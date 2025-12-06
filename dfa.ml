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


  (** Emptiness check *)
  let is_empty dfa =
    let rec loop visited to_visit =
      match to_visit with
      | [] -> true
      | head::tail -> 
        if List.mem head visited then
          loop visited tail
        else if List.mem head dfa.finals then
          false
        else 
          let neighbors = List.map (fun c -> dfa.delta head c) dfa.alpha in
          loop (head::visited) (neighbors @ tail)
    in
    loop [] [dfa.start]

  
end


