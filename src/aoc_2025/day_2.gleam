import gleam/int
import gleam/list

// import gleam/regexp
import gleam/string

pub fn pt_1(input: String) {
  list.fold(string.split(input, ","), 0, fn(accum, range) {
    accum
    + sum_invalid_ids_in_range(to_id_range(range), get_invalid_id_summand_pt1)
  })
}

type IdRange {
  IdRange(lower: Int, upper: Int)
}

fn to_id_range(input: String) -> IdRange {
  case string.split(input, "-") {
    [lower, upper] -> {
      let assert Ok(lower) = int.parse(lower)
      let assert Ok(upper) = int.parse(upper)
      IdRange(lower, upper)
    }
    _ -> panic as "input must be of this format"
  }
}

fn sum_invalid_ids_in_range(range: IdRange, summand_fn: fn(Int) -> Int) {
  sum_invalid_ids_in_range_accum(range.lower, range.upper, summand_fn, 0)
}

fn sum_invalid_ids_in_range_accum(
  current_id: Int,
  upper: Int,
  summand_fn: fn(Int) -> Int,
  accum: Int,
) {
  case current_id > upper {
    True -> accum
    False ->
      sum_invalid_ids_in_range_accum(
        current_id + 1,
        upper,
        summand_fn,
        accum + summand_fn(current_id),
      )
  }
}

// 
// fn get_invalid_id_summand_pt1_regexp(current_id: Int) {
//   let assert Ok(pattern) = regexp.from_string("^([0-9]+)\\1$")
//   case regexp.check(pattern, int.to_string(current_id)) {
//     True -> current_id
//     False -> 0
//   }
// }

fn get_invalid_id_summand_pt1(current_id: Int) {
  let number = int.to_string(current_id)
  let halfway = string.length(number) / 2
  let first_half = string.slice(number, 0, halfway)
  let second_half = string.slice(number, halfway, halfway)
  case string.length(number) % 2 == 0 && first_half == second_half {
    True -> current_id
    False -> 0
  }
}

pub fn pt_2(input: String) {
  list.fold(string.split(input, ","), 0, fn(accum, range) {
    accum
    + sum_invalid_ids_in_range(to_id_range(range), get_invalid_id_summand_pt2)
  })
}

// import gleam/regexp to use this code (gleam add gleam_regexp)
// fn get_invalid_id_summand_pt2_regexp(current_id: Int) {
//   let assert Ok(pattern) = regexp.from_string("^([0-9]+)\\1+$")
//   case regexp.check(pattern, int.to_string(current_id)) {
//     True -> current_id
//     False -> 0
//   }
// }

fn get_invalid_id_summand_pt2(current_id: Int) {
  get_invalid_id_summand_pt2_loop(current_id, 1)
}

fn get_invalid_id_summand_pt2_loop(current_id: Int, substring_size: Int) {
  let number = int.to_string(current_id)
  case string.length(number) % substring_size == 0 {
    True -> {
      case string.length(number) / substring_size > 1 {
        True -> {
          let num_substrings = string.length(number) / substring_size
          let splits =
            list.map(list.range(0, num_substrings - 1), fn(index) {
              string.slice(number, index * substring_size, substring_size)
            })
          let assert [head, ..] = splits as "list guaranteed to have head"
          case list.all(splits, fn(split) { head == split }) {
            True -> current_id
            False ->
              get_invalid_id_summand_pt2_loop(current_id, substring_size + 1)
          }
        }
        False -> 0
      }
    }
    False -> get_invalid_id_summand_pt2_loop(current_id, substring_size + 1)
  }
}
