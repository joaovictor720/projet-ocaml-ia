open Dfa
open ObservationTable

(* ========================================== *)
(* TYPE DEFINITIONS                           *)
(* ========================================== *)

type algorithm = 
  | Angluin        (* Classic L* *)
  | RivestSchapire (* Optimized L* *)

(* ========================================== *)
(* COMMON HELPERS                             *)
(* ========================================== *)

let string_to_char_list s = List.of_seq (String.to_seq s)

(* OPTIMIZED: Materializes the DFA Transitions to avoid repeated Oracle calls *)
let build_hypothesis table alphabet oracle =
  (* 1. Identify Unique Rows (States) *)
  (* We cache the row values to avoid re-querying inside the sort *)
  let raw_s_rows = List.map (fun s -> (s, ObservationTable.get_row table oracle s)) table.s in
  let rows = List.map snd raw_s_rows |> List.sort_uniq compare in
  
  let num_states = List.length rows in
  
  let row_to_idx r = 
    match List.find_index (fun x -> x = r) rows with
    | Some i -> i
    | None -> failwith "Fatal: Row not found in hypothesis construction"
  in
  
  (* 2. Find a Representative String 's' for each State Index *)
  (* Instead of searching table.s every time, we pre-calculate this map *)
  let state_reps = Array.init num_states (fun i ->
      let target_row = List.nth rows i in
      (* Find the first 's' in raw_s_rows that produces this row *)
      let (s, _) = List.find (fun (_, r) -> r = target_row) raw_s_rows in
      s
  ) in

  (* 3. Materialize the Transition Matrix *)
  (* Matrix[State][Char] -> Next State Index *)
  (* This executes the oracle queries once per state/char, saving HUGE amounts of time *)
  let transition_matrix = Array.init num_states (fun i ->
      let s = state_reps.(i) in
      List.map (fun c ->
          let next_row = ObservationTable.get_row table oracle (s ^ String.make 1 c) in
          (c, row_to_idx next_row)
      ) alphabet
  ) in

  (* 4. Materialize Final States *)
  let finals_list = List.filter (fun i -> 
      oracle state_reps.(i)
  ) (List.init num_states (fun i -> i)) in

  { Dfa.alpha = alphabet; 
    states = List.init num_states (fun i -> i);
    start = row_to_idx (ObservationTable.get_row table oracle "");
    finals = finals_list;
    
    (* 5. Fast Delta: O(1) Lookup, NO Oracle calls *)
    delta = (fun q c -> List.assoc c transition_matrix.(q)); 
  }

(* Searches for a Counter-Example (CE) using BFS *)
let find_ce dfa oracle alphabet =
  let rec gen n = 
    if n = 0 then [""] 
    else let ws = gen (n-1) in List.concat_map (fun c -> List.map (fun w -> w ^ String.make 1 c) ws) alphabet 
  in
  (* Depth limit 10 is enough for small examples, increase for complex ones *)
  let rec loop i = 
    if i > 10 then None 
    else match List.find_opt (fun w -> Dfa.membership dfa (string_to_char_list w) <> oracle w) (gen i) with
      | Some w -> Some w | None -> loop (i+1)
  in loop 0

(* ========================================== *)
(* STRATEGY 0: ANGLUIN (The Classic)          *)
(* ========================================== *)

let run_angluin table ce =
  let rec prefixes i = 
    if i > String.length ce then [] 
    else String.sub ce 0 i :: prefixes (i+1) 
  in
  let new_rows = prefixes 0 in
  { table with s = List.sort_uniq compare (table.s @ new_rows) }

(* ========================================== *)
(* STRATEGY 1: RIVEST-SCHAPIRE (Robust)       *)
(* ========================================== *)

let run_rivest_schapire table dfa oracle ce =
  let len = String.length ce in
  let ce_chars = string_to_char_list ce in
  let target_val = oracle ce in 

  (* 1. Binary Search Logic *)
  let check_consistency i =
    let prefix_chars = List.init i (fun k -> List.nth ce_chars k) in
    let suffix_chars = List.filteri (fun k _ -> k >= i) ce_chars in
    let q = List.fold_left (fun s c -> dfa.Dfa.delta s c) dfa.Dfa.start prefix_chars in
    Dfa.membership { dfa with start = q } suffix_chars = target_val
  in

  let rec bin_search low high =
    if low + 1 >= high then String.sub ce high (len - high)
    else
      let mid = (low + high) / 2 in
      if check_consistency mid then bin_search mid high
      else bin_search low mid
  in
  
  let suffix = bin_search 0 len in
  
  (* 2. Collision Handling Logic *)
  if not (List.mem suffix table.e) then
      (* Happy Path: New suffix found! *)
      { table with e = table.e @ [suffix] }
  else
      (* COLLISION DETECTED: The suffix exists. *)
      (* Step A: Try Angluin strategy (Add Rows) *)
      let table_angluin = run_angluin table ce in
      
      (* Check if Angluin actually did something new *)
      if List.length table_angluin.s > List.length table.s then
        table_angluin
      else
        (* EMERGENCY BREAK: Angluin didn't add new rows (or rows didn't help). *)
        (* Force the Counter-Example itself as a new Column to split states. *)
        { table with e = List.sort_uniq String.compare (table.e @ [ce]) }

(* ========================================== *)
(* MAIN LEARNING LOOP                         *)
(* ========================================== *)

let learn algo alphabet oracle =
  
  let rec loop table steps =
    Printf.printf "Cycle: %d | Rows: %d | Cols: %d\n%!" (List.length steps) (List.length table.s) (List.length table.e);
    let current_html = ObservationTable.to_html table alphabet oracle in
    let new_steps = current_html :: steps in

    match ObservationTable.is_closed table alphabet oracle with
    | Some sa -> 
        loop { table with s = table.s @ [sa] } new_steps

    | None -> 
        match ObservationTable.is_consistent table alphabet oracle with
        | Some (s1, s2, a) ->
            let r1 = ObservationTable.get_row table oracle (s1 ^ String.make 1 a) in
            let r2 = ObservationTable.get_row table oracle (s2 ^ String.make 1 a) in
            let e_new = List.find_map (fun (suffix, (b1, b2)) -> 
              if b1 <> b2 then Some (String.make 1 a ^ suffix) else None) 
              (List.combine table.e (List.combine r1 r2)) |> Option.get in
            loop { table with e = table.e @ [e_new] } new_steps

        | None -> 
            let dfa = build_hypothesis table alphabet oracle in
            match find_ce dfa oracle alphabet with
            | None -> (dfa, List.rev new_steps)
            | Some ce -> 
                let updated_table = match algo with
                  | Angluin -> run_angluin table ce
                  | RivestSchapire -> run_rivest_schapire table dfa oracle ce
                in
                loop updated_table new_steps
  in
  loop ObservationTable.empty []