import gleam/bool
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/string

pub fn pt_1(input: String) {
  let red_tiles = parse_input(input)

  list.combination_pairs(red_tiles)
  |> list.map(area)
  |> list.max(int.compare)
}

type Tile {
  Tile(x: Int, y: Int)
}

fn area(opposite_corners: #(Tile, Tile)) {
  {
    int.absolute_value({ opposite_corners.1 }.x - { opposite_corners.0 }.x) + 1
  }
  * {
    int.absolute_value({ opposite_corners.1 }.y - { opposite_corners.0 }.y) + 1
  }
}

// input parsing //

fn parse_input(input: String) {
  string.split(input, "\n")
  |> list.map(parse_red_tile)
}

fn parse_red_tile(tile: String) {
  case string.split(tile, ",") {
    [x, y] -> Tile(assert_int(x), assert_int(y))
    _ ->
      panic as {
        "malformed input: \""
        <> tile
        <> "\". each line must be of the format x, y"
      }
  }
}

fn assert_int(input: String) {
  let assert Ok(i) = int.parse(input) as "this must be a number"
  i
}

// -- //
// END PART 1 //

pub fn pt_2(input: String) {
  let red_tiles = parse_input(input)
  let #(first_red_tile, _, _) = case red_tiles {
    [head, second, ..rest] -> #(head, second, rest)
    _ ->
      panic as "malformed input: must have at least two points to have a solution"
  }
  let border = list.window_by_2(list.append(red_tiles, [first_red_tile]))
  // The composition of these rectangles encompasses the border and the inside of the input
  let checking_rectangles =
    list.combination_pairs(red_tiles)
    |> list.map(to_rectangle)
    // a candidate rectangle that has its four corners on the border (defined by the problem input)
    // encompass a discrete portion of the "inside" of the input
    // the list of all of such rectangles encompasses the whole "inside"!
    |> list.filter(rectangle_corners_lie_on_border(_, border))
    |> list.sort(sort_rectangle_area_desc)
    // the list has duplicates (some rectangles are duplicated), so we must coalesce for memory
    |> coalesce_checking_rectangles

  echo "checking rects!!:"
  checking_rectangles
  |> list.each(fn(rect) { echo rect })
  echo list.length(checking_rectangles)
  echo "!!"

  let candidate_rectangles =
    list.combination_pairs(red_tiles)
    |> list.map(to_rectangle)
    |> list.sort(sort_rectangle_area_desc)

  process_candidate_rectangles_loop(
    candidate_rectangles,
    20,
    checking_rectangles,
  )
}

fn process_candidate_rectangles_loop(
  candidates: List(Rectangle),
  step_size: Int,
  checking_rectangles: List(Rectangle),
) {
  echo "starting an iteration"
  let candidates_slice = list.take(candidates, step_size)
  case candidates_slice {
    [] -> option.None
    _ ->
      case get_valid_candidate(candidates_slice, checking_rectangles) {
        Ok(area) -> option.Some(area)
        Error(_) ->
          process_candidate_rectangles_loop(
            list.drop(candidates, step_size),
            step_size,
            checking_rectangles,
          )
      }
  }
}

fn get_valid_candidate(
  candidates: List(Rectangle),
  checking_rectangles: List(Rectangle),
) {
  candidates
  |> list.find(fn(rectangle) {
    echo "processing rectangle: "
    echo rectangle

    // is there a better format for this?
    to_border_tiles(rectangle)
    |> fn(tiles) {
      echo list.length(tiles)
      tiles
    }
    |> list.map(fn(border_tile) {
      list.any(checking_rectangles, fn(rectangle) {
        tile_lies_inside_rectangle(border_tile, rectangle)
      })
    })
    |> list.reduce(bool.and)
    |> result.unwrap(False)
  })
  |> result.map(fn(candidate) { candidate.area })
}

type Rectangle {
  Rectangle(opposite_corners: #(Tile, Tile), area: Int)
}

fn to_rectangle(opposite_corners: #(Tile, Tile)) {
  Rectangle(opposite_corners, area(opposite_corners))
}

fn to_four_corners(rect: Rectangle) {
  let #(corner_a, corner_b) = rect.opposite_corners
  [
    corner_a,
    corner_b,
    Tile(corner_a.x, corner_b.y),
    Tile(corner_b.x, corner_a.y),
  ]
}

fn sort_rectangle_area_desc(rect_a: Rectangle, rect_b: Rectangle) {
  int.compare(rect_b.area, rect_a.area)
}

// fn rectangle_border_lies_inside_rectangle(
//   maybe_inside: Rectangle,
//   rect: Rectangle,
// ) {
//   to_border_tiles(maybe_inside)
//   |> list.all(tile_lies_inside_rectangle(_, rect))
// }

// fn rectangle_corners_lies_inside_rectangle(
//   maybe_inside: Rectangle,
//   rect: Rectangle,
// ) {
//   to_four_corners(maybe_inside)
//   |> list.all(tile_lies_inside_rectangle(_, rect))
// }

fn tile_lies_inside_rectangle(tile: Tile, rect: Rectangle) {
  let #(a, b) = rect.opposite_corners
  tile.x <= int.max(a.x, b.x)
  && tile.x >= int.min(a.x, b.x)
  && tile.y <= int.max(a.y, b.y)
  && tile.y >= int.min(a.y, b.y)
}

fn to_border_tiles(rect: Rectangle) {
  let #(corner_a, corner_b) = rect.opposite_corners
  let x_range = list.range(corner_a.x, corner_b.x)
  let y_range = list.range(corner_a.y, corner_b.y)
  [
    list.map(y_range, fn(y) { Tile(corner_a.x, y) }),
    list.map(y_range, fn(y) { Tile(corner_b.x, y) }),
    list.map(x_range, fn(x) { Tile(x, corner_a.y) }),
    list.map(x_range, fn(x) { Tile(x, corner_b.y) }),
  ]
  |> list.flatten
}

fn rectangle_is_line(rect: Rectangle) {
  let #(a, b) = rect.opposite_corners
  a.x == b.x || a.y == b.y
}

fn rectangle_is_not_line(rect: Rectangle) {
  !rectangle_is_line(rect)
}

fn coalesce_checking_rectangles(rects: List(Rectangle)) {
  list.fold(rects, [], fn(minimal_list_rects, rect) {
    case
      list.map(to_four_corners(rect), fn(corner) {
        list.any(minimal_list_rects, fn(rectangle) {
          tile_lies_inside_rectangle(corner, rectangle)
        })
      })
      |> list.reduce(bool.and)
      |> result.unwrap(False)
    {
      True -> minimal_list_rects
      False -> [rect, ..minimal_list_rects]
    }
  })
}

// Consider these cases
// __________________
// |                 |
// |         ________|
// |        |
// |        |
// |________| 
//
// __________________
// |                 |
// |________         |_____________
//          |                      |
//          |                      |
//          |______________________|

// Concave
// __________________
// |                |
// |                |
// |        ________|
// |        | 
// |        |________
// |                |
// |                |
// |________________|

// _________
// |        |
// |        |_______
// |                |
// |        ________|
// |        | 
// |        |________
// |                |
// |                |
// |________________|

// Convex
// __________________
// |                |
// |                |
// |                |_______
// |                        | 
// |                 _______|
// |                |
// |                |
// |________________|

// We have already generated the complete list of opposite-cornered red-tiles
// With this, we can figure out the input as a composition of these special rectangles
//  and then use them to find the desired maximal rectangle.

// The inner area if the input can be described as a ** composition ** of rectangles
// How do we determine those rectangles? (Duplicates are fine)
// For a given rectangle with two opposite-cornered red-tiles, we can say that
// this rectangle fully encompasses a part of the shape from border to border 
// if its other two corners lie on the path drawn by the input.
fn rectangle_corners_lie_on_border(
  rect: Rectangle,
  red_tile_borders: List(#(Tile, Tile)),
) {
  {
    use corner <- list.map(to_four_corners(rect))
    use border <- list.any(red_tile_borders)
    tile_lies_on_border(corner, border)
  }
  |> list.all(fn(tile_is_on_border) { tile_is_on_border })
}

fn tile_lies_on_border(tile: Tile, border: #(Tile, Tile)) {
  let #(a, b) = border
  case a.x != b.x {
    True ->
      tile.y == a.y
      && tile.x <= int.max(a.x, b.x)
      && tile.x >= int.min(a.x, b.x)
    // tile.a.y != tile_b.y by input invariant
    False ->
      tile.x == a.x
      && tile.y <= int.max(a.y, b.y)
      && tile.y >= int.min(a.y, b.y)
  }
}
