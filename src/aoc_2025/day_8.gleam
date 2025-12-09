import gleam/dict
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string

pub fn pt_1(input: String) {
  let junction_boxes = parse_input(input)

  let shortest_lights = find_n_shortest_lights(junction_boxes, 1000, 0)
  let circuits = create_circuits(shortest_lights)

  circuits
  |> list.map(set.size)
  |> list.take(3)
  |> list.reduce(int.multiply)
  // should not be empty
  |> result.unwrap(0)
}

// Types & Utils //

type JunctionBox {
  JunctionBox(x: Int, y: Int, z: Int)
}

fn jb_equal(a: JunctionBox, b: JunctionBox) {
  a.x == b.x && a.y == b.y && a.z == b.z
}

fn parse_input(input: String) -> List(JunctionBox) {
  string.split(input, "\n")
  |> list.map(string.split(_, ","))
  |> list.map(list.map(_, assert_int))
  |> list.map(parse_to_junction_box)
}

fn assert_int(input: String) {
  let assert Ok(i) = int.parse(input) as "this must be a number"
  i
}

fn parse_to_junction_box(coords: List(Int)) {
  case coords {
    [x, y, z] -> JunctionBox(x, y, z)
    _ -> panic as "malformed input: every line must be formatted as: x,y,z"
  }
}

type Light {
  Light(a: JunctionBox, b: JunctionBox, distance_squared: Int)
}

fn light_compare(a: Light, b: Light) {
  int.compare(a.distance_squared, b.distance_squared)
}

fn distance_squared(a: JunctionBox, b: JunctionBox) {
  { a.x - b.x }
  * { a.x - b.x }
  + { a.y - b.y }
  * { a.y - b.y }
  + { a.z - b.z }
  * { a.z - b.z }
}

// -- //

// Finding n-Shortest Lights //
// Instead of pagination, this could be made better with a cursor 
// cursor = the longest distance from the previous page
// then we can just filter for n entries that are longer than the cursor!

fn find_n_shortest_lights(boxes: List(JunctionBox), n: Int, page: Int) {
  find_n_shortest_lights_loop(boxes, n, page, [])
}

fn find_n_shortest_lights_loop(
  boxes: List(JunctionBox),
  n: Int,
  page: Int,
  lights: List(Light),
) {
  case boxes {
    [head, ..rest] ->
      find_n_shortest_lights_loop(
        rest,
        n,
        page,
        recalc_shortest_lights(head, rest, n * { page + 1 }, lights),
      )
    [] -> lights |> list.drop(n * page)
  }
}

/// For the given JunctionBox, calculate its distances with the other JunctionBoxes
/// Then, combined with the existing shortest lights, from previous iterations,
/// sort the list and take the updated n-shortest lights
fn recalc_shortest_lights(
  a: JunctionBox,
  others: List(JunctionBox),
  n: Int,
  lights: List(Light),
) {
  case others {
    [] -> lights
    _ ->
      others
      |> list.map(fn(b) { Light(a, b, distance_squared(a, b)) })
      |> list.append(lights, _)
      |> list.sort(light_compare)
      |> list.take(n)
  }
}

// -- //

// Set Detection //

fn create_circuits(lights: List(Light)) {
  case lights {
    [] -> []
    [head, ..rest] -> {
      create_circuits_loop(
        [head.a, head.b],
        dict.new()
          |> dict.insert(head.a, True)
          |> dict.insert(head.b, True),
        set.from_list([head.a, head.b]),
        rest,
        [],
      )
    }
  }
}

fn is_being_processed(
  jbs_processing_dict: dict.Dict(JunctionBox, Bool),
  jb: JunctionBox,
) {
  result.unwrap(dict.get(jbs_processing_dict, jb), False)
}

// compares size descending
fn compare_circuits_size_desc(a: set.Set(JunctionBox), b: set.Set(JunctionBox)) {
  int.compare(set.size(b), set.size(a))
}

fn create_circuits_loop(
  jbs_to_process: List(JunctionBox),
  jbs_processing_dict: dict.Dict(JunctionBox, Bool),
  current_circuit: set.Set(JunctionBox),
  lights_to_process: List(Light),
  all_circuits: List(set.Set(JunctionBox)),
) {
  case lights_to_process {
    [] ->
      [current_circuit, ..all_circuits]
      |> list.sort(compare_circuits_size_desc)
    [first_light, ..other_lights] -> {
      case jbs_to_process {
        [jb, ..other_jbs_to_process] -> {
          let new_circuit_jbs =
            lights_to_process
            |> list.filter(fn(light) {
              jb_equal(jb, light.a) || jb_equal(jb, light.b)
            })
            |> list.map(fn(light) {
              case jb_equal(jb, light.a) {
                True -> light.b
                False -> light.a
              }
            })

          let new_circuit_jbs_to_process =
            new_circuit_jbs
            |> list.filter(fn(jb) {
              !is_being_processed(jbs_processing_dict, jb)
            })

          let updated_jbs_to_process =
            list.append(other_jbs_to_process, new_circuit_jbs_to_process)
          let updated_processing_dict =
            jbs_processing_dict
            |> list.fold(
              new_circuit_jbs_to_process,
              _,
              fn(processing_dict, new_jb) {
                dict.insert(processing_dict, new_jb, True)
              },
            )
            |> dict.insert(jb, True)
          let updated_circuit =
            set.union(current_circuit, set.from_list(new_circuit_jbs))
          let reduced_lights_to_process =
            lights_to_process
            |> list.filter(fn(light) {
              !jb_equal(jb, light.a) && !jb_equal(jb, light.b)
            })

          create_circuits_loop(
            updated_jbs_to_process,
            updated_processing_dict,
            updated_circuit,
            reduced_lights_to_process,
            all_circuits,
          )
        }
        // ran out of jbs to process, but there are still lights to process.
        // we must have finished a whole circuit, so start the process again
        [] -> {
          create_circuits_loop(
            [first_light.a, first_light.b],
            jbs_processing_dict
              |> dict.insert(first_light.a, True)
              |> dict.insert(first_light.b, True),
            set.from_list([first_light.a, first_light.b]),
            other_lights,
            [current_circuit, ..all_circuits],
          )
        }
      }
    }
  }
}

pub fn pt_2(input: String) {
  let junction_boxes = parse_input(input)
  let junction_boxes_length = list.length(junction_boxes)
  let last_light =
    get_final_light_for_complete_circuit(
      junction_boxes,
      junction_boxes_length,
      // * 9 was found empirically by counting the num iterations until solution
      1000 * 9,
      0,
      [],
    )

  last_light.a.x * last_light.b.x
}

fn get_final_light_for_complete_circuit(
  junction_boxes: List(JunctionBox),
  junction_boxes_length: Int,
  step_size: Int,
  iteration: Int,
  circuits: List(set.Set(JunctionBox)),
) {
  let shortest_lights =
    find_n_shortest_lights(junction_boxes, step_size, iteration)
  let #(circuits, maybe_final_light) =
    update_circuits(circuits, shortest_lights, junction_boxes_length)

  case maybe_final_light {
    option.Some(light) -> light
    option.None ->
      get_final_light_for_complete_circuit(
        junction_boxes,
        junction_boxes_length,
        step_size,
        iteration + 1,
        circuits,
      )
  }
}

fn update_circuits(
  circuits: List(set.Set(JunctionBox)),
  new_lights: List(Light),
  junction_boxes_length: Int,
) {
  case new_lights {
    [Light(a, b, dist), ..rest] -> {
      let circuits_to_add_to =
        circuits
        |> list.filter(fn(circuit) {
          set.contains(circuit, a) || set.contains(circuit, b)
        })
      let other_circuits =
        circuits
        |> list.filter(fn(circuit) {
          !set.contains(circuit, a) && !set.contains(circuit, b)
        })
      case circuits_to_add_to {
        // create new circuit
        [] ->
          update_circuits(
            [set.from_list([a, b]), ..circuits],
            rest,
            junction_boxes_length,
          )
        [one_circuit] -> {
          // add to existing circuit
          let updated_circuit =
            one_circuit
            |> set.insert(a)
            |> set.insert(b)
          case set.size(updated_circuit) == junction_boxes_length {
            True -> #([updated_circuit], option.Some(Light(a, b, dist)))
            False ->
              update_circuits(
                [updated_circuit, ..other_circuits],
                rest,
                junction_boxes_length,
              )
          }
        }
        [one, two] -> {
          // perform a merge
          let updated_circuit = set.union(one, two)
          case set.size(updated_circuit) == junction_boxes_length {
            True -> #([updated_circuit], option.Some(Light(a, b, dist)))
            False ->
              update_circuits(
                [updated_circuit, ..other_circuits],
                rest,
                junction_boxes_length,
              )
          }
        }
        _ -> panic as "invariant: this should not happen"
      }
    }
    _ -> {
      // ran out of new lights to process, so return the current state and no final light
      #(circuits |> list.sort(compare_circuits_size_desc), option.None)
    }
  }
}
/// This is not optimized at all, and only works on small datasets. 
/// recursive and slow, does not take advantage of pagination
// fn find_last_light_for_complete_circuit_loop(
//   junction_boxes: List(JunctionBox),
//   junction_boxes_length: Int,
//   n: Int,
//   shortest_lights: List(Light),
//   biggest_circuit: set.Set(JunctionBox),
// ) {
//   let biggest_circuit_size = set.size(biggest_circuit)

//   case
//     biggest_circuit_size == junction_boxes_length,
//     list.reverse(shortest_lights)
//   {
//     True, [last_shortest_light, ..] -> {
//       echo list.reverse(shortest_lights)
//       echo n
//       last_shortest_light
//     }
//     _, _ -> {
//       // replace with finding more shortest lights than the previous.
//       let new_shortest_lights = find_n_shortest_lights(junction_boxes, n + 1, 0)
//       // replace with just updating the circuits instead of calling it anew probably?
//       // or a create_circuit function that short circuits when we find a minimum graph
//       // this means that we have to do merging of sets....
//       let new_circuits = create_circuits(new_shortest_lights)
//       case new_circuits {
//         [new_biggest_circuit, ..] ->
//           find_last_light_for_complete_circuit_loop(
//             junction_boxes,
//             junction_boxes_length,
//             n + 1,
//             new_shortest_lights,
//             new_biggest_circuit,
//           )
//         _ -> panic as "there should be at least one circuit"
//       }
//     }
//   }
// }
