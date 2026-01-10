open Dfa
open ObservationTable
open LStar
open Targets

(* ========================================== *)
(* CONFIGURATION & ALIASES                    *)
(* ========================================== *)
(* Alias Dfa type to avoid deep nesting (Dfa.Dfa.t) *)
module D = Dfa
open D

let results_dir = "results"

(* ========================================== *)
(* UTILITIES                                  *)
(* ========================================== *)

let ensure_results_dir () =
  if not (Sys.file_exists results_dir) then Sys.mkdir results_dir 0o755

let string_to_char_list s =
  List.of_seq (String.to_seq s)

(* ========================================== *)
(* GRAPHVIZ EXPORT                            *)
(* ========================================== *)

(* Exports the DFA to a .dot file. 
   Merges transitions: if q0 -> q1 on '0' and '1', label becomes "0, 1".
*)
let export_dot dfa filename =
  let oc = open_out filename in
  Printf.fprintf oc "digraph DFA {\n";
  Printf.fprintf oc "  rankdir=LR;\n";
  Printf.fprintf oc "  node [shape = circle, style=filled, color=black, fillcolor=white];\n";
  
  (* Double circle for final states *)
  Printf.fprintf oc "  node [shape = doublecircle]; %s;\n" 
    (String.concat " " (List.map string_of_int dfa.finals));
    
  Printf.fprintf oc "  node [shape = circle];\n";
  
  (* Invisible entry point for the start state arrow *)
  Printf.fprintf oc "  secret_node [style=invis, shape=point];\n";
  Printf.fprintf oc "  secret_node -> %d [label=\"start\"];\n" dfa.start;
  
  (* Group transitions by target state to keep graph clean *)
  List.iter (fun q ->
    let transitions = 
      List.fold_left (fun acc a ->
        let target = dfa.delta q a in
        let existing_chars = try List.assoc target acc with Not_found -> [] in
        (target, a :: existing_chars) :: (List.remove_assoc target acc)
      ) [] dfa.alpha 
    in

    List.iter (fun (target, char_list) ->
      let sorted_chars = List.sort Char.compare char_list in
      let label = String.concat ", " (List.map (String.make 1) sorted_chars) in
      Printf.fprintf oc "  %d -> %d [label=\"%s\"];\n" q target label
    ) transitions

  ) dfa.states;
  
  Printf.fprintf oc "}\n";
  close_out oc;
  Printf.printf "   [+] DFA exported to: %s\n" filename

(* ========================================== *)
(* LOGGING WRAPPER                            *)
(* ========================================== *)

(* Wraps an oracle function to log every query to a file *)
let make_logged_oracle oracle log_file =
  let oc = open_out log_file in
  let counter = ref 0 in
  
  let logged_wrapper w =
    incr counter;
    let res = oracle w in
    Printf.fprintf oc "[Query %d] Word: '%s' -> %b\n" !counter w res;
    res
  in
  (logged_wrapper, counter, oc)



(* ========================================== *)
(* MAIN ROUTINE                               *)
(* ========================================== *)

let test_words = [
  ""; "0"; "1"; "00"; "01"; "10"; "11"; "1100"; "111"; "10101"; 
  "1111"; "1001"; "0101"; "10110"; "11101"; "11111"; "00000"
]

let () =
  ensure_results_dir ();
  let alphabet = ['0'; '1'] in

  print_endline "\n===========================================";
  print_endline "   AKLEENATOR - L* LEARNING AUTOMATION";
  print_endline "===========================================\n";

  List.iter (fun (file_tag, human_name, oracle) ->
    Printf.printf ">> Learning Scenario: %s\n" human_name;
    
    let log_filename = Printf.sprintf "%s/%s_queries.log" results_dir file_tag in
    let (spy_oracle, query_count, log_channel) = make_logged_oracle oracle log_filename in

    (* Using try-final to ensure log file closes even if LStar crashes *)
    try 
      let start_time = Sys.time () in
      let (dfa, _) = LStar.learn alphabet spy_oracle in
      let duration = Sys.time () -. start_time in

      (* Export Visual Graph *)
      let dot_filename = Printf.sprintf "%s/%s.dot" results_dir file_tag in
      export_dot dfa dot_filename;

      (* Verification against test set *)
      let errors = List.fold_left (fun acc w ->
        let w_chars = string_to_char_list w in
        let res_dfa = D.membership dfa w_chars in
        let res_oracle = oracle w in
        
        if res_dfa <> res_oracle then (
          Printf.printf "   [ERROR] Discrepancy on '%s' (DFA: %b, Oracle: %b)\n" 
            w res_dfa res_oracle;
          acc + 1
        ) else acc
      ) 0 test_words in

      (* Final Stats *)
      Printf.printf "   [i] Time: %.4fs | Queries: %d | States: %d\n" 
        duration !query_count (List.length dfa.states);
      
      if errors = 0 then
        Printf.printf "   [OK] Verification Passed (%d words).\n" (List.length test_words)
      else
        Printf.printf "   [FAIL] Verification Failed (%d errors).\n" errors;
      
      print_endline "-------------------------------------------";
      
      (* Important: Close the log handle *)
      close_out log_channel

    with e ->
      close_out log_channel;
      Printf.printf "   [FATAL] Exception during learning: %s\n" (Printexc.to_string e);
      exit 1

  ) oracles;
  
  print_endline "\n[Done] Check 'results/' for logs and graphs."