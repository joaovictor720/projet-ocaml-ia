(** LStar.mli *)

open Dfa

(** Runs the L* algorithm.

    Arguments:
    - Alphabet: A list of characters representing the valid symbols.
    - Oracle: A function that returns true if a string belongs to the target language.

    Returns:
    - The learned DFA (with integer states).
    - A list of HTML strings representing the evolution of the observation table.
*)
val learn : char list -> (string -> bool) -> int Dfa.t * string list