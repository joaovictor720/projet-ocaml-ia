open Dfa
open ObservationTable

let build_hypothesis table alphabet oracle =
  let rows = List.map (get_row table oracle) table.s |> List.sort_uniq compare in
  let row_to_idx r = List.find_index (fun x -> x = r) rows |> Option.get in
  { Dfa.alpha = alphabet; states = List.init (List.length rows) (fun i -> i);
    start = row_to_idx (get_row table oracle "");
    finals = List.filter_map (fun r -> 
               let s = List.find (fun s -> get_row table oracle s = r) table.s in
               if oracle s then Some (row_to_idx r) else None) rows;
    delta = (fun q c -> let r = List.nth rows q in
      let s = List.find (fun s -> get_row table oracle s = r) table.s in
      row_to_idx (get_row table oracle (s ^ String.make 1 c))); }

let find_ce dfa oracle alphabet =
  let rec gen n = if n = 0 then [""] else 
    let ws = gen (n-1) in List.concat_map (fun c -> List.map (fun w -> w ^ String.make 1 c) ws) alphabet in
  let rec loop i = if i > 6 then None else
    match List.find_opt (fun w -> Dfa.membership dfa (Dfa.Word.of_string w) <> oracle w) (gen i) with
    | Some w -> Some w | None -> loop (i+1)
  in loop 0

let rec learn alphabet oracle =
  let rec loop table =
    match is_closed table alphabet oracle with
    | Some sa -> loop { table with s = table.s @ [sa] }
    | None -> match is_consistent table alphabet oracle with
      | Some (s1, s2, a) ->
          let r1 = get_row table oracle (s1 ^ String.make 1 a) in
          let r2 = get_row table oracle (s2 ^ String.make 1 a) in
          let e_new = List.find_map (fun (suffix, (b1, b2)) -> 
            if b1 <> b2 then Some (String.make 1 a ^ suffix) else None) 
            (List.combine table.e (List.combine r1 r2)) |> Option.get in
          loop { table with e = table.e @ [e_new] }
      | None -> let dfa = build_hypothesis table alphabet oracle in
          match find_ce dfa oracle alphabet with
          | None -> (dfa, table)
          | Some ce -> let rec pref s = if s = "" then [""] else s :: pref (String.sub s 0 (String.length s - 1)) in
              loop { table with s = List.sort_uniq compare (table.s @ pref ce) }
  in loop ObservationTable.empty
