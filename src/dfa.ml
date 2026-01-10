module Dfa = struct
  module Alphabet = struct type t = char list end
  module Word = struct
    type t = char list
    let epsilon = []
    let to_string w = String.concat "" (List.map (String.make 1) w)
    let of_string s = s |> String.to_seq |> List.of_seq
  end
  type 'state t = {
    alpha  : Alphabet.t;
    states : 'state list;
    start  : 'state;
    finals : 'state list;
    delta  : 'state -> char -> 'state;
  }
  let membership dfa word =
    let rec loop q = function
      | [] -> List.mem q dfa.finals
      | c :: cs -> loop (dfa.delta q c) cs
    in loop dfa.start word
  let negate dfa = { dfa with finals = List.filter (fun s -> not (List.mem s dfa.finals)) dfa.states }
  let inter dfa1 dfa2 =
    let new_states = List.concat_map (fun s1 -> List.map (fun s2 -> (s1, s2)) dfa2.states) dfa1.states in
    { alpha = dfa1.alpha; states = new_states; start = (dfa1.start, dfa2.start);
      finals = List.filter (fun (s1, s2) -> List.mem s1 dfa1.finals && List.mem s2 dfa2.finals) new_states;
      delta = (fun (s1, s2) c -> (dfa1.delta s1 c, dfa2.delta s2 c)); }
  let is_empty dfa =
    let rec bfs visited to_visit = match to_visit with
      | [] -> true | q :: _ when List.mem q dfa.finals -> false
      | q :: qs -> if List.mem q visited then bfs visited qs 
                   else bfs (q :: visited) (qs @ (List.map (dfa.delta q) dfa.alpha))
    in bfs [] [dfa.start]
  let equivalent dfa1 dfa2 =
    is_empty (inter dfa1 (negate dfa2)) && is_empty (inter (negate dfa1) dfa2)
end
