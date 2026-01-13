type t = { s : string list; e : string list }

(* Initializes S and E with epsilon (empty string) *)
let empty = { s = [""]; e = [""] }

(* Helper: Computes the row vector for a specific word (prefix)
   by testing it against all suffixes in E using the oracle. *)
let get_row table oracle row_word = 
  List.map (fun suffix -> oracle (row_word ^ suffix)) table.e

(* Check Closedness:
   Ensure that for every s in S and a in A, the row for (s^a) exists somewhere in S. *)
let is_closed table alphabet oracle =
  (* Pre-compute all rows currently in S to avoid re-querying *)
  let s_rows = List.map (get_row table oracle) table.s in
  
  (* Generate all extensions S . A *)
  let sa = List.concat_map (fun s -> List.map (fun a -> s ^ String.make 1 a) alphabet) table.s in
  
  (* Find the first word in S.A whose row is NOT present in s_rows *)
  List.find_opt (fun w_sa -> not (List.mem (get_row table oracle w_sa) s_rows)) sa

(* Check Consistency:
   Ensure that if two rows in S are identical, they must remain identical
   when appended with any character 'a' from the alphabet. *)
let is_consistent table alphabet oracle =
  (* Helper to generate all unique pairs (s1, s2) from list S *)
  let rec pairs = function 
    | [] -> [] 
    | x::xs -> (List.map (fun y -> (x,y)) xs) @ pairs xs 
  in
  
  (* Search for an inconsistency *)
  List.find_map (fun (s1, s2) ->
    (* Only check if rows are currently identical *)
    if get_row table oracle s1 = get_row table oracle s2 then
      (* Check extensions for all characters 'a' *)
      List.find_map (fun a ->
        let r1_next = get_row table oracle (s1 ^ String.make 1 a) in
        let r2_next = get_row table oracle (s2 ^ String.make 1 a) in
        if r1_next <> r2_next then Some (s1, s2, a) (* Inconsistency found! *)
        else None) alphabet
    else None) (pairs table.s)

(* ========================================== *)
(* HTML VISUALIZATION                         *)
(* ========================================== *)

let to_html table alphabet oracle =
  (* Use Buffer for efficient string construction (O(1) append) *)
  let b = Buffer.create 1024 in
  
  (* Inline CSS for clean visualization *)
  Buffer.add_string b "<table border='1' style='border-collapse: collapse; text-align: center; font-family: monospace; margin-bottom: 20px;'>\n";
  
  (* 1. Header Row (Suffixes E) *)
  Buffer.add_string b "  <tr style='background-color: #f0f0f0;'>\n";
  Buffer.add_string b "    <th style='padding: 8px;'>T</th>\n"; (* Top-left corner cell *)
  List.iter (fun e -> 
    let label = if e = "" then "&epsilon;" else e in
    Printf.bprintf b "    <th style='padding: 8px;'>%s</th>\n" label
  ) table.e;
  Buffer.add_string b "  </tr>\n";

  (* Helper to render a single row (used for both S and S.A) *)
  let render_row word is_upper =
    let bg_color = if is_upper then "#ffffff" else "#fafafa" in
    Printf.bprintf b "  <tr style='background-color: %s;'>\n" bg_color;
    
    (* Row Label (Prefix) *)
    let label = if word = "" then "&epsilon;" else word in
    let font_weight = if is_upper then "bold" else "normal" in
    Printf.bprintf b "    <td style='padding: 5px; font-weight: %s;'>%s</td>\n" font_weight label;
    
    (* Cells (0 or 1) *)
    let results = get_row table oracle word in
    List.iter (fun res ->
      let color = if res then "green" else "red" in
      let text = if res then "1" else "0" in
      Printf.bprintf b "    <td style='padding: 5px; color: %s;'>%s</td>\n" color text
    ) results;
    Buffer.add_string b "  </tr>\n"
  in

  (* 2. Upper Part (S) - The core states *)
  List.iter (fun s -> render_row s true) table.s;

  (* Separator Line between S and S.A *)
  Printf.bprintf b "  <tr style='background-color: #000; height: 2px;'><td colspan='%d'></td></tr>\n" (List.length table.e + 1);

  (* 3. Lower Part (S . A) - The transitions *)
  (* Filter out words that are already in S to avoid duplicates in display *)
  let sa = List.concat_map (fun s -> List.map (fun a -> s ^ String.make 1 a) alphabet) table.s in
  let sa_unique = List.sort_uniq String.compare sa in
  let sa_filtered = List.filter (fun w -> not (List.mem w table.s)) sa_unique in
  
  List.iter (fun s -> render_row s false) sa_filtered;

  Buffer.add_string b "</table>\n";
  Buffer.contents b