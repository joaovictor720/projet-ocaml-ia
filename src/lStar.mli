(** LStar.mli
    Core implementation of the L* Active Learning Algorithm.
    This module orchestrates the interaction between the Observation Table,
    the Hypothesis DFA, and the Equivalence Oracle.
*)

open Dfa

(** Strategies for handling counter-examples (CE) found by the oracle. *)
type algorithm = 
  | Angluin        (** Classic approach: Adds all prefixes of the CE to S. *)
  | RivestSchapire (** Optimized approach: Uses binary search to find 1 distinguishing suffix. *)

val learn : algorithm -> char list -> (string -> bool) -> int -> int Dfa.t * string list