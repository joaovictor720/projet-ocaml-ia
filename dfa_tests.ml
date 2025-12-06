open OUnit2
open Dfa

let dfs (dfa : 's Dfa.t) : 's list =
    let rec explore visited = function
      | [] -> List.rev visited
      | q :: rest ->
         if List.mem q visited then
           explore visited rest
         else
           let succs = List.map (dfa.delta q) dfa.alpha in
           explore (q :: visited) (succs @ rest)
    in
    explore [] [dfa.start]

let alphabet = ['a'; 'b']

(* empty language *)
let dfa_epsilon : int Dfa.t =
  let delta _ c =
    match c with
    | 'a' | 'b' -> 1
    | _ -> failwith "bad symbol"
  in
  {
    alpha = alphabet;
    states = [0; 1];
    start = 0;
    finals = [0];
    delta;
  }

(* (aa)*[a|b]* *)
let dfa_even_as: int Dfa.t =
  let delta st c =
    match st, c with
    | 0, 'a' -> 1
    | 1, 'a' -> 0
    | (_ , 'b') -> st
    | _ -> failwith "bad symbol"
  in
  {
    alpha = alphabet;
    states = [0; 1];
    start = 0;
    finals = [0];
    delta;
  }

(* [a|b]*b *)
let dfa_ends_in_b: int Dfa.t =
  let delta _ c =
    match c with
    | 'b' -> 1
    | 'a' -> 0
    | _ -> failwith "bad symbol"
  in
  {
    alpha = alphabet;
    states = [0; 1];
    start = 0;
    finals = [1];
    delta;
  }

let tests = "membership tests" >::: [

  "membership_epsilon" >:: (fun _ ->
      assert_bool "epsilon should be accepted"
        (Dfa.membership dfa_epsilon []);

      assert_bool "a should be rejected"
        (not (Dfa.membership dfa_epsilon ['a']));

      assert_bool "bbabba should be rejected"
        (not (Dfa.membership dfa_epsilon ['b';'b';'a';'b';'b';'a']));
    );

  "membership_even_as" >:: (fun _ ->
      assert_bool "[] is even" (Dfa.membership dfa_even_as []);
      assert_bool "a is odd" (not (Dfa.membership dfa_even_as ['a']));
      assert_bool "aa is even" (Dfa.membership dfa_even_as ['a';'a']);
      assert_bool "aba has even number of as" 
        (Dfa.membership dfa_even_as ['a';'b';'a']);
      assert_bool "bbaaabb has odd number of as"
        (not (Dfa.membership dfa_even_as ['b';'b';'a';'a';'a';'b';'b';'b']));                
    );

  "membership_ends_in_b" >:: (fun _ ->
      assert_bool "[] doesn't end in b"
        (not (Dfa.membership dfa_ends_in_b []));
      assert_bool "b ends in b" (Dfa.membership dfa_ends_in_b ['b']);
      assert_bool "aab ends in b" 
        (Dfa.membership dfa_ends_in_b ['a';'a';'b']);
    );
]

let () =
  run_test_tt_main tests
