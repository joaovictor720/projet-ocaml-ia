open OUnit2
open Dfa

let alphabet = ['a'; 'b']

let make_dfa ~states ~start ~finals ~delta : int Dfa.t =
  { alpha = alphabet; states; start; finals; delta }

(* DFA simples *)
let dfa_empty =
  make_dfa ~states:[0] ~start:0 ~finals:[] ~delta:(fun _ _ -> 0)

let dfa_all =
  make_dfa ~states:[0] ~start:0 ~finals:[0] ~delta:(fun _ _ -> 0)

let dfa_ends_in_b =
  make_dfa
    ~states:[0;1]
    ~start:0
    ~finals:[1]
    ~delta:(fun q c -> match q, c with
                       | 0, 'a' -> 0 | 0, 'b' -> 1
                       | 1, 'a' -> 0 | 1, 'b' -> 1
                       | _ -> 0)

(* Tests *)
let tests = "inter and equivalent tests" >::: [

  "all_equiv_all" >:: (fun _ ->
    assert_bool "all == all" (Dfa.equivalent dfa_all dfa_all)
  );

  "empty_not_equiv_all" >:: (fun _ ->
    assert_bool "empty != all" (not (Dfa.equivalent dfa_empty dfa_all))
  );

  "inter_with_empty" >:: (fun _ ->
    let d = Dfa.inter dfa_all dfa_empty in
    assert_bool "inter(all, empty) == empty" (Dfa.equivalent d dfa_empty)
  );

  "inter_all_with_ends_in_b" >:: (fun _ ->
    let d = Dfa.inter dfa_all dfa_ends_in_b in
    assert_bool "inter(all, ends_in_b) == ends_in_b" (Dfa.equivalent d dfa_ends_in_b)
  );

]

let () = run_test_tt_main tests
