import gleam/int
import gleam/list
import gleam/string

pub fn pt_1(input: String) {
  let InputData(intervals, ids) = parse_input(input)
  {
    use id <- list.map(ids)
    use interval <- list.any(intervals)
    id_in_fresh_interval(id, interval)
  }
  |> list.map(fn(bool) {
    case bool {
      True -> 1
      False -> 0
    }
  })
  |> list.reduce(int.add)
}

type InputData {
  InputData(intervals: List(FreshInterval), ids: List(Int))
}

type FreshInterval {
  FreshInterval(lower: Int, upper: Int)
}

fn id_in_fresh_interval(id: Int, interval: FreshInterval) {
  interval.lower <= id && id <= interval.upper
}

// Parsing Functions

fn parse_input(input: String) {
  case string.split(input, "\n\n") {
    [head, tail] ->
      InputData(
        list.map(string.split(head, "\n"), to_fresh_interval),
        list.map(string.split(tail, "\n"), assert_int),
      )
    _ -> panic as "malformed input"
  }
}

fn to_fresh_interval(number_dash_number: String) {
  case string.split(number_dash_number, "-") {
    [first, second] -> {
      FreshInterval(assert_int(first), assert_int(second))
    }
    _ -> panic as "malformed input"
  }
}

fn assert_int(input: String) {
  let assert Ok(i) = int.parse(input) as "this must be a number"
  i
}

// -- END DAY 1 //

pub fn pt_2(input: String) {
  let InputData(intervals, _) = parse_input(input)
  // Since lists in gleam are single-linked and not indexable...
  // ... it is probably faster to rely on std list sort than roll my own 
  list.sort(intervals, compare_intervals)
  |> list.fold([], try_coalesce_interval_with_sorted_list)
  |> list.map(fn(interval) { interval.upper - interval.lower + 1 })
  |> list.reduce(int.add)
}

fn compare_intervals(a: FreshInterval, b: FreshInterval) {
  int.compare(a.lower, b.lower)
}

fn try_coalesce_interval_with_sorted_list(
  accum: List(FreshInterval),
  next: FreshInterval,
) {
  case accum {
    [head, ..rest] -> {
      case next.lower <= head.upper {
        True -> [
          FreshInterval(
            int.min(head.lower, next.lower),
            int.max(head.upper, next.upper),
          ),
          ..rest
        ]
        False -> [next, head, ..rest]
      }
    }
    [] -> [next]
  }
}
