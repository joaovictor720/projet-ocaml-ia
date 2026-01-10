open Dfa
open ObservationTable

(* Converts the observation table into a DFA Hypothesis *)
let build_hypothesis table alphabet oracle =
  let rows = List.map (ObservationTable.get_row table oracle) table.s |> List.sort_uniq compare in
  let row_to_idx r = List.find_index (fun x -> x = r) rows |> Option.get in
  
  { Dfa.alpha = alphabet; 
    states = List.init (List.length rows) (fun i -> i);
    start = row_to_idx (ObservationTable.get_row table oracle "");
    
    finals = List.filter_map (fun r -> 
               let s = List.find (fun s -> ObservationTable.get_row table oracle s = r) table.s in
               if oracle s then Some (row_to_idx r) else None) rows;
               
    delta = (fun q c -> 
      let r = List.nth rows q in
      let s = List.find (fun s -> ObservationTable.get_row table oracle s = r) table.s in
      row_to_idx (ObservationTable.get_row table oracle (s ^ String.make 1 c))); 
  }

(* Looks for a counterexample using BFS *)
let find_ce dfa oracle alphabet =
  let rec gen n = 
    if n = 0 then [""] 
    else 
      let ws = gen (n-1) in 
      List.concat_map (fun c -> List.map (fun w -> w ^ String.make 1 c) ws) alphabet 
  in
  let rec loop i = 
    if i > 6 then None (* Limits search depth to keep it fast *)
    else
      match List.find_opt (fun w -> Dfa.membership dfa (Dfa.Word.of_string w) <> oracle w) (gen i) with
      | Some w -> Some w 
      | None -> loop (i+1)
  in loop 0

(* Main L* Algorithm Loop *)
(* Returns: (Dfa.t * string list) -> The learned DFA and the HTML debug trace *)
let learn alphabet oracle =
  
  let rec loop table steps =
    (* 1. Capture current state as HTML *)
    let current_html = ObservationTable.to_html table alphabet oracle in
    let new_steps = current_html :: steps in

    (* 2. Check Closedness *)
    match ObservationTable.is_closed table alphabet oracle with
    | Some sa -> 
        (* Table is not closed: Add s.a to S *)
        loop { table with s = table.s @ [sa] } new_steps

    | None -> 
        (* 3. Check Consistency *)
        match ObservationTable.is_consistent table alphabet oracle with
        | Some (s1, s2, a) ->
            (* Table is not consistent: Find distinguishing suffix *)
            let r1 = ObservationTable.get_row table oracle (s1 ^ String.make 1 a) in
            let r2 = ObservationTable.get_row table oracle (s2 ^ String.make 1 a) in
            let e_new = List.find_map (fun (suffix, (b1, b2)) -> 
              if b1 <> b2 then Some (String.make 1 a ^ suffix) else None) 
              (List.combine table.e (List.combine r1 r2)) |> Option.get in
            
            loop { table with e = table.e @ [e_new] } new_steps

        | None -> 
            (* 4. Conjecture Hypothesis *)
            let dfa = build_hypothesis table alphabet oracle in
            
            (* 5. Verify Hypothesis (Equivalence Query) *)
            match find_ce dfa oracle alphabet with
            | None -> 
                (* Success! Return DFA and reversed logs *)
                (dfa, List.rev new_steps)
                
            | Some ce -> 
                (* Counterexample found: Process prefixes and restart loop *)
                let rec pref s = 
                  if s = "" then [""] 
                  else s :: pref (String.sub s 0 (String.length s - 1)) 
                in
                (* Add all prefixes of CE to S *)
                loop { table with s = List.sort_uniq compare (table.s @ pref ce) } new_steps
  in
  
  loop ObservationTable.empty []