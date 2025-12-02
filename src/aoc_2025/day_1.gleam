import gleam/int
import gleam/list
import gleam/string

pub fn pt_1(input: String) {
  list.fold(parse_input(input), PasswordAccum(50, 0), fold_password_accum_pt_1).password
}

type Direction {
  Left
  Right
}

type Rotation {
  // clicks is non-zero
  Rotation(dir: Direction, clicks: Int)
}

fn parse_input(input: String) -> List(Rotation) {
  list.map(string.split(input, "\n"), to_rotation)
}

fn to_rotation(line: String) -> Rotation {
  case line {
    "L" <> clicks -> {
      let assert Ok(i) = int.parse(clicks) as "this should be an int"
      Rotation(Left, i)
    }
    "R" <> clicks -> {
      let assert Ok(i) = int.parse(clicks) as "this should be an int"
      Rotation(Right, i)
    }
    _ -> panic as "input must match above format"
  }
}

fn calculate_new_position(position: Int, rotation: Rotation) {
  case rotation {
    Rotation(Left, clicks) ->
      case { position - clicks } % 100 < 0 {
        True -> { { position - clicks } % 100 } + 100
        // have to mod 100 for cases where { position - clicks } % 100 == 0
        // position - clicks could also be > 0 here
        False -> { position - clicks } % 100
      }
    Rotation(Right, clicks) -> { position + clicks } % 100
  }
}

type PasswordAccum {
  PasswordAccum(position: Int, password: Int)
}

fn fold_password_accum_pt_1(accum: PasswordAccum, rotation: Rotation) {
  let new_position = calculate_new_position(accum.position, rotation)
  let new_password = case new_position {
    0 -> accum.password + 1
    _ -> accum.password
  }
  PasswordAccum(new_position, new_password)
}

pub fn pt_2(input: String) {
  list.fold(parse_input(input), PasswordAccum(50, 0), fold_password_accum_pt_2).password
}

fn calculate_password_increment(position: Int, rotation: Rotation) {
  case rotation {
    Rotation(Left, clicks) ->
      case position - clicks <= 0 {
        True if position - clicks < 0 -> {
          case position == 0 {
            // We do not count the first position at 0; it was already counted
            True -> { clicks - position } / 100
            // Account for the first crossing of 0 by adding 1.
            False -> { clicks - position } / 100 + 1
          }
        }
        // position - clicks = 0, the rotation has landed on 0
        True -> 1
        // position - clicks > 0, 0 has not been crossed at all
        False -> 0
      }
    Rotation(Right, clicks) -> { position + clicks } / 100
  }
}

fn fold_password_accum_pt_2(accum: PasswordAccum, rotation: Rotation) {
  let new_position = calculate_new_position(accum.position, rotation)
  let new_password =
    calculate_password_increment(accum.position, rotation) + accum.password
  PasswordAccum(new_position, new_password)
}
