import gleam/int
import gleam/list
import gleam/string

pub fn pt_1(input: String) {
  list.map(parse_input(input), get_highest_joltage(get_new_candidate_pt1, 2, _))
  |> list.fold(0, int.add)
}

fn parse_input(input: String) -> List(String) {
  string.split(input, "\n")
}

fn get_highest_joltage(
  candidate_calc: fn(String, Int) -> Int,
  num_digits: Int,
  input: String,
) {
  let candidate = string.slice(input, -num_digits, num_digits)
  let reversed_substring =
    string.slice(
      string.reverse(input),
      num_digits,
      string.length(input) - num_digits,
    )

  get_highest_joltage_loop(
    candidate_calc,
    reversed_substring,
    assert_int(candidate),
  )
}

fn get_highest_joltage_loop(
  candidate_calc: fn(String, Int) -> Int,
  input_substring: String,
  candidate: Int,
) {
  case string.pop_grapheme(input_substring) {
    Error(Nil) -> candidate
    Ok(#(head, rest)) ->
      get_highest_joltage_loop(
        candidate_calc,
        rest,
        candidate_calc(head, candidate),
      )
  }
}

/// Gets the max comparing three numbers: 
///   - the original 2 digit candidate
///   - this new digit prepended to the first digit of the candidate
///   - this new digit prepended to the second digit of the candidate
fn get_new_candidate_pt1(new_digit: String, two_digit_candidate: Int) {
  two_digit_candidate
  |> int.max(
    assert_int(
      new_digit <> string.slice(int.to_string(two_digit_candidate), 0, 1),
    ),
    _,
  )
  |> int.max(
    assert_int(
      new_digit <> string.slice(int.to_string(two_digit_candidate), 1, 1),
    ),
    _,
  )
}

fn assert_int(input: String) {
  let assert Ok(i) = int.parse(input) as "this must be a number"
  i
}

pub fn pt_2(input: String) {
  list.map(parse_input(input), get_highest_joltage(get_new_candidate_pt2, 12, _))
  |> list.fold(0, int.add)
}

/// Compares lots of numbers now...
///   - the original 12-digit candidate
///   - This first digit prepended every permutation of 11 digits 
///     from the 12-digit candidate (preserve ordering). There are 11 such numbers.
fn get_new_candidate_pt2(digit: String, candidate: Int) {
  list.map(
    list.range(0, string.length(int.to_string(candidate)) - 1),
    get_candidate_substring(digit, int.to_string(candidate), _),
  )
  |> list.fold(candidate, int.max)
}

/// Gets a substring of a string with: 
///   - digit prepended to the string
///   - the index_to_ignore removed from the string
fn get_candidate_substring(
  digit: String,
  candidate: String,
  index_to_ignore: Int,
) {
  assert_int(
    digit
    <> string.slice(candidate, 0, index_to_ignore)
    <> string.slice(
      candidate,
      index_to_ignore + 1,
      string.length(candidate) - 1,
    ),
  )
}
