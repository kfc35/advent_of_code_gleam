import gleam/int
import gleam/list
import gleam/result
import gleam/string

pub fn pt_1(input: String) {
  let VerticalMathWorksheet(numbers, operator) = parse_input(input)

  list.reduce(
    solve_individual_problems_vertical(numbers, operator, []),
    int.add,
  )
}

fn solve_individual_problems_vertical(
  numbers: List(List(Int)),
  operator: List(Operation),
  solutions: List(Int),
) {
  case numbers, operator {
    [
      [first, ..first_rest],
      [second, ..second_rest],
      [third, ..third_rest],
      [fourth, ..fourth_rest],
    ],
      [operator, ..op_rest]
    -> {
      solve_individual_problems_vertical(
        [first_rest, second_rest, third_rest, fourth_rest],
        op_rest,
        [apply_operation([first, second, third, fourth], operator), ..solutions],
      )
    }
    _, _ -> solutions
  }
}

type Operation {
  Multiply
  Add
}

fn apply_operation(nums: List(Int), op: Operation) {
  case op {
    Multiply -> result.unwrap(list.reduce(nums, int.multiply), 0)
    Add -> result.unwrap(list.reduce(nums, int.add), 0)
  }
}

// the head operator needs to be applied to the list comprised of the head of each sublist in numbers
type VerticalMathWorksheet {
  VerticalMathWorksheet(numbers: List(List(Int)), operator: List(Operation))
}

fn parse_input(input: String) {
  string.split(input, "\n")
  |> list.map(string.trim)
  |> list.map(fn(str) { string.split(str, " ") })
  |> list.map(list.filter(_, fn(str) { str != "" }))
  |> fn(lists) {
    case lists {
      [first, second, third, fourth, operations] -> {
        VerticalMathWorksheet(
          list.map([first, second, third, fourth], list.map(_, assert_int)),
          list.map(operations, parse_operation),
        )
      }
      _ -> panic as "malformed input"
    }
  }
}

fn assert_int(input: String) {
  let assert Ok(i) = int.parse(input) as "this must be a number"
  i
}

fn parse_operation(op_str: String) {
  case op_str {
    "*" -> Multiply
    "+" -> Add
    _ -> panic as "malformed input"
  }
}

// -- END DAY 1 //

pub fn pt_2(input: String) {
  let split_splits = parse_input_pt_2(input)
  let HorizontalMathWorksheet(numbers, operators) =
    create_worksheet(split_splits, [], [], [])

  list.map2(numbers, operators, apply_operation)
  |> list.reduce(int.add)
}

// the head operator needs to be applied to the head of numbers
type HorizontalMathWorksheet {
  HorizontalMathWorksheet(numbers: List(List(Int)), operator: List(Operation))
}

fn parse_input_pt_2(input: String) {
  string.split(input, "\n")
  |> list.map(string.split(_, ""))
}

fn create_worksheet(
  split_splits: List(List(String)),
  working_lof_numbers: List(Int),
  lof_lof_numbers: List(List(Int)),
  operators: List(Operation),
) {
  case split_splits {
    // columns that have an operator at the bottom
    [
      [first_char, ..first_rest],
      [second_char, ..second_rest],
      [third_char, ..third_rest],
      [fourth_char, ..fourth_rest],
      [op_str, ..op_rest],
    ]
      if op_str == "*" || op_str == "+"
    -> {
      create_worksheet(
        [first_rest, second_rest, third_rest, fourth_rest, op_rest],
        [
          assert_int(string.trim(
            first_char <> second_char <> third_char <> fourth_char,
          )),
        ],
        lof_lof_numbers,
        [parse_operation(op_str), ..operators],
      )
    }
    // columns that are completely empty (it means we hit a border btwn problems)
    [
      [" ", ..first_rest],
      [" ", ..second_rest],
      [" ", ..third_rest],
      [" ", ..fourth_rest],
      [" ", ..op_rest],
    ] -> {
      create_worksheet(
        [first_rest, second_rest, third_rest, fourth_rest, op_rest],
        [],
        [working_lof_numbers, ..lof_lof_numbers],
        operators,
      )
    }
    // columns that are just numbers
    [
      [first_char, ..first_rest],
      [second_char, ..second_rest],
      [third_char, ..third_rest],
      [fourth_char, ..fourth_rest],
      [_, ..op_rest],
    ] -> {
      create_worksheet(
        [first_rest, second_rest, third_rest, fourth_rest, op_rest],
        [
          assert_int(string.trim(
            first_char <> second_char <> third_char <> fourth_char,
          )),
          ..working_lof_numbers
        ],
        lof_lof_numbers,
        operators,
      )
    }
    _ ->
      HorizontalMathWorksheet(
        [working_lof_numbers, ..lof_lof_numbers],
        operators,
      )
  }
}
