open Dfa
open ObservationTable

(* ========================================== *)
(* TYPES                                      *)
(* ========================================== *)

type algorithm =
  | Angluin
  | RivestSchapire

(* HELPER: Crucial para o funcionamento do código *)
let string_to_char_list s = List.of_seq (String.to_seq s)

(* ========================================== *)
(* DFA CONSTRUCTION                           *)
(* ========================================== *)

(* Retorna (DFA, Array de Representantes de Estado) *)
let build_hypothesis table alphabet oracle =
  let raw_s_rows =
    List.map (fun s -> (s, ObservationTable.get_row table oracle s)) table.s
  in
  let rows = List.map snd raw_s_rows |> List.sort_uniq compare in

  let row_to_idx r =
    match List.find_index (( = ) r) rows with
    | Some i -> i
    | None -> failwith "Row not found"
  in

  let state_reps =
    Array.init (List.length rows) (fun i ->
        let r = List.nth rows i in
        fst (List.find (fun (_, r') -> r' = r) raw_s_rows))
  in

  let transition_matrix =
    Array.init (Array.length state_reps) (fun i ->
        let s = state_reps.(i) in
        List.map
          (fun c ->
            let next =
              ObservationTable.get_row table oracle (s ^ String.make 1 c)
            in
            (c, row_to_idx next))
          alphabet)
  in

  let finals =
    List.filter
      (fun i -> oracle state_reps.(i))
      (List.init (Array.length state_reps) Fun.id)
  in

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

let find_ce dfa oracle alphabet iteration =
  let num_tries = 3000 in
  let min_len = 1 in
  let max_len = 25 in

  let base_seed = 4242 + iteration * 97 in

  let random_char () =
    List.nth alphabet (Random.int (List.length alphabet))
  in

  let random_word len =
    String.init len (fun _ -> random_char ())
  in

  let rec attempt i =
    if i > num_tries then None
    else (
      Random.init (base_seed + i);
      let len = min_len + Random.int (max_len - min_len + 1) in
      let w = random_word len in
      if
        Dfa.membership dfa (string_to_char_list w)
        <> oracle w
      then Some w
      else attempt (i + 1))
  in
  attempt 0

(* ========================================== *)
(* ANGLUIN UPDATE                             *)
(* ========================================== *)

let run_angluin table ce =
  let rec prefixes i =
    if i > String.length ce then []
    else String.sub ce 0 i :: prefixes (i + 1)
  in
  let new_rows = prefixes 0 in
  { table with s = List.sort_uniq compare (table.s @ new_rows) }

(* ========================================== *)
(* RIVEST–SCHAPIRE (LOGICA CORRETA)           *)
(* ========================================== *)

let run_rivest_schapire table dfa state_reps oracle ce =
  let len = String.length ce in
  let target_val = oracle ce in 

  (* Roda o prefixo no DFA para descobrir em qual estado paramos *)
  let get_state_after_prefix len_prefix =
    let prefix = String.sub ce 0 len_prefix in
    let chars = string_to_char_list prefix in
    List.fold_left (fun q c -> dfa.Dfa.delta q c) dfa.Dfa.start chars
  in

  (* Verifica consistência: 
     O representante do estado atual + sufixo dá o mesmo resultado que o target? *)
  let check_consistency i =
    let state_idx = get_state_after_prefix i in
    let state_str = state_reps.(state_idx) in 
    let suffix = String.sub ce i (len - i) in
    oracle (state_str ^ suffix) = target_val
  in

  let rec bin_search low high =
    if low + 1 >= high then
      String.sub ce high (len - high)
    else
      let mid = (low + high) / 2 in
      (* Se o ponto médio concorda com o início, o erro está depois *)
      if check_consistency mid = check_consistency low then
        bin_search mid high
      else
        bin_search low mid
  in

  let suffix = bin_search 0 len in

  if List.mem suffix table.e then table
  else { table with e = table.e @ [suffix] }

(* ========================================== *)
(* MAIN LEARNING LOOP                         *)
(* ========================================== *)

let learn algo alphabet oracle =
  let rec loop table steps iteration =
    Printf.printf "Iter %d | S=%d | E=%d\n%!"
      iteration (List.length table.s) (List.length table.e);

    let html = ObservationTable.to_html table alphabet oracle in
    let steps = html :: steps in

    if iteration > 150 then
      let (dfa, _) = build_hypothesis table alphabet oracle in
      (dfa, List.rev steps)
    else
      match ObservationTable.is_closed table alphabet oracle with
      | Some sa ->
          loop { table with s = table.s @ [sa] } steps iteration
      | None -> (
          match ObservationTable.is_consistent table alphabet oracle with
          | Some (s1, s2, a) ->
              let r1 =
                ObservationTable.get_row table oracle
                  (s1 ^ String.make 1 a)
              in
              let r2 =
                ObservationTable.get_row table oracle
                  (s2 ^ String.make 1 a)
              in
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
              (* Recupera DFA e Representantes *)
              let (dfa, state_reps) = build_hypothesis table alphabet oracle in
              match find_ce dfa oracle alphabet iteration with
              | None -> (dfa, List.rev steps)
              | Some ce ->
                  let table =
                    match algo with
                    | Angluin -> run_angluin table ce
                    (* Passa argumentos extras para o RS *)
                    | RivestSchapire -> run_rivest_schapire table dfa state_reps oracle ce
                  in
                  loop table steps (iteration + 1)))
  in
  loop ObservationTable.empty [] 1