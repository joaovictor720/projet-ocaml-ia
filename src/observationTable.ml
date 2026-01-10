type t = { s : string list; e : string list }
let empty = { s = [""]; e = [""] }
let get_row table oracle row_word = List.map (fun suffix -> oracle (row_word ^ suffix)) table.e

let is_closed table alphabet oracle =
  let s_rows = List.map (get_row table oracle) table.s in
  let sa = List.concat_map (fun s -> List.map (fun a -> s ^ String.make 1 a) alphabet) table.s in
  List.find_opt (fun w_sa -> not (List.mem (get_row table oracle w_sa) s_rows)) sa

let is_consistent table alphabet oracle =
  let rec pairs = function [] -> [] | x::xs -> (List.map (fun y -> (x,y)) xs) @ pairs xs in
  List.find_map (fun (s1, s2) ->
    if get_row table oracle s1 = get_row table oracle s2 then
      List.find_map (fun a ->
        if get_row table oracle (s1 ^ String.make 1 a) <> get_row table oracle (s2 ^ String.make 1 a)
        then Some (s1, s2, a) else None) alphabet
    else None) (pairs table.s)
