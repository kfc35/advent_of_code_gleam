import gleam/bool
import gleam/int
import gleam/list
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

  let candidate_rectangles =
    list.combination_pairs(red_tiles)
    |> list.map(to_rectangle)
    |> list.sort(sort_rectangle_area_desc)

  // The composition of these rectangles encompasses the border AND inside of the input
  let checking_rectangles =
    candidate_rectangles
    |> list.filter(rectangle_corners_lie_on_border(_, border))

  echo checking_rectangles

  list.find(candidate_rectangles, fn(rectangle) {
    let tiles = to_covering_tiles(rectangle)
    assert list.length(tiles) == rectangle.area as "invariant"

    {
      use checking_rect <- list.map(checking_rectangles)
      use tile <- list.map(tiles)
      tile_lies_inside_rectangle(tile, checking_rect)
    }
    |> list.reduce(fn(tile_checks_a, tile_checks_b) {
      list.zip(tile_checks_a, tile_checks_b)
      |> list.map(fn(tup) {
        let #(a, b) = tup
        a || b
      })
    })
    |> result.unwrap([False])
    |> list.reduce(bool.and)
    |> result.unwrap(False)
  })
  |> result.map(fn(candidate) {
    echo candidate
    candidate.area
  })
  |> result.unwrap(0)
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

fn tile_lies_inside_rectangle(tile: Tile, rect: Rectangle) {
  let #(a, b) = rect.opposite_corners
  tile.x <= int.max(a.x, b.x)
  && tile.x >= int.min(a.x, b.x)
  && tile.y <= int.max(a.y, b.y)
  && tile.y >= int.min(a.y, b.y)
}

fn to_covering_tiles(rect: Rectangle) {
  let #(corner_a, corner_b) = rect.opposite_corners
  let x_range = list.range(corner_a.x, corner_b.x)
  let y_range = list.range(corner_a.y, corner_b.y)
  {
    use x <- list.map(x_range)
    use y <- list.map(y_range)
    Tile(x, y)
  }
  |> list.flatten()
}

// fn rectangle_is_line(rect: Rectangle) {
//   let #(a, b) = rect.corners
//   a.x == b.x || a.y == b.y
// }

// fn rectangle_is_not_line(rect: Rectangle) {
//   !rectangle_is_line(rect)
// }

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
