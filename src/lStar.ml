open Dfa
open ObservationTable

(* ========================================== *)
(* TYPES & HELPERS                            *)
(* ========================================== *)

type algorithm =
  | Angluin
  | RivestSchapire

(** Converts a string to a char list for DFA processing. *)
let string_to_char_list s = List.of_seq (String.to_seq s)

(* ========================================== *)
(* DFA CONSTRUCTION (Hypothesis)              *)
(* ========================================== *)

(** Converts the closed and consistent Observation Table into a DFA.
    1. Unique rows in S become the States.
    2. Transitions are determined by looking up row(s + a).
    3. Final states are determined by the oracle output for the state representative.
*)
let build_hypothesis table alphabet oracle =
  (* 1. Compute rows for all prefixes in S *)
  let raw_s_rows =
    List.map (fun s -> (s, ObservationTable.get_row table oracle s)) table.s
  in
  
  (* 2. Identify unique row patterns (these become the DFA states) *)
  let rows = List.map snd raw_s_rows |> List.sort_uniq compare in
  let rows_arr = Array.of_list rows in (* Array for O(1) index lookup *)
  
  (* Helper to find state index given a row pattern *)
  let row_to_idx r =
    match List.find_index (( = ) r) rows with
    | Some i -> i
    | None -> failwith "Critical: Row not found during DFA construction"
  in

  (* 3. Determine representative string for each state (for debugging/oracle) *)
  let state_reps =
    Array.init (Array.length rows_arr) (fun i ->
        let r = rows_arr.(i) in
        fst (List.find (fun (_, r') -> r' = r) raw_s_rows))
  in

  (* 4. Build Transition Matrix: delta(q, a) *)
  let transition_matrix =
    Array.init (Array.length state_reps) (fun i ->
        let s = state_reps.(i) in
        List.map
          (fun c ->
            (* The next state is determined by the row of (s + c) *)
            let next_row = ObservationTable.get_row table oracle (s ^ String.make 1 c) in
            (c, row_to_idx next_row))
          alphabet)
  in

  (* 5. Identify Final States (where Oracle returns true) *)
  let finals =
    List.filter
      (fun i -> oracle state_reps.(i))
      (List.init (Array.length state_reps) Fun.id)
  in

  (* Construct the DFA record *)
  let dfa = {
    Dfa.alpha = alphabet;
    states = List.init (Array.length state_reps) Fun.id;
    start = row_to_idx (ObservationTable.get_row table oracle "");
    finals;
    delta = (fun q c -> List.assoc c transition_matrix.(q));
  } in
  
  (dfa, state_reps)

(* ========================================== *)
(* EQUIVALENCE ORACLE                         *)
(* ========================================== *)

(** Monte Carlo search for a counter-example.
    Tests random words to see if Hypothesis(w) != Oracle(w).
    Returns 'Some w' if a discrepancy is found, 'None' otherwise.
*)
let find_ce dfa oracle alphabet iteration max_checks =
  let num_tries = max_checks in
  let min_len = 1 in
  let max_len = 25 in
  
  (* Optimization: Use Array for O(1) random character access *)
  let alpha_arr = Array.of_list alphabet in
  let alpha_len = Array.length alpha_arr in
  
  (* Seed depends on iteration to ensure coverage variance *)
  let base_seed = 4242 + iteration * 97 in

  let random_char () = alpha_arr.(Random.int alpha_len) in
  let random_word len = String.init len (fun _ -> random_char ()) in

  let rec attempt i =
    if i > num_tries then None (* Hypothesis assumed correct *)
    else (
      Random.init (base_seed + i);
      let len = min_len + Random.int (max_len - min_len + 1) in
      let w = random_word len in
      
      if Dfa.membership dfa (string_to_char_list w) <> oracle w then (
        (* Log only when a genuine error is found *)
        Printf.printf "   [!] Counter-example found: '%s'\n%!" w;
        Some w
      )
      else attempt (i + 1))
  in
  attempt 0

(* ========================================== *)
(* UPDATE STRATEGIES                          *)
(* ========================================== *)

(** Angluin's Strategy:
    Adds ALL prefixes of the counter-example to the set S.
    Simple but can lead to very large tables.
*)
let run_angluin table ce =
  let rec prefixes i =
    if i > String.length ce then []
    else String.sub ce 0 i :: prefixes (i + 1)
  in
  let new_rows = prefixes 0 in
  (* Update S, keeping it unique and sorted *)
  { table with s = List.sort_uniq compare (table.s @ new_rows) }

(** Rivest-Schapire Strategy:
    Uses Binary Search to find a SINGLE suffix to add to E.
    Much more efficient for large automata.
*)
let run_rivest_schapire table dfa state_reps oracle ce =
  let len = String.length ce in
  let target_val = oracle ce in 

  (* Helper: simulate DFA on prefix to find current state *)
  let get_state_after_prefix len_prefix =
    let prefix = String.sub ce 0 len_prefix in
    let chars = string_to_char_list prefix in
    List.fold_left (fun q c -> dfa.Dfa.delta q c) dfa.Dfa.start chars
  in

  (* Helper: Checks if the property holds at index i *)
  let check_consistency i =
    let state_idx = get_state_after_prefix i in
    let state_str = state_reps.(state_idx) in 
    let suffix = String.sub ce i (len - i) in
    oracle (state_str ^ suffix) = target_val
  in

  (* Binary Search to find the breakpoint where consistency fails *)
  let rec bin_search low high =
    if low + 1 >= high then
      String.sub ce high (len - high) (* Found the distinguishing suffix *)
    else
      let mid = (low + high) / 2 in
      if check_consistency mid = check_consistency low then
        bin_search mid high
      else
        bin_search low mid
  in

  let suffix = bin_search 0 len in

  (* Add the new suffix to E if not already present *)
  if List.mem suffix table.e then table
  else { table with e = table.e @ [suffix] }

(* ========================================== *)
(* MAIN LEARNING LOOP                         *)
(* ========================================== *)

(** Main L* Algorithm Loop.
    1. Check Closedness -> Add row to S if needed.
    2. Check Consistency -> Add col to E if needed.
    3. Construct Hypothesis -> Check Equivalence -> Refine if needed.
*)
let learn algo alphabet oracle max_checks =
  let rec loop table steps iteration =
    Printf.printf "Iter %d | S=%d | E=%d\n%!"
      iteration (List.length table.s) (List.length table.e);

    (* Trace generation for HTML output *)
    let html = ObservationTable.to_html table alphabet oracle in
    let steps = html :: steps in

    (* Safety break to prevent infinite loops on impossible targets *)
    if iteration > 150 then
      let (dfa, _) = build_hypothesis table alphabet oracle in
      (dfa, List.rev steps)
    else
      (* Phase 1: Close the table *)
      match ObservationTable.is_closed table alphabet oracle with
      | Some sa ->
          loop { table with s = table.s @ [sa] } steps iteration
      | None -> (
          (* Phase 2: Make the table consistent *)
          match ObservationTable.is_consistent table alphabet oracle with
          | Some (s1, s2, a) ->
              (* Found inconsistency: s1~s2 but s1.a !~ s2.a *)
              (* Determine the new suffix to add to E *)
              let r1 = ObservationTable.get_row table oracle (s1 ^ String.make 1 a) in
              let r2 = ObservationTable.get_row table oracle (s2 ^ String.make 1 a) in
              let e_new =
                List.find_map
                  (fun (e, (b1, b2)) ->
                    if b1 <> b2 then Some (String.make 1 a ^ e)
                    else None)
                  (List.combine table.e (List.combine r1 r2))
                |> Option.get
              in
              loop { table with e = table.e @ [e_new] } steps iteration
          | None -> (
              (* Phase 3: Equivalence Query *)
              let (dfa, state_reps) = build_hypothesis table alphabet oracle in
              match find_ce dfa oracle alphabet iteration max_checks with
              | None -> (dfa, List.rev steps) (* Success! *)
              | Some ce ->
                  (* Refinement based on selected algorithm *)
                  let table =
                    match algo with
                    | Angluin -> run_angluin table ce
                    | RivestSchapire -> run_rivest_schapire table dfa state_reps oracle ce
                  in
                  loop table steps (iteration + 1)))
  in
  loop ObservationTable.empty [] 1