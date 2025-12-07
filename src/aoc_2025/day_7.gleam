import gleam/int
import gleam/list
import gleam/string

pub fn pt_1(input: String) {
  let room_state = parse_input(input)

  let RoomState(updated_rows) = fire_beam(room_state)

  updated_rows
  |> list.map(fn(row_state) {
    list.map(row_state.splitters, fn(splitter) {
      case splitter.used {
        True -> 1
        False -> 0
      }
    })
  })
  |> list.flatten
  |> list.reduce(int.add)
}

type Beam {
  Beam(col: Int)
}

type Splitter {
  Splitter(col: Int, used: Bool)
}

type RowState {
  RowState(beams: List(Beam), splitters: List(Splitter))
}

type RoomState {
  RoomState(rows: List(RowState))
}

fn parse_input(input: String) {
  let lines = string.split(input, "\n")
  let length = case lines {
    [head, ..] -> string.length(head)
    _ -> panic as "malformed input: there cannot be any empty lines."
  }

  lines
  |> list.map(string.split(_, ""))
  |> list.map(list.zip(list.range(0, length - 1), _))
  |> list.map(parse_initial_row_state(_, RowState([], [])))
  |> RoomState
}

fn parse_initial_row_state(row: List(#(Int, String)), row_state: RowState) {
  case row {
    [] -> row_state
    [head, ..rest] ->
      parse_initial_row_state(rest, parse_element(head, row_state))
  }
}

fn parse_element(element: #(Int, String), row_state: RowState) {
  case element {
    #(col, "S") -> RowState([Beam(col), ..row_state.beams], row_state.splitters)
    #(col, "^") ->
      RowState(row_state.beams, [Splitter(col, False), ..row_state.splitters])
    _ -> row_state
  }
}

fn update_current_row(current: RowState, previous: RowState) {
  let previous_beam_cols = list.map(previous.beams, fn(beam) { beam.col })
  let updated_splitters =
    list.map(current.splitters, fn(splitter) {
      case list.contains(previous_beam_cols, splitter.col) {
        True -> Splitter(splitter.col, True)
        False -> Splitter(splitter.col, False)
      }
    })
  let splitters_used =
    list.filter(updated_splitters, fn(splitter) { splitter.used })

  let continuing_beams =
    previous_beam_cols
    |> list.filter(fn(col) {
      !list.contains(
        list.map(splitters_used, fn(splitter) { splitter.col }),
        col,
      )
    })
    |> list.map(fn(col) { Beam(col) })
  let new_beams =
    list.map(splitters_used, fn(splitter) {
      [splitter.col - 1, splitter.col + 1]
    })
    |> list.flatten
    |> list.unique
    |> list.map(fn(col) { Beam(col) })

  RowState(list.append(continuing_beams, new_beams), updated_splitters)
}

fn fire_beam(state: RoomState) {
  let RoomState(rows) = state

  case rows {
    // the first row has the initial beam, so its update is a no-op
    [first, ..rest] -> fire_beam_loop(rest, [first])
    _ -> state
  }
}

fn fire_beam_loop(rows: List(RowState), updated_rows_reversed: List(RowState)) {
  assert updated_rows_reversed != []
    as "you cannot provide an empty updated_rows_reversed"
  case rows, updated_rows_reversed {
    [], _ -> RoomState(list.reverse(updated_rows_reversed))
    [current, ..rest_to_process], [previous, ..rest_already_processed] ->
      fire_beam_loop(rest_to_process, [
        update_current_row(current, previous),
        previous,
        ..rest_already_processed
      ])
    _, [] -> panic as "you cannot provide an empty updated_rows_reversed"
  }
}

pub fn pt_2(input: String) {
  todo as "part 2 not implemented"
}
