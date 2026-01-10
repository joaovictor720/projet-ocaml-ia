open Dfa
open ObservationTable
open LStar

(* ========================================== *)
(* CONFIGURATION TYPE                         *)
(* ========================================== *)
module D = Dfa
open D

type config = {
  target : string option;
  list_mode : bool;
  interactive : bool;
  results_dir : string;
}

(* ========================================== *)
(* UTILITIES                                  *)
(* ========================================== *)

let ensure_dir dir =
  if not (Sys.file_exists dir) then Sys.mkdir dir 0o755

let string_to_char_list s =
  List.of_seq (String.to_seq s)

(* ========================================== *)
(* GRAPHVIZ EXPORT                            *)
(* ========================================== *)

let export_dot dfa filename =
  let oc = open_out filename in
  Printf.fprintf oc "digraph DFA {\n";
  Printf.fprintf oc "  rankdir=LR;\n";
  Printf.fprintf oc "  node [shape = circle, style=filled, color=black, fillcolor=white];\n";
  
  Printf.fprintf oc "  node [shape = doublecircle]; %s;\n" 
    (String.concat " " (List.map string_of_int dfa.finals));
    
  Printf.fprintf oc "  node [shape = circle];\n";
  Printf.fprintf oc "  secret_node [style=invis, shape=point];\n";
  Printf.fprintf oc "  secret_node -> %d [label=\"start\"];\n" dfa.start;
  
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
(* ORACLE WRAPPER                             *)
(* ========================================== *)

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
(* CORE LOGIC                                 *)
(* ========================================== *)

let run_learning_scenario cfg (tag, name, oracle) =
  Printf.printf ">> Learning Scenario: %s\n" name;
  
  let log_filename = Printf.sprintf "%s/%s_queries.log" cfg.results_dir tag in
  let (spy_oracle, query_count, log_channel) = make_logged_oracle oracle log_filename in
  
  (* Standard test set for verification *)
  let test_words = [
    ""; "0"; "1"; "00"; "01"; "10"; "11"; "1100"; "111"; "10101"; 
    "1111"; "1001"; "0101"; "10110"; "11101"; "11111"; "00000"
  ] in

  try 
    let alphabet = ['0'; '1'] in
    let start_time = Sys.time () in
    
    (* Execute L* Algorithm *)
    (* UPDATED: Capture debug_steps (the HTML list) *)
    let (dfa, debug_steps) = LStar.learn alphabet spy_oracle in
    let duration = Sys.time () -. start_time in

    (* 1. Export HTML Debug Report *)
    let html_filename = Printf.sprintf "%s/%s_debug.html" cfg.results_dir tag in
    let oc_html = open_out html_filename in
    Printf.fprintf oc_html "<html><head><title>%s Debug Trace</title></head><body>" name;
    Printf.fprintf oc_html "<h1>L* Algorithm Trace: %s</h1>\n" name;
    Printf.fprintf oc_html "<p><strong>Total Queries:</strong> %d | <strong>Time:</strong> %.4fs</p><hr/>\n" !query_count duration;
    
    (* Iterate and print each step *)
    List.iteri (fun i html -> 
      Printf.fprintf oc_html "<h3>Step %d</h3>\n" (i + 1);
      Printf.fprintf oc_html "<div style='margin-bottom: 30px;'>%s</div><hr/>\n" html
    ) debug_steps;
    
    Printf.fprintf oc_html "</body></html>";
    close_out oc_html;
    Printf.printf "   [+] Debug trace saved to: %s\n" html_filename;

    (* 2. Export Visuals (DOT) *)
    let dot_filename = Printf.sprintf "%s/%s.dot" cfg.results_dir tag in
    export_dot dfa dot_filename;

    (* 3. Verification Phase *)
    let errors = List.fold_left (fun acc w ->
      let w_chars = string_to_char_list w in
      let res_dfa = Dfa.membership dfa w_chars in
      let res_oracle = oracle w in
      if res_dfa <> res_oracle then (
        Printf.printf "   [ERROR] Discrepancy on '%s'\n" w;
        acc + 1
      ) else acc
    ) 0 test_words in

    Printf.printf "   [i] Time: %.4fs | Queries: %d | States: %d\n" 
      duration !query_count (List.length dfa.states);
    
    if errors = 0 then
      Printf.printf "   [OK] Verification Passed.\n"
    else
      Printf.printf "   [FAIL] Verification Failed (%d errors).\n" errors;
    
    print_endline "-------------------------------------------";
    close_out log_channel

  with e ->
    close_out log_channel;
    Printf.printf "   [FATAL] Exception: %s\n" (Printexc.to_string e);
    exit 1

(* ========================================== *)
(* ARGUMENT PARSING                           *)
(* ========================================== *)

let parse_config () =
  let target_ref = ref "" in
  let list_ref = ref false in
  let interactive_ref = ref false in
  
  let speclist = [
    ("-t", Arg.Set_string target_ref, "Run a specific scenario by tag");
    ("-list", Arg.Set list_ref, "List all available scenarios");
    ("-i", Arg.Set interactive_ref, "Interactive Mode (Human Oracle)");
  ] in
  
  let usage = "Usage: ./bin/lstar [-t <tag>] [-list] [-i]" in
  Arg.parse speclist (fun _ -> ()) usage;
  
  {
    target = if !target_ref = "" then None else Some !target_ref;
    list_mode = !list_ref;
    interactive = !interactive_ref;
    results_dir = "results";
  }

(* ========================================== *)
(* ENTRY POINT                                *)
(* ========================================== *)

let () =
  let cfg = parse_config () in

  (* 1. List Mode *)
  if cfg.list_mode then (
    print_endline "\nAvailable Automated Scenarios:";
    print_endline "-----------------------------";
    List.iter (fun (tag, desc, _) -> 
      Printf.printf "  %-15s : %s\n" tag desc
    ) Targets.all;
    print_endline "-----------------------------";
    print_endline "  (interactive)   : Use -i flag to be the oracle.";
    exit 0
  );

  ensure_dir cfg.results_dir;

  print_endline "\n===========================================";
  print_endline "   AKLEENATOR - L* LEARNING AUTOMATION";
  print_endline "===========================================\n";

  (* 2. Interactive Mode *)
  if cfg.interactive then (
    Printf.printf ">> Mode: INTERACTIVE (You are the oracle)\n";
    Printf.printf ">> Protocol: Type 'y' for True, anything else for False.\n";
    print_endline "-------------------------------------------";
    
    let human_scenario = ("human", "Interactive Session", Targets.oracle_human) in
    run_learning_scenario cfg human_scenario;
    
    print_endline "\n[Done] Interactive session finished.";
    exit 0
  );

  (* 3. Automated Mode *)
  let scenarios = 
    match cfg.target with
    | None -> Targets.all 
    | Some t -> 
        let found = List.filter (fun (tag, _, _) -> tag = t) Targets.all in
        if found = [] then (
          Printf.printf "\n[!] Error: Target '%s' not found.\n" t;
          exit 1
        ) else found
  in

  List.iter (run_learning_scenario cfg) scenarios;
  
  print_endline "\n[Done] Execution finished. Check 'results/' folder."