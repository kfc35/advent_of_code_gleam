import gleam/int
import gleam/list
import gleam/string

pub fn pt_1(input: String) {
  let cafe = parse_input(input)
  let row_indices = list.range(0, list.length(cafe) - 1)
  let cafe_col_length = case cafe {
    [head, ..] -> list.length(head)
    _ -> 0
  }
  let col_indices = list.range(0, cafe_col_length - 1)

  let cafe_forklift_map = {
    use row, row_index <- list.map2(cafe, row_indices)
    use item, col_index <- list.map2(row, col_indices)
    can_forklift(cafe, item, row_index, col_index, 1)
  }

  cafe_forklift_map
  |> list.flatten
  |> list.reduce(int.add)
}

fn parse_input(input: String) -> List(List(String)) {
  string.split(input, "\n")
  |> list.map(string.split(_, ""))
}

fn can_forklift(
  cafe: List(List(String)),
  current_item: String,
  row: Int,
  col: Int,
  breadth: Int,
) {
  case current_item {
    "@" -> check_surrounding_tiles(cafe, row, col, breadth)
    _ -> 0
  }
}

// Returns 1 if passes check, 0 if false
fn check_surrounding_tiles(
  cafe: List(List(String)),
  row: Int,
  col: Int,
  breadth: Int,
) {
  let cafe_row_length = list.length(cafe)
  let cafe_col_length = case cafe {
    [head, ..] -> list.length(head)
    _ -> 0
  }

  // (0,0) matches top left corner of cafe.
  let top_row = int.max(row - breadth, 0)
  let bottom_row = int.min(row + breadth, cafe_row_length - 1)
  let num_rows = bottom_row - top_row + 1
  let left_col = int.max(col - breadth, 0)
  let right_col = int.min(col + breadth, cafe_col_length - 1)
  let num_cols = right_col - left_col + 1

  let paper_unflattened =
    find_desired_rows_flipped(cafe, [], top_row, num_rows)
    // mark the row that has the index to ignore
    |> list.zip(
      list.range(bottom_row, top_row)
      |> list.map(fn(index) { index == row }),
    )
    |> list.map(find_desired_items(_, [], col, 0, left_col, num_cols))

  let paper =
    paper_unflattened
    |> list.flatten
    |> num_paper(0, 0)

  case paper < 4 {
    True -> 1
    False -> 0
  }
}

/// this function returns the desired rows from cafe between "num_until_desired"
/// and "num_until_desired" + num_desired, 0-indexed
/// as a side effect, it returns a reversed order of the rows for optimization
/// ultimately, that is fine, since we do not care about orientation luckily.
fn find_desired_rows_flipped(
  cafe: List(List(String)),
  desired_rows: List(List(String)),
  num_until_desired: Int,
  num_desired_left: Int,
) {
  case cafe {
    [_, ..rest] if num_until_desired > 0 ->
      find_desired_rows_flipped(
        rest,
        desired_rows,
        num_until_desired - 1,
        num_desired_left,
      )
    [head, ..rest] if num_until_desired == 0 && num_desired_left > 0 ->
      find_desired_rows_flipped(
        rest,
        [head, ..desired_rows],
        num_until_desired,
        num_desired_left - 1,
      )
    _ -> desired_rows
  }
}

// same caveat as above function, returning reversed order of the cols.
fn find_desired_items(
  row_and_has_to_ignore: #(List(String), Bool),
  desired_items: List(String),
  col_to_ignore: Int,
  current_col: Int,
  num_until_desired: Int,
  num_desired: Int,
) {
  case row_and_has_to_ignore.0 {
    [_, ..rest] if num_until_desired > 0 ->
      find_desired_items(
        #(rest, row_and_has_to_ignore.1),
        desired_items,
        col_to_ignore,
        current_col + 1,
        num_until_desired - 1,
        num_desired,
      )
    [head, ..rest] if num_until_desired == 0 && num_desired > 0 ->
      find_desired_items(
        #(rest, row_and_has_to_ignore.1),
        case row_and_has_to_ignore.1 && current_col == col_to_ignore {
          False -> [head, ..desired_items]
          True -> desired_items
        },
        col_to_ignore,
        current_col + 1,
        num_until_desired,
        num_desired - 1,
      )
    _ -> desired_items
  }
}

// adds up paper from adjacent breadth tiles
fn num_paper(desired_items: List(String), current_index: Int, sum: Int) {
  case desired_items {
    [head, ..rest] -> {
      case head {
        "@" -> num_paper(rest, current_index + 1, sum + 1)
        _ -> num_paper(rest, current_index + 1, sum)
      }
    }
    _ -> sum
  }
}

pub fn pt_2(input: String) {
  todo as "part 2 not implemented"
}
