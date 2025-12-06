module Dfa = struct

  module Alphabet = struct
    type t = char list
  end

  module Word = struct
    type t = char list
    let epsilon = []
  end

  type 'state t = {
    alpha : Alphabet.t;
    states : 'state list;
    start : 'state;
    finals : 'state list;
    delta : 'state -> char -> 'state;
  }

  (*
    - membership: Verifies if a given word belongs to the language recognized by the DFA
    - how it works: Recursively apply the DFA's transition function to the current pair (state, symbol)
  *)
  let membership dfa word =
    let final_state =
      List.fold_left (fun state symbol -> dfa.delta state symbol) dfa.start word
    in
    List.mem final_state dfa.finals

  let inter _ _ = failwith "not implemented"
  let negate _ = failwith "not implemented"
  let is_empty _ = failwith "not implemented"
  let equivalent _ _ = failwith "not implemented"

end
