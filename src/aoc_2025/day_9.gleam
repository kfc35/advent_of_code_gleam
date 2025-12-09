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
  let red_tiles = parse_input(input)
  let #(first_red_tile, _, _) = case red_tiles {
    [head, second, ..rest] -> #(head, second, rest)
    _ ->
      panic as "malformed input: must have at least two points to have a solution"
  }

  let candidate_rectangles =
    list.combination_pairs(red_tiles)
    |> list.map(to_rectangle)
    |> list.sort(sort_rectangle_area_desc)

  // these are rectangles drawn from the first tile to every other point in the shape.
  // these checking rects do NOT constitute the "interior" of the shape, 
  // but checking whether points are in these rects might be
  // used to eventually guess whether a point is in the "interior" of the shape
  let checking_rectangles =
    red_tiles
    |> list.map(fn(tile) { to_rectangle(#(first_red_tile, tile)) })
    |> list.filter(rectangle_is_not_line)

  let _ =
    list.find(candidate_rectangles, fn(rectangle) {
      echo rectangle
      let tiles = to_covering_tiles(rectangle)
      // assert list.length(tiles) == rectangle.area as "invariant"

      // turns into List(List(Int))
      // for every checking rectangle, check tiles in the checking rectangle
      let _ = {
        use checking_rect <- list.map(checking_rectangles)
        use tile <- list.map(tiles)
        tile_lies_inside_rectangle(tile, checking_rect)
      }

      // this rest of this logic is flawed :(
      // sum up over all checking
      //   |> list.reduce(fn(tile_checks_a, tile_checks_b) {
      //     list.zip(tile_checks_a, tile_checks_b)
      //     |> list.map(fn(tup) {
      //       let #(a, b) = tup
      //       a + b
      //     })
      //   })
      //   |> result.unwrap([0])
      //   |> list.map(fn(parity_to_check) { parity_to_check % 2 == 1 })
      //   |> list.reduce(bool.and)
      //   |> result.unwrap(False)
      // })
      // // get the rectangle
      // |> result.map(fn(candidate) {
      //   echo candidate
      //   candidate.area
      // })
      // |> result.unwrap(0)
      True
    })
  0
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

fn tile_lies_inside_rectangle(tile: Tile, rect: Rectangle) {
  let #(a, b) = rect.corners
  tile.x <= int.max(a.x, b.x)
  && tile.x >= int.min(a.x, b.x)
  && tile.y <= int.max(a.y, b.y)
  && tile.y >= int.min(a.y, b.y)
}

fn to_covering_tiles(rect: Rectangle) {
  let #(corner_a, corner_b) = rect.corners
  let x_range = list.range(corner_a.x, corner_b.x)
  let y_range = list.range(corner_a.y, corner_b.y)
  {
    use x <- list.map(x_range)
    use y <- list.map(y_range)
    Tile(x, y)
  }
  |> fn(tiles) {
    echo tiles
    tiles
  }
  |> list.flatten()
}

fn rectangle_is_line(rect: Rectangle) {
  let #(a, b) = rect.corners
  a.x == b.x || a.y == b.y
}

fn rectangle_is_not_line(rect: Rectangle) {
  !rectangle_is_line(rect)
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

// fn tile_lies_on_border(tile: Tile, red_tile_line: #(Tile, Tile)) {
//   let #(a, b) = red_tile_line
//   case a.x != b.x {
//     True ->
//       tile.y == a.y
//       && tile.x <= int.max(a.x, b.x)
//       && tile.x >= int.min(a.x, b.x)
//     // tile.a.y != tile_b.y by input invariant
//     False ->
//       tile.x == a.x
//       && tile.y <= int.max(a.y, b.y)
//       && tile.y >= int.min(a.y, b.y)
//   }
// }
