type t = { s : string list; e : string list }
val empty : t
val get_row : t -> (string -> bool) -> string -> bool list
val is_closed : t -> char list -> (string -> bool) -> string option
val is_consistent : t -> char list -> (string -> bool) -> (string * string * char) option
