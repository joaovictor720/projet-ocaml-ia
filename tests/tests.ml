open Dfa

let alphabet = ['a'; 'b']
let make_dfa ~states ~start ~finals ~delta : int Dfa.t =
  { alpha = alphabet; states; start; finals; delta }

(* ---------- Définition des DFA ---------- *)
let dfa_empty = make_dfa ~states:[0] ~start:0 ~finals:[] ~delta:(fun _ _ -> 0)
let dfa_all = make_dfa ~states:[0] ~start:0 ~finals:[0] ~delta:(fun _ _ -> 0)

(* Accepte les mots de longueur paire *)
let dfa_even_len = make_dfa ~states:[0;1] ~start:0 ~finals:[0]
    ~delta:(fun q _ -> 1 - q)

(* Accepte les mots finissant par 'a' *)
let dfa_ends_with_a = make_dfa ~states:[0;1] ~start:0 ~finals:[1]
    ~delta:(fun q c -> if c = 'a' then 1 else 0)

(* Accepte les mots commençant par 'b' *)
let dfa_starts_with_b = make_dfa ~states:[0;1;2] ~start:0 ~finals:[1]
    ~delta:(fun q c -> match q, c with
      | 0, 'b' -> 1
      | 0, 'a' -> 2
      | 1, _ -> 1
      | _ -> 2)

(* ---------- Moteur de test simple ---------- *)
let run_test name condition =
  if condition then Printf.printf "[ OK ] %-40s\n" name
  else (Printf.printf "[ FAIL ] %-40s\n" name; exit 1)

let () =
  Printf.printf "=== ENRICHED TEST SUITE ===\n";

  (* 1. Tests d'équivalence de base *)
  run_test "all_vs_empty" (not (Dfa.equivalent dfa_all dfa_empty));
  
  (* 2. Tests de vacuité (is_empty) *)
  run_test "is_empty_on_empty_dfa" (Dfa.is_empty dfa_empty);
  run_test "is_not_empty_on_all_dfa" (not (Dfa.is_empty dfa_all));

  (* 3. Tests de l'intersection *)
  run_test "intersection_all_empty_is_empty" (
    let inter = Dfa.inter dfa_all dfa_empty in
    Dfa.is_empty inter
  );

  run_test "intersection_with_self_is_equivalent" (
    let inter = Dfa.inter dfa_even_len dfa_even_len in
    Dfa.equivalent inter dfa_even_len
  );

  (* 4. Test d'inclusion via intersection 
     Si A est inclus dans B, alors (A inter B) est équivalent à A *)
  run_test "intersection_logic_inclusion" (
    let inter = Dfa.inter dfa_ends_with_a dfa_all in
    Dfa.equivalent inter dfa_ends_with_a
  );

  (* 5. Test de complémentarité
     L'intersection d'un DFA et de son opposé doit être vide *)
  run_test "intersection_with_negation_is_empty" (
    let dfa_odd_len = Dfa.negate dfa_even_len in
    let inter = Dfa.inter dfa_even_len dfa_odd_len in
    Dfa.is_empty inter
  );

  (* 6. Test d'adhésion (membership) *)
  run_test "membership_starts_with_b" (
    Dfa.membership dfa_starts_with_b ['b'; 'a'; 'b'] && 
    not (Dfa.membership dfa_starts_with_b ['a'; 'b'])
  );

  Printf.printf "=== ALL %d TESTS PASSED ===\n" 7
