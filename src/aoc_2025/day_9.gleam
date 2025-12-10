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
  let first_red_tile = case red_tiles {
    [head, ..] -> head
    _ ->
      panic as "malformed input: must have at least two points to have a solution"
  }
  let border = list.window_by_2(list.append(red_tiles, [first_red_tile]))
  // The composition of these rectangles encompasses the border AND the inside of the input
  // TODO... this does take into account concave.... shapes.... ugh......
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
  |> fn(candidates) {
    echo "before first filter: "
    echo list.length(candidates)
    candidates
  }
  // first filter just checks borders. This is quick and easy and gets most out of the way.
  |> list.filter(fn(candidate) {
    echo "processing candidate: "
    echo candidate

    rect_to_border_sides(candidate)
    |> remove_overlapping_sides(checking_rectangles)
    |> list.is_empty()
  })
  |> fn(candidates) {
    echo "before second filter: "
    echo list.length(candidates)
    candidates
  }
  // now check the candidate's full shape
  // just take progressively smaller and smaller inner rects until youve checked the whole thing
  // TODO is this really necessary? Maybe our algorithm was wrong in a different place.
  |> list.filter(fn(candidate) {
    fully_vet_candidate(candidate, checking_rectangles)
  })
  |> fn(candidates) {
    echo "before third filter: "
    echo list.length(candidates)
    candidates
  }
  // |> list.filter(fn(candidate) {
  //   case
  //     list.fold_until(
  //       checking_rectangles,
  //       to_tiles(candidate),
  //       fn(tiles, checking_rect) {
  //         let leftover =
  //           tiles
  //           |> list.filter(tile_lies_inside_rectangle(_, checking_rect))
  //         case leftover {
  //           [] -> list.Stop([])
  //           _ -> list.Continue(leftover)
  //         }
  //       },
  //     )
  //   {
  //     [] -> True
  //     _ -> False
  //   }
  // })
  // one last sanity check... that might be unnecessary. This can have a tendency to OOM if done too many times.
  |> list.filter(fn(candidate) {
    to_full_sides(candidate)
    |> remove_overlapping_sides(checking_rectangles)
    |> list.is_empty()
  })
  |> fn(candidates) {
    echo "before completing iteration"
    echo list.length(candidates)
    candidates
  }
  |> list.take(1)
  |> fn(maybe_candidate) {
    case maybe_candidate {
      [head] -> Ok(head.area)
      _ -> Error(Nil)
    }
  }
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
    Tile(corner_a.x, corner_b.y),
    corner_b,
    Tile(corner_b.x, corner_a.y),
  ]
}

type Line {
  // y stays constant
  HorizontalLine(x_low: Int, x_high: Int, y: Int)
  // x stays constant
  VerticalLine(x: Int, y_low: Int, y_high: Int)
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

// fn to_border_tiles(rect: Rectangle) {
//   let #(corner_a, corner_b) = rect.opposite_corners
//   let x_range = list.range(corner_a.x, corner_b.x)
//   let y_range = list.range(corner_a.y, corner_b.y)
//   [
//     list.map(y_range, fn(y) { Tile(corner_a.x, y) }),
//     list.map(y_range, fn(y) { Tile(corner_b.x, y) }),
//     list.map(x_range, fn(x) { Tile(x, corner_a.y) }),
//     list.map(x_range, fn(x) { Tile(x, corner_b.y) }),
//   ]
//   |> list.flatten
// }

// fn to_tiles(rect: Rectangle) {
//   let #(corner_a, corner_b) = rect.opposite_corners
//   echo rect.opposite_corners
//   let x_range = list.range(corner_a.x, corner_b.x)
//   let y_range = list.range(corner_a.y, corner_b.y)
//   {
//     use x <- list.map(x_range)
//     use y <- list.map(y_range)
//     Tile(x, y)
//   }
//   |> list.flatten
// }

/// shorten the list by ensuring smaller rectangles are subsumed by bigger ones
fn coalesce_checking_rectangles(rects: List(Rectangle)) {
  list.fold(rects, [], fn(minimal_list_rects, rect) {
    case
      list.any(minimal_list_rects, fn(rectangle) {
        list.all(to_four_corners(rect), tile_lies_inside_rectangle(_, rectangle))
      })
    {
      True -> minimal_list_rects
      False -> [rect, ..minimal_list_rects]
    }
  })
}

fn rect_to_border_sides(rect: Rectangle) {
  let #(corner_a, corner_b) = rect.opposite_corners
  let min_x = int.min(corner_a.x, corner_b.x)
  let max_x = int.max(corner_a.x, corner_b.x)
  let min_y = int.min(corner_a.y, corner_b.y)
  let max_y = int.max(corner_a.y, corner_b.y)
  to_border_sides(min_x, max_x, min_y, max_y)
}

fn to_border_sides(min_x: Int, max_x: Int, min_y: Int, max_y: Int) {
  [
    // left
    VerticalLine(min_x, min_y, max_y),
    // top
    HorizontalLine(min_x, max_x, max_y),
    // right
    VerticalLine(max_x, min_y, max_y),
    // bottom
    HorizontalLine(min_x, max_x, min_y),
  ]
}

/// fully vetting candidate via checking smaller and smaller rectangles (as represented by List(Side))
/// and making sure they within the shape expressed as checking_rectangles 
fn fully_vet_candidate(rect: Rectangle, checking_rectangles: List(Rectangle)) {
  fully_vet_candidate_loop(rect, checking_rectangles, 1)
}

fn fully_vet_candidate_loop(
  rect: Rectangle,
  checking_rectangles: List(Rectangle),
  n: Int,
) {
  let next_sides = get_sides_n_sizes_smaller(rect, n)
  case next_sides {
    [] -> True
    _ ->
      case
        next_sides
        |> remove_overlapping_sides(checking_rectangles)
        |> list.is_empty()
      {
        True -> fully_vet_candidate_loop(rect, checking_rectangles, n + 1)
        False -> False
      }
  }
}

fn get_sides_n_sizes_smaller(rect: Rectangle, n) {
  let #(corner_a, corner_b) = rect.opposite_corners
  let min_x = int.min(corner_a.x, corner_b.x) + n
  let max_x = int.max(corner_a.x, corner_b.x) - n
  let min_y = int.min(corner_a.y, corner_b.y) + n
  let max_y = int.max(corner_a.y, corner_b.y) - n
  case min_x > max_x || min_y > max_y {
    False -> to_border_sides(min_x, max_x, min_y, max_y)
    True -> []
  }
}

// -- //

/// Express a rectangle completely as a list of lines
fn to_full_sides(rect: Rectangle) {
  let #(corner_a, corner_b) = rect.opposite_corners
  let min_x = int.min(corner_a.x, corner_b.x)
  let max_x = int.max(corner_a.x, corner_b.x)
  let min_y = int.min(corner_a.y, corner_b.y)
  let max_y = int.max(corner_a.y, corner_b.y)

  case max_x - min_x > max_y - min_y {
    True ->
      list.range(min_y, max_y)
      |> list.map(fn(y) { HorizontalLine(min_x, max_x, y) })
    False ->
      list.range(min_x, max_x)
      |> list.map(fn(x) { VerticalLine(x, min_y, max_y) })
  }
}

fn remove_overlapping_sides(sides: List(Line), checking_rects: List(Rectangle)) {
  list.fold_until(checking_rects, sides, fn(sides_accum, checking_rect) {
    let #(corner_a, corner_b) = checking_rect.opposite_corners
    let min_x = int.min(corner_a.x, corner_b.x)
    let max_x = int.max(corner_a.x, corner_b.x)
    let min_y = int.min(corner_a.y, corner_b.y)
    let max_y = int.max(corner_a.y, corner_b.y)

    let updated_sides =
      sides_accum
      |> list.map(fn(side) {
        case side {
          HorizontalLine(x_low, x_high, y) -> {
            let outside_y_range = y < min_y || max_y < y
            let outside_x_range = x_low > max_x || x_high < min_x
            let outside_range = outside_y_range || outside_x_range

            let there_is_excess_lower_x = x_low < min_x
            let there_is_excess_upper_x = x_high > max_x
            case
              outside_range,
              there_is_excess_lower_x,
              there_is_excess_upper_x
            {
              True, _, _ -> [side]
              // spawn any extra horizontal lines as necessary
              False, True, True -> [
                HorizontalLine(x_low, min_x - 1, y),
                HorizontalLine(max_x + 1, x_high, y),
              ]
              False, True, False -> [
                HorizontalLine(x_low, min_x - 1, y),
              ]
              False, False, True -> [
                HorizontalLine(max_x + 1, x_high, y),
              ]
              False, False, False -> []
            }
          }
          VerticalLine(x, y_low, y_high) -> {
            let outside_x_range = x < min_x || max_x < x
            let outside_y_range = y_low > max_y || y_high < min_y
            let outside_range = outside_y_range || outside_x_range

            let there_is_excess_lower_y = y_low < min_y
            let there_is_excess_upper_y = y_high > max_y
            case
              outside_range,
              there_is_excess_lower_y,
              there_is_excess_upper_y
            {
              True, _, _ -> [side]
              // spawn any extra horizontal lines as necessary
              False, True, True -> [
                VerticalLine(x, y_low, min_y - 1),
                VerticalLine(x, max_y + 1, y_high),
              ]
              False, True, False -> [
                VerticalLine(x, y_low, min_y - 1),
              ]
              False, False, True -> [
                VerticalLine(x, max_y + 1, y_high),
              ]
              False, False, False -> []
            }
          }
        }
      })
      |> list.flatten
    case updated_sides {
      [] -> list.Stop([])
      _ -> list.Continue(updated_sides)
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

// The inner area of the input can be described as a ** composition ** of rectangles
// How do we determine those rectangles? (Duplicates are fine)
// For a given rectangle with two opposite-cornered red-tiles, we can say that
// this rectangle fully encompasses a part of the shape from border to border 
// if its other two corners lie on the path drawn by the input.
// TODO THIS IS WRONG FOR CONVEX SHAPES
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
