(** ObservationTable.mli *)

type t = { s : string list; e : string list }

(** Returns an empty observation table *)
val empty : t

(** Computes the row of boolean values for a given prefix *)
val get_row : t -> (string -> bool) -> string -> bool list

(** Checks if the table is closed. Returns Some (s.a) if not closed, None otherwise *)
val is_closed : t -> char list -> (string -> bool) -> string option

(** Checks if the table is consistent. Returns Some (s1, s2, a) if inconsistent *)
val is_consistent : t -> char list -> (string -> bool) -> (string * string * char) option

(** Exports the current table state to an HTML string for visualization.
    Requires alphabet and oracle to compute the cells. *)
val to_html : t -> char list -> (string -> bool) -> string