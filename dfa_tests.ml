open OUnit2
open Dfa

let alphabet = ['a'; 'b']

let make_dfa ~states ~start ~finals ~delta : int Dfa.t =
  { alpha = alphabet; states; start; finals; delta }

(* ---------- Définition des DFA ---------- *)

let dfa_epsilon =
  make_dfa
    ~states:[0;1]
    ~start:0
    ~finals:[0]
    ~delta:(fun q _ -> match q with | 0 -> 1 | 1 -> 1 | _ -> 1)

let dfa_empty =
  make_dfa
    ~states:[0]
    ~start:0
    ~finals:[]
    ~delta:(fun _ _ -> 0)

let dfa_all =
  make_dfa
    ~states:[0]
    ~start:0
    ~finals:[0]
    ~delta:(fun _ _ -> 0)

let dfa_ends_in_b =
  make_dfa
    ~states:[0;1]
    ~start:0
    ~finals:[1]
    ~delta:(fun q c -> match q, c with
                       | 0, 'a' -> 0 | 0, 'b' -> 1
                       | 1, 'a' -> 0 | 1, 'b' -> 1
                       | _ -> 0)
let dfa_starts_ab =
  make_dfa
    ~states:[0;1;2;3]
    ~start:0
    ~finals:[3]
    ~delta:(fun q c -> match q, c with
                       | 0, 'a' -> 1 | 0, 'b' -> 3
                       | 1, 'b' -> 2 | 1, 'a' -> 3
                       | 2, _ -> 3
                       | 3, _ -> 3
                       | _ -> 3)

let dfa_ab_star =
  make_dfa
    ~states:[0;1;2]
    ~start:0
    ~finals:[0]
    ~delta:(fun q c -> match q, c with
                       | 0, 'a' -> 1 | 0, 'b' -> 2
                       | 1, 'b' -> 0 | 1, 'a' -> 2
                       | 2, _ -> 2
                       | _ -> 2)

let dfa_even_a_A =
  make_dfa
    ~states:[0;1]
    ~start:0
    ~finals:[0]
    ~delta:(fun q c -> match q, c with
                       | 0, 'a' -> 1 | 1, 'a' -> 0
                       | 0, 'b' -> 0 | 1, 'b' -> 1
                       | _ -> 0)

let dfa_even_a_B =
  make_dfa
    ~states:[0;1;2]
    ~start:0
    ~finals:[0]
    ~delta:(fun q c -> match q, c with
                       | 0, 'a' -> 1 | 0, 'b' -> 0
                       | 1, 'a' -> 0 | 1, 'b' -> 1
                       | 2, _ -> 2
                       | _ -> 2)

let dfa_a_mod3 =
  make_dfa
    ~states:[0;1;2]
    ~start:0
    ~finals:[0]
    ~delta:(fun q c -> match q, c with
                       | 0, 'a' -> 1 | 1, 'a' -> 2 | 2, 'a' -> 0
                       | s, 'b' -> s
                       | _ -> 0)

let dfa_contains_abba =
  make_dfa
    ~states:[0;1;2;3;4]
    ~start:0
    ~finals:[4]
    ~delta:(fun q c -> match q, c with
                       | 0, 'a' -> 1 | 0, 'b' -> 0
                       | 1, 'b' -> 2 | 1, 'a' -> 1
                       | 2, 'b' -> 3 | 2, 'a' -> 1
                       | 3, 'a' -> 4 | 3, 'b' -> 0
                       | 4, _ -> 4
                       | _ -> 0)

let dfa_contains_aba =
  make_dfa
    ~states:[0;1;2;3]
    ~start:0
    ~finals:[3]
    ~delta:(fun q c -> match q, c with
                       | 0, 'a' -> 1 | 0, 'b' -> 0
                       | 1, 'b' -> 0 | 1, 'a' -> 1
                       | 2, 'a' -> 3 | 2, 'b' -> 0
                       | 3, _ -> 3
                       | _ -> 0)
let complement (dfa : int Dfa.t) =
  let finals = List.filter (fun s -> not (List.mem s dfa.finals)) dfa.states in
  { dfa with finals }

let dfa_all_complement = complement dfa_all
let dfa_empty_complement = complement dfa_empty

(* ---------- Suite de tests ---------- *)

let tests = "big dfa test suite" >::: [
  "epsilon_not_equiv_empty" >:: (fun _ ->
    assert_bool "epsilon != empty" (not (Dfa.equivalent dfa_epsilon dfa_empty))
  );
  "all_vs_not_empty" >:: (fun _ ->
    assert_bool "all != empty" (not (Dfa.equivalent dfa_all dfa_empty))
  );
  "all_equiv_all_complement_complement" >:: (fun _ ->
    assert_bool "double complement of all == all" (
      Dfa.equivalent (complement (complement dfa_all)) dfa_all)
  );
  "empty_double_complement" >:: (fun _ ->
    assert_bool "double complement of empty == empty" (
      Dfa.equivalent (complement (complement dfa_empty)) dfa_empty)
  );
  "even_a_equiv_variants" >:: (fun _ ->
    assert_bool "even a's: variant A == variant B" (Dfa.equivalent dfa_even_a_A dfa_even_a_B)
  );
  "contains_aba_vs_abba" >:: (fun _ ->
    assert_bool "aba != abba" (not (Dfa.equivalent dfa_contains_aba dfa_contains_abba))
  );
]

let () = run_test_tt_main tests
                       
