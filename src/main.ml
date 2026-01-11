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
  algo : LStar.algorithm;
  use_cache : bool;
  results_dir : string;
}

(* ========================================== *)
(* UTILITIES                                  *)
(* ========================================== *)

let ensure_dir dir =
  if not (Sys.file_exists dir) then Sys.mkdir dir 0o755

let string_to_char_list s =
  List.of_seq (String.to_seq s)

let export_dot dfa filename =
  let oc = open_out filename in
  Printf.fprintf oc "digraph DFA { rankdir=LR; node [shape = circle];\n";
(* CORREÇÃO: Verifica se a lista não está vazia antes de escrever *)
  if dfa.finals <> [] then
    Printf.fprintf oc "  node [shape = doublecircle]; %s;\n" (String.concat " " (List.map string_of_int dfa.finals));  Printf.fprintf oc "  node [shape = circle];\n"; (* Reset style *)
  Printf.fprintf oc "  secret_node [style=invis, shape=point]; secret_node -> %d [label=\"start\"];\n" dfa.start;
  List.iter (fun q ->
    let transitions = List.fold_left (fun acc a ->
        let target = dfa.delta q a in
        let existing = try List.assoc target acc with Not_found -> [] in
        (target, a :: existing) :: (List.remove_assoc target acc)
      ) [] dfa.alpha 
    in
    List.iter (fun (t, chars) ->
      let lbl = String.concat ", " (List.map (String.make 1) (List.sort Char.compare chars)) in
      Printf.fprintf oc "  %d -> %d [label=\"%s\"];\n" q t lbl
    ) transitions
  ) dfa.states;
  Printf.fprintf oc "}\n"; close_out oc

(* ========================================== *)
(* ORACLE WRAPPERS                            *)
(* ========================================== *)

let make_logged_oracle oracle log_file =
  let oc = open_out log_file in
  let counter = ref 0 in
  let wrapper w =
    incr counter;
    let res = oracle w in
    Printf.fprintf oc "[Query %d] Word: '%s' -> %b\n" !counter w res;
    res
  in
  (wrapper, counter, oc)

let make_cached_oracle oracle log_file =
  let oc = open_out log_file in
  let counter = ref 0 in
  let cache = Hashtbl.create 2048 in
  
  let wrapper w =
    try
      Hashtbl.find cache w
    with Not_found ->
      incr counter;
      let res = oracle w in
      Printf.fprintf oc "[Query %d] Word: '%s' -> %b\n" !counter w res;
      Hashtbl.add cache w res;
      res
  in
  (wrapper, counter, oc)

(* ========================================== *)
(* CORE LOGIC                                 *)
(* ========================================== *)

let run_learning_scenario cfg (tag, name, oracle) =
  (* 1. Determine Folder Name based on CONFIGURATION only *)
  let algo_suffix = match cfg.algo with LStar.Angluin -> "angluin" | LStar.RivestSchapire -> "rs" in
  let cache_suffix = if cfg.use_cache then "cached" else "raw" in
  
  (* Example folder: results/rs_cached/ *)
  let config_dir_name = Printf.sprintf "%s_%s" algo_suffix cache_suffix in
  let run_dir = Filename.concat cfg.results_dir config_dir_name in
  ensure_dir run_dir;

  Printf.printf ">> Learning: %s [Algo: %s | Cache: %b]\n" name algo_suffix cfg.use_cache;
  
  (* 2. Determine Filenames based on TARGET tag *)
  (* Example file: results/rs_cached/even_ones_queries.log *)
  let log_filename = Filename.concat run_dir (Printf.sprintf "%s_queries.log" tag) in
  
  let (spy_oracle, query_count, log_channel) = 
    if cfg.use_cache then make_cached_oracle oracle log_filename
    else make_logged_oracle oracle log_filename
  in
  
  let test_words = [
    ""; "0"; "1"; "00"; "01"; "10"; "11"; "1100"; "111"; "10101"; 
    "1111"; "1001"; "0101"; "10110"; "11101"; "11111"; "00000"
  ] in

  try 
    let alphabet = ['0'; '1'] in
    let start_time = Sys.time () in
    
    let (dfa, debug_steps) = LStar.learn cfg.algo alphabet spy_oracle in
    let duration = Sys.time () -. start_time in

    (* HTML Generator *)
    let html_filename = Filename.concat run_dir (Printf.sprintf "%s_debug.html" tag) in
    let oc_html = open_out html_filename in
    
    Printf.fprintf oc_html "<html><head><title>%s Trace</title>
    <style>body{font-family:sans-serif;background:#f4f4f9;padding:20px} .step{display:none;background:#fff;padding:20px;border-radius:8px} .active{display:block} table{border-collapse:collapse} td,th{border:1px solid #ccc;padding:5px}</style>
    </head><body><h1>Trace: %s</h1>
    <h3>Config: %s | %s</h3>
    <p><strong>Queries:</strong> %d | <strong>Time:</strong> %.4fs</p>
    <button onclick='mv(-1)'>Prev</button> <span id='lbl'>Step 1</span> <button onclick='mv(1)'>Next</button>" 
    name name algo_suffix (if cfg.use_cache then "Cache ON" else "Cache OFF") !query_count duration;

    List.iteri (fun i h -> Printf.fprintf oc_html "<div class='step' id='s%d'><h2>Step %d</h2>%s</div>" (i+1) (i+1) h) debug_steps;
    
    Printf.fprintf oc_html "<script>let c=1,t=%d;function mv(d){c+=d;if(c<1)c=1;if(c>t)c=t;up()}function up(){document.querySelectorAll('.step').forEach(e=>e.classList.remove('active'));document.getElementById('s'+c).classList.add('active');document.getElementById('lbl').innerText='Step '+c}up()</script></body></html>" (List.length debug_steps);
    close_out oc_html;

    (* Export & Verify *)
    export_dot dfa (Filename.concat run_dir (Printf.sprintf "%s.dot" tag));
    
    let errors = List.fold_left (fun acc w ->
      if Dfa.membership dfa (string_to_char_list w) <> oracle w then acc + 1 else acc
    ) 0 test_words in

    Printf.printf "   [i] Time: %.4fs | Queries: %d | States: %d\n" duration !query_count (List.length dfa.states);
    if errors > 0 then Printf.printf "   [FAIL] %d errors\n" errors else Printf.printf "   [OK] Verified\n";
    
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
  let algo_ref = ref "rs" in
  let no_cache_ref = ref false in
  
  let speclist = [
    ("-t", Arg.Set_string target_ref, "Run a specific scenario by tag");
    ("-list", Arg.Set list_ref, "List all available scenarios");
    ("-i", Arg.Set interactive_ref, "Interactive Mode");
    ("-algo", Arg.Set_string algo_ref, "angluin | rs");
    ("-no-cache", Arg.Set no_cache_ref, "Disable memoization");
  ] in
  
  let usage = "Usage: ./bin/lstar [-t <tag>] [-algo rs] [-no-cache]" in
  Arg.parse speclist (fun _ -> ()) usage;
  
  let algo = match String.lowercase_ascii !algo_ref with
    | "angluin" -> LStar.Angluin
    | _ -> LStar.RivestSchapire
  in
  
  {
    target = if !target_ref = "" then None else Some !target_ref;
    list_mode = !list_ref;
    interactive = !interactive_ref;
    algo = algo;
    use_cache = not !no_cache_ref;
    results_dir = "results";
  }

(* ========================================== *)
(* ENTRY POINT                                *)
(* ========================================== *)

let () =
  let cfg = parse_config () in

  if cfg.list_mode then (
    List.iter (fun (tag, desc, _) -> Printf.printf "  %-15s : %s\n" tag desc) Targets.all;
    exit 0
  );

  ensure_dir cfg.results_dir;

  print_endline "\n===========================================";
  print_endline "   AKLEENATOR - LAB BENCHMARK";
  print_endline "===========================================\n";

  if cfg.interactive then (
    run_learning_scenario cfg ("human", "Interactive Session", Targets.oracle_human);
    exit 0
  );

  let scenarios = match cfg.target with
    | None -> Targets.all 
    | Some t -> List.filter (fun (tag, _, _) -> tag = t) Targets.all
  in

  List.iter (run_learning_scenario cfg) scenarios;
  print_endline "\n[Done]"