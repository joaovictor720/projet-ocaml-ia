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

  let is_final dfa q = List.mem q dfa.finals

  (* Intersection de deux DFA *)
  let inter d1 d2 =
    let states = List.concat_map (fun s1 ->
                  List.map (fun s2 -> (s1, s2)) d2.states
                ) d1.states in
    let start = (d1.start, d2.start) in
    let finals = List.filter (fun (s1, s2) ->
                    is_final d1 s1 && is_final d2 s2
                  ) states in
    let delta (s1, s2) c = (d1.delta s1 c, d2.delta s2 c) in
    { alpha = d1.alpha; states; start; finals; delta }

  (* Équivalence naïve *)
  let equivalent d1 d2 =
    let rec reachable visited = function
      | [] -> visited
      | q :: qs ->
        if List.mem q visited then reachable visited qs
        else
          let next = List.concat_map (fun c -> [d1.delta (fst q) c, d2.delta (snd q) c]) d1.alpha in
          reachable (q :: visited) (next @ qs)
    in
    let reachable_states = reachable [] [(d1.start, d2.start)] in
    List.for_all (fun (s1, s2) ->
      is_final d1 s1 = is_final d2 s2
    ) reachable_states

end
