import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn pt_1(input: String) {
  let room = parse_input(input)
  let row_indices = list.range(0, list.length(room) - 1)
  let room_col_length = case room {
    [head, ..] -> list.length(head)
    _ -> 0
  }
  let col_indices = list.range(0, room_col_length - 1)

  let room_forklift_map = {
    use row, row_index <- list.map2(room, row_indices)
    use item, col_index <- list.map2(row, col_indices)
    can_forklift(room, item, row_index, col_index, 1)
  }

  room_forklift_map
  |> list.flatten
  |> list.reduce(int.add)
  |> result.unwrap(0)
}

fn parse_input(input: String) -> List(List(String)) {
  string.split(input, "\n")
  |> list.map(string.split(_, ""))
}

fn can_forklift(
  room: List(List(String)),
  current_item: String,
  row: Int,
  col: Int,
  breadth: Int,
) {
  case current_item {
    "@" -> check_surrounding_tiles(room, row, col, breadth)
    _ -> 0
  }
}

// Returns 1 if passes check, 0 if false
fn check_surrounding_tiles(
  room: List(List(String)),
  row: Int,
  col: Int,
  breadth: Int,
) {
  let room_row_length = list.length(room)
  let room_col_length = case room {
    [head, ..] -> list.length(head)
    _ -> 0
  }

  // (0,0) matches top left corner of room.
  let top_row = int.max(row - breadth, 0)
  let bottom_row = int.min(row + breadth, room_row_length - 1)
  let num_rows = bottom_row - top_row + 1
  let left_col = int.max(col - breadth, 0)
  let right_col = int.min(col + breadth, room_col_length - 1)
  let num_cols = right_col - left_col + 1

  let paper_unflattened =
    find_desired_rows_flipped(room, [], top_row, num_rows)
    // mark the row that has the index to ignore
    |> list.zip(
      list.range(bottom_row, top_row)
      |> list.map(fn(index) { index == row }),
    )
    |> list.map(find_desired_items(_, [], col, 0, left_col, num_cols))

  let paper =
    paper_unflattened
    |> list.flatten
    |> list.map(fn(item) {
      case item {
        "@" -> 1
        _ -> 0
      }
    })
    |> list.reduce(int.add)

  case paper {
    Ok(sum) if sum < 4 -> 1
    _ -> 0
  }
}

/// this function returns the desired rows from room between "num_until_desired"
/// and "num_until_desired" + num_desired, 0-indexed
/// as a side effect, it returns a reversed order of the rows for optimization
/// ultimately, that is fine, since we do not care about orientation luckily.
fn find_desired_rows_flipped(
  room: List(List(String)),
  desired_rows: List(List(String)),
  num_until_desired: Int,
  num_desired_left: Int,
) {
  case room {
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

pub fn pt_2(input: String) {
  let room = parse_input(input)
  let row_indices = list.range(0, list.length(room) - 1)
  let room_col_length = case room {
    [head, ..] -> list.length(head)
    _ -> 0
  }
  let col_indices = list.range(0, room_col_length - 1)

  forklift_loop(room, row_indices, col_indices, 0)
}

fn forklift_loop(
  room: List(List(String)),
  row_indices: List(Int),
  col_indices: List(Int),
  total_removed: Int,
) {
  let update_map = {
    use row, row_index <- list.map2(room, row_indices)
    use item, col_index <- list.map2(row, col_indices)
    can_forklift(room, item, row_index, col_index, 1)
  }
  let num_removed_result =
    update_map
    |> list.flatten
    |> list.reduce(int.add)

  case num_removed_result {
    Ok(0) -> total_removed
    Error(_) -> total_removed
    Ok(num_removed) ->
      forklift_loop(
        update_room(room, update_map),
        row_indices,
        col_indices,
        total_removed + num_removed,
      )
  }
}

/// Updates the room from the given update map where, for a given entry,
/// 1 -> replace with "."
/// 0 -> keep the original entry
/// Updates the room 
fn update_room(room: List(List(String)), updates: List(List(Int))) {
  use #(row, updates) <- list.map(list.zip(room, updates))
  use #(item, update) <- list.map(list.zip(row, updates))
  case update == 1 {
    True -> "."
    False -> item
  }
}
