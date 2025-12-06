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


let tests = "dfa tests" >::: [

  "negate" >:: (fun _ ->
      let neg = Dfa.negate dfa_ends_in_b in
      assert_bool "b should be rejected by negation"
        (not (Dfa.membership neg ['b']));
      assert_bool "aab should be rejected"
        (not (Dfa.membership neg ['a';'a';'b']));
      assert_bool "aa ends in a, so accepted by negation"
        (Dfa.membership neg ['a';'a']);
    );

]
  
let () =
  run_test_tt_main tests
