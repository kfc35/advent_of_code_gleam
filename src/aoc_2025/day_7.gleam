import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn pt_1(input: String) {
  let room_state = parse_input(input)

  let RoomState(updated_rows) = fire_beam(room_state)

  updated_rows
  |> list.map(fn(row_state) {
    list.map(row_state.splitters, fn(splitter) {
      case splitter.used_times > 0 {
        True -> 1
        False -> 0
      }
    })
  })
  |> list.flatten
  |> list.reduce(int.add)
  |> result.unwrap(0)
}

type Beam {
  Beam(col: Int, num_instances: Int)
}

fn beam_compare(a: Beam, b: Beam) {
  int.compare(a.col, b.col)
}

type Splitter {
  Splitter(col: Int, used_times: Int)
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
    #(col, "S") ->
      RowState([Beam(col, 1), ..row_state.beams], row_state.splitters)
    #(col, "^") ->
      RowState(row_state.beams, [Splitter(col, 0), ..row_state.splitters])
    _ -> row_state
  }
}

fn update_current_row(current: RowState, previous: RowState) {
  let updated_splitters =
    list.map(current.splitters, fn(splitter) {
      case list.find(previous.beams, fn(beam) { beam.col == splitter.col }) {
        Ok(beam) ->
          Splitter(splitter.col, splitter.used_times + beam.num_instances)
        Error(_) -> Splitter(splitter.col, splitter.used_times)
      }
    })
    |> list.reverse()
  let splitters_used =
    list.filter(updated_splitters, fn(splitter) { splitter.used_times > 0 })

  let continuing_beams =
    previous.beams
    |> list.filter(fn(beam) {
      !list.contains(
        list.map(splitters_used, fn(splitter) { splitter.col }),
        beam.col,
      )
    })
  let new_beams =
    list.map(splitters_used, fn(splitter) {
      [splitter.col - 1, splitter.col + 1]
    })
    |> list.flatten
    |> list.map(fn(col) { Beam(col, 1) })
  let coalesce_beams =
    list.append(continuing_beams, new_beams)
    |> list.sort(beam_compare)
    |> list.fold([], fn(accum: List(Beam), beam) {
      case accum {
        [] -> [beam]
        [head, ..rest] -> {
          case head.col == beam.col {
            True -> [
              Beam(head.col, head.num_instances + beam.num_instances),
              ..rest
            ]
            False -> [beam, head, ..rest]
          }
        }
      }
    })
    |> list.reverse
  echo coalesce_beams
  echo updated_splitters

  RowState(coalesce_beams, updated_splitters)
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
  // let room_state = parse_input(input)
  // let RoomState(updated_rows) = fire_beam(room_state)

  todo
}
