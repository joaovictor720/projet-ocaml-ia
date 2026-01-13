(** ObservationTable.mli
    Defines the data structure for the Angluin/L* observation table
    and the core properties (closedness, consistency).
*)

(** The observation table structure.
    - s: List of prefixes (Rows) representing states.
    - e: List of suffixes (Columns) used to distinguish states.
*)
type t = { 
  s : string list; 
  e : string list 
}

(** Returns an initial empty observation table containing only epsilon. *)
val empty : t

(** Computes the row of boolean values for a given prefix.
    Signature: table -> oracle -> word -> row (bool list) *)
val get_row : t -> (string -> bool) -> string -> bool list

(** Checks if the table is closed.
    A table is closed if for every t in (S . A), there exists an s in S 
    such that row(t) = row(s).
    Returns: Some (t) if not closed (where t is the missing row), None otherwise. *)
val is_closed : t -> char list -> (string -> bool) -> string option

(** Checks if the table is consistent.
    A table is consistent if for all s1, s2 in S:
    row(s1) = row(s2) implies row(s1 . a) = row(s2 . a) for all a in A.
    Returns: Some (s1, s2, a) if inconsistent, None otherwise. *)
val is_consistent : t -> char list -> (string -> bool) -> (string * string * char) option

(** Exports the current table state to an HTML string for visualization.
    Useful for debugging and generating the step-by-step trace. *)
val to_html : t -> char list -> (string -> bool) -> string