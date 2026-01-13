open Dfa

(* Helper: Fixed alphabet for these specific tests *)
let test_alphabet = ['a'; 'b']

(* Helper to quickly construct a DFA record for testing *)
let make_dfa ~states ~start ~finals ~delta : int Dfa.t =
  { alpha = test_alphabet; states; start; finals; delta }

(* ---------- DFA Definitions for Testing ---------- *)

(* Accepts nothing (Empty language) *)
let dfa_empty = make_dfa ~states:[0] ~start:0 ~finals:[] ~delta:(fun _ _ -> 0)

(* Accepts everything (Sigma star) *)
let dfa_all = make_dfa ~states:[0] ~start:0 ~finals:[0] ~delta:(fun _ _ -> 0)

(* Accepts words of even length *)
let dfa_even_len = make_dfa ~states:[0;1] ~start:0 ~finals:[0]
    ~delta:(fun q _ -> 1 - q)

(* Accepts words ending with 'a' *)
let dfa_ends_with_a = make_dfa ~states:[0;1] ~start:0 ~finals:[1]
    ~delta:(fun q c -> if c = 'a' then 1 else 0)

(* Accepts words starting with 'b' *)
let dfa_starts_with_b = make_dfa ~states:[0;1;2] ~start:0 ~finals:[1]
    ~delta:(fun q c -> match q, c with
      | 0, 'b' -> 1    (* First char is 'b', go to success state *)
      | 0, 'a' -> 2    (* First char is 'a', go to trap state *)
      | 1, _ -> 1      (* Stay in success *)
      | _ -> 2)        (* Stay in trap *)

(* ---------- Simple Test Engine ---------- *)

let run_test name condition =
  if condition then Printf.printf "[ OK ] %-40s\n" name
  else (Printf.printf "[ FAIL ] %-40s\n" name; exit 1)

(* ---------- Main Execution ---------- *)

let () =
  Printf.printf "=== ENRICHED TEST SUITE ===\n";

  (* 1. Basic Equivalence Tests *)
  run_test "all_vs_empty" (not (Dfa.equivalent dfa_all dfa_empty));
  
  (* 2. Emptiness Tests (is_empty) *)
  run_test "is_empty_on_empty_dfa" (Dfa.is_empty dfa_empty);
  run_test "is_not_empty_on_all_dfa" (not (Dfa.is_empty dfa_all));

  (* 3. Intersection Tests *)
  run_test "intersection_all_empty_is_empty" (
    let inter = Dfa.inter dfa_all dfa_empty in
    Dfa.is_empty inter
  );

  run_test "intersection_with_self_is_equivalent" (
    let inter = Dfa.inter dfa_even_len dfa_even_len in
    Dfa.equivalent inter dfa_even_len
  );

  (* 4. Inclusion Test via Intersection 
     Logic: If A is a subset of B, then (A inter B) must be equivalent to A *)
  run_test "intersection_logic_inclusion" (
    let inter = Dfa.inter dfa_ends_with_a dfa_all in
    Dfa.equivalent inter dfa_ends_with_a
  );

  (* 5. Complementarity Test
     Logic: The intersection of a DFA and its negation (complement) must be empty *)
  run_test "intersection_with_negation_is_empty" (
    let dfa_odd_len = Dfa.negate dfa_even_len in
    let inter = Dfa.inter dfa_even_len dfa_odd_len in
    Dfa.is_empty inter
  );

  (* 6. Membership Test *)
  run_test "membership_starts_with_b" (
    Dfa.membership dfa_starts_with_b ['b'; 'a'; 'b'] && 
    not (Dfa.membership dfa_starts_with_b ['a'; 'b'])
  );

  Printf.printf "=== ALL %d TESTS PASSED ===\n" 7