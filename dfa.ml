module Dfa = struct

  module Alphabet = struct
    type t = char list
  end

  module Word = struct
    type t = char list
    let epsilon = []
  end

  (** Deterministic Finite Automaton *)
  type 'state t = {
      alpha : Alphabet.t;
      states : 'state list;
      start : 'state;
      finals : 'state list;
      delta : 'state -> char -> 'state;
    }


  (*val negate : 's t -> 's t*)

  let membership dfa word =
    let final_state =
      List.fold_left (fun state symbol -> dfa.delta state symbol) dfa.start word
    in
    List.mem final_state dfa.finals

 
  let negate dfa =
    let finals = 
      List.filter (fun s -> not (List.mem s dfa.finals)) dfa.states 
    in

  { dfa with finals }


  let inter _ _ = failwith "not implemented"
  let is_empty _ = failwith "not implemented"
  let equivalent _ _ = failwith "not implemented"

end 




