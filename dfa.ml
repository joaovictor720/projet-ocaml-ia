module Dfa = struct

  module Alphabet = struct
    type t = char list
  end

  module Word = struct
    type t = char list
    let epsilon = []
  end

  type 's t = {
    alpha  : Alphabet.t;
    states : 's list;
    start  : 's;
    finals : 's list;
    delta  : 's -> char -> 's;
  }

  (* membership *)
  let membership dfa word =
    let rec step q = function
      | [] -> List.mem q dfa.finals
      | c :: w -> step (dfa.delta q c) w
    in
    step dfa.start word

  (* product construction for intersection *)
  let inter d1 d2 =
    let alpha = d1.alpha in
    let states =
      List.flatten
        (List.map (fun s1 -> List.map (fun s2 -> (s1, s2)) d2.states) d1.states)
    in
    let start = (d1.start, d2.start) in
    let finals =
      List.filter (fun (s1, s2) ->
        List.mem s1 d1.finals && List.mem s2 d2.finals
      ) states
    in
    let delta (q1, q2) c = (d1.delta q1 c, d2.delta q2 c) in
    { alpha; states; start; finals; delta }

  (* negate automaton *)
  let negate dfa =
    let finals =
      List.filter (fun s -> not (List.mem s dfa.finals)) dfa.states
    in
    { dfa with finals }

  (* emptiness: BFS from start, checking if reachable final *)
  let is_empty dfa =
    let rec bfs visited queue =
      match queue with
      | [] -> true
      | q :: qs ->
        if List.mem q dfa.finals then false
        else
          let next =
            List.map (dfa.delta q) dfa.alpha
            |> List.filter (fun s -> not (List.mem s visited))
          in
          bfs (q :: visited) (qs @ next)
    in
    bfs [] [dfa.start]

  (* equivalence: A ≡ B ⇔ (A Δ B) is empty *)
  let equivalent d1 d2 =
    let sym_diff =
      inter (d1) (negate d2)
      |> fun a -> inter (negate d1) d2 |> fun b ->
         (* union of A\B and B\A via product is tricky;
            easier: check emptiness of both *)
         is_empty (inter d1 (negate d2)) &&
         is_empty (inter (negate d1) d2)
    in
    sym_diff

end
