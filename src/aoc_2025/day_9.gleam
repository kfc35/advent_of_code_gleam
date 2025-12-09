import gleam/int
import gleam/list
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

fn area(corners: #(Tile, Tile)) {
  { int.absolute_value({ corners.1 }.x - { corners.0 }.x) + 1 }
  * { int.absolute_value({ corners.1 }.y - { corners.0 }.y) + 1 }
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
  // only need to check that all four corners of a rectangle within the shape.
  let red_tiles = parse_input(input)
  let #(first_red_tile, second_red_tile, rest_red_tiles) = case red_tiles {
    [head, second, ..rest] -> #(head, second, rest)
    _ ->
      panic as "malformed input: must have at least two points to have a solution"
  }

  let candidate_rectangles =
    list.combination_pairs(red_tiles)
    |> list.map(to_rectangle)
    |> list.sort(sort_rectangle_area_desc)
    
}

type Rectangle {
  Rectangle(corners: #(Tile, Tile), area: Int)
}

fn to_rectangle(corners: #(Tile, Tile)) {
  Rectangle(corners, area(corners))
}

fn sort_rectangle_area_desc(rect_a: Rectangle, rect_b: Rectangle) {
  int.compare(rect_b.area, rect_a.area)
}

fn get_other_two_corners(rect: Rectangle) {
  let #(rect_a, rect_b) = rect.corners
  [
    Tile(rect_a.x, rect_b.y),
    Tile(rect_b.x, rect_a.y),
  ]
}

fn verify_rectangle_valid(rect: Rectangle, red_tiles: List(Tile)) {
  get_other_two_corners(rect)
  |> list.map(fn(unknown_corner) { list.window_by_2(red_tiles) })
}

// fn shape_rectangles(global_first: Tile, 
//   global_second: Tile,
//   current_first: Tile,
//   current_second: Tile,
//   rest_red_tiles: List(Tile), 
//   rects: List(Rect)) {
//   case rest_red_tiles {
//     [] -> rects
//     [last] ->
//       [to_rectangle(#(current_first, last), to_rectangle(#(last, second))), ..rects]
//     [third, fourth] ->
//       [to_rectangle(#(first, third)), ..rects]
//     // 3 or more
//     [third, fourth, ..rest] -> 
//       shape_rectangles(third, fourth, rest, [to_rectangle(#(first, third)), to_rectangle(#(second, fourth))...rects)
//   }
// }

fn tile_lies_on_border(tile: Tile, red_tile_line: #(Tile, Tile)) {
  let #(a, b) = red_tile_line
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

fn tile_lies_in_rectangle(tile: Tile, rect: Rectangle) {
  let (a, b) = rect.corners
  tile.x <= int.max(a.x, b.x)
    && tile.x >= int.min(a.x, b.x)
    && tile.y <= int.max(a.y, b.y)
    && tile.y >= int.min(a.y, b.y)
}
