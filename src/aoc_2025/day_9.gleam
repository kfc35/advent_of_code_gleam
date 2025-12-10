import gleam/int
import gleam/list
import gleam/option
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
  let border_lines = shape_to_border_lines(border)
  let invalid_border_lines =
    generate_invalid_border_lines(red_tiles, border_lines)
  // The composition of these rectangles encompasses the border AND the inside of the input
  echo "invalid border lines:"
  invalid_border_lines
  |> list.each(fn(line) { echo line })
  echo "boo"
  let checking_rectangles =
    list.combination_pairs(red_tiles)
    |> list.map(to_rectangle)
    // a rectangle that has its four corners on the border (defined by the problem input)
    // it can encompass a discrete portion of the "inside" of the input, 
    // or an empty portion, as in certain concave sections of the shape
    |> list.filter(rectangle_corners_lie_on_border(_, border))
    // remove any rectangles if any of its sides is exactly an invalid border line
    // this filters out any perfectly concave shapes 
    // TODO this overly filters out any convex winners
    |> list.filter(fn(rectangle) {
      let border_lines = rect_to_border_lines(rectangle)
      !{
        use invalid_border_line <- list.any(invalid_border_lines)
        use border_line <- list.any(border_lines)
        invalid_border_line == border_line
      }
    })
    |> list.sort(sort_rectangle_area_desc)
    // the list has duplicates (some rectangles are duplicated), so we coalesce for memory
    |> coalesce_checking_rectangles

  echo "checking rects!!:"
  checking_rectangles
  |> list.each(fn(rect) { echo rect })
  echo list.length(checking_rectangles)
  echo "yayyyy"

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

// TODO this does not work for convex...
// this will fix it in the concave example, but not the convex!
fn generate_invalid_border_lines(
  red_tiles: List(Tile),
  border_lines: List(Line),
) -> List(Line) {
  list.combination_pairs(red_tiles)
  |> list.map(to_rectangle)
  |> list.filter(rectangle_is_line)
  |> list.map(rect_to_border_lines)
  |> list.flatten()
  |> list.filter(fn(potential_invalid) {
    !list.any(border_lines, fn(border_line) { border_line == potential_invalid })
  })
  // remove any segments of valid borders from the potential invalid ones
  // |> list.map(fn(potential_invalid) {
  //   list.fold(border_lines, [potential_invalid], fn(accum, border_line) {
  //     list.flatten(list.map(accum, remove_overlap(_, border_line)))
  //   })
  // })
  // |> list.flatten()
  // |> list.unique()
}

// Use this function only for border calculations!!
// fn remove_overlap(a: Line, remove: Line) {
//   case a, remove {
//     HorizontalLine(a_low_x, a_high_x, a_y),
//       HorizontalLine(rm_low_x, rm_high_x, rm_y)
//     -> {
//       case a_y != rm_y || a_low_x > rm_high_x || a_high_x < rm_low_x {
//         True -> [a]
//         False -> {
//           let low_left_over = a_low_x < rm_low_x
//           let high_left_over = a_high_x > rm_high_x
//           case low_left_over, high_left_over {
//             True, True -> [
//               // we include rm_low_x and rm_high_x directly (instead of -1, +1)
//               // because it makes the math work for borders -- those points
//               // are included in the creation of the rect composition of the shape
//               HorizontalLine(a_low_x, rm_low_x, a_y),
//               HorizontalLine(rm_high_x, a_high_x, a_y),
//             ]
//             True, False -> [HorizontalLine(a_low_x, rm_low_x, a_y)]
//             False, True -> [HorizontalLine(a_high_x, a_high_x, a_y)]
//             False, False -> []
//           }
//         }
//       }
//     }
//     VerticalLine(a_x, a_low_y, a_high_y),
//       VerticalLine(rm_x, rm_low_y, rm_high_y)
//     -> {
//       case a_x != rm_x || a_low_y > rm_high_y || a_high_y < rm_low_y {
//         True -> [a]
//         False -> {
//           let low_left_over = a_low_y < rm_low_y
//           let high_left_over = a_high_y > rm_high_y
//           case low_left_over, high_left_over {
//             True, True -> [
//               // we include rm_low_y and rm_high_y directly (instead of -1, +1)
//               // because ... idk
//               VerticalLine(a_x, a_low_y, rm_low_y),
//               VerticalLine(a_x, rm_high_y, a_high_y),
//             ]
//             True, False -> [VerticalLine(a_x, a_low_y, rm_low_y)]
//             False, True -> [VerticalLine(a_x, rm_high_y, a_high_y)]
//             False, False -> []
//           }
//         }
//       }
//     }
//     _, _ -> [a]
//   }
// }

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
  // first filter just checks borders. This is quick and easy and gets most out of the way.
  |> fn(candidates) {
    candidates |> list.map(fn(candidate) { echo candidate })
    candidates
  }
  |> list.filter(fn(candidate) {
    rect_to_border_lines(candidate)
    |> remove_overlapping_sides(checking_rectangles)
    |> list.is_empty()
  })
  |> fn(candidates) {
    case list.length(candidates) > 1 {
      True -> {
        echo "candidates that passed first filter"
        list.each(candidates, fn(candidate) { echo candidate })
        candidates
      }
      False -> candidates
    }
  }
  // now check the candidate's full shape.
  // just take progressively smaller and smaller inner rects until youve checked the whole thing
  // TODO is this really necessary? Maybe our algorithm is wrong in a different place.
  |> list.filter(fn(candidate) {
    fully_vet_candidate(candidate, checking_rectangles)
  })
  |> fn(candidates) {
    case list.length(candidates) > 1 {
      True -> {
        echo "candidates that passed second filter"
        list.each(candidates, fn(candidate) { echo candidate })
        candidates
      }
      False -> candidates
    }
  }
  // |> fn(candidates) {
  //   echo "before third filter: "
  //   echo list.length(candidates)
  //   candidates
  // }
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
  // |> list.filter(fn(candidate) {
  //   to_full_sides(candidate)
  //   |> remove_overlapping_sides(checking_rectangles)
  //   |> list.is_empty()
  // })
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

type Line {
  // y stays constant
  HorizontalLine(x_low: Int, x_high: Int, y: Int)
  // x stays constant
  VerticalLine(x: Int, y_low: Int, y_high: Int)
}

fn rectangle_is_line(rect: Rectangle) {
  let #(corner_a, corner_b) = rect.opposite_corners
  corner_a.x == corner_b.x || corner_a.y == corner_b.y
}

fn rect_to_border_lines(rect: Rectangle) {
  let #(corner_a, corner_b) = rect.opposite_corners
  let min_x = int.min(corner_a.x, corner_b.x)
  let max_x = int.max(corner_a.x, corner_b.x)
  let min_y = int.min(corner_a.y, corner_b.y)
  let max_y = int.max(corner_a.y, corner_b.y)
  to_border_lines(min_x, max_x, min_y, max_y)
}

fn to_border_lines(min_x: Int, max_x: Int, min_y: Int, max_y: Int) {
  case min_x == max_x, min_y == max_y {
    False, False -> [
      // left
      VerticalLine(min_x, min_y, max_y),
      // top
      HorizontalLine(min_x, max_x, max_y),
      // right
      VerticalLine(max_x, min_y, max_y),
      // bottom
      HorizontalLine(min_x, max_x, min_y),
    ]
    True, False -> [VerticalLine(min_x, min_y, max_y)]
    False, True -> [HorizontalLine(min_x, max_x, min_y)]
    // A point 
    True, True -> [HorizontalLine(min_x, min_x, min_y)]
  }
}

fn shape_to_border_lines(shape: List(#(Tile, Tile))) {
  shape
  |> list.map(fn(segment) {
    let #(a, b) = segment
    case a.x == b.x, a.y == b.y {
      True, False -> VerticalLine(a.x, int.min(a.y, b.y), int.max(a.y, b.y))
      False, True -> HorizontalLine(int.min(a.x, b.x), int.max(a.x, b.x), a.y)
      True, True ->
        panic as "invariant violated: two lines exist with x and y equal"
      False, False ->
        panic as "invariant violated: two lines exist with x and y both unequal"
    }
  })
}

// This function and related ops usually OOM's
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
    False -> to_border_lines(min_x, max_x, min_y, max_y)
    True -> []
  }
}

// -- //

/// Express a rectangle completely as a list of lines
// fn to_full_lines(rect: Rectangle) {
//   let #(corner_a, corner_b) = rect.opposite_corners
//   let min_x = int.min(corner_a.x, corner_b.x)
//   let max_x = int.max(corner_a.x, corner_b.x)
//   let min_y = int.min(corner_a.y, corner_b.y)
//   let max_y = int.max(corner_a.y, corner_b.y)

//   case max_x - min_x > max_y - min_y {
//     True ->
//       list.range(min_y, max_y)
//       |> list.map(fn(y) { HorizontalLine(min_x, max_x, y) })
//     False ->
//       list.range(min_x, max_x)
//       |> list.map(fn(x) { VerticalLine(x, min_y, max_y) })
//   }
// }

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
              // With checking rects, we have to -1 +1 where appropriate because
              // the border of the checking rect are all valid points.
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

// Consider these cases for your algorithm!
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
// With this, we can filter the list somehow to figure out the inputted shape as 
// a composition of these rectangles.
// Then, we can use them to find the desired maximal rectangle.

/// We can say that every rectangle that fully encompasses some part of the input 
/// shape from border to border has its four corners on the path drawn by the input.
/// This function is used to filter for such rectangles as a first step
/// towards coming up with the correct composition of the shape.
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
