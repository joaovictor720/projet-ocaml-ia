(** LStar.mli *)

open Dfa

(** Available optimization strategies *)
type algorithm = 
  | Angluin        (** Standard: Adds all prefixes of CE to Rows (S) *)
  | RivestSchapire (** Optimized: Binary Search to add 1 suffix to Cols (E) *)

(** Runs the learning algorithm using the specified strategy. *)
val learn : algorithm -> char list -> (string -> bool) -> int Dfa.t * string list