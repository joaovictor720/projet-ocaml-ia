(** Dfa.mli
    Defines the structure of a Deterministic Finite Automaton (DFA) 
    and core operations for equivalence testing.
*)

module Alphabet : sig
  (** The set of symbols allowed in the language *)
  type t = char list
end

module Word : sig
  type t = char list
  (** The empty word (epsilon) *)
  val epsilon : t
  (** Helper to convert character list to string *)
  val to_string : t -> string
  (** Helper to convert string to character list *)
  val of_string : string -> t
end

(** The generic DFA type. *)
type 'state t = {
  alpha  : Alphabet.t;
  states : 'state list;
  start  : 'state;
  finals : 'state list;
  delta  : 'state -> char -> 'state;
}

(** Checks if a word is accepted by the DFA. *)
val membership : 's t -> Word.t -> bool

(** Constructs the intersection of two DFAs (Product Construction).
    L(result) = L(dfa1) INTERSECT L(dfa2) *)
val inter : 's1 t -> 's2 t -> ('s1 * 's2) t

(** Constructs the complement DFA.
    L(result) = Sigma* - L(dfa) *)
val negate : 's t -> 's t

(** Checks if the language recognized by the DFA is empty.
    Uses Breadth-First Search (BFS) to find if any final state is reachable. *)
val is_empty : 's t -> bool

(** Checks if two DFAs recognize exactly the same language.
    Logic: (L1 subset L2) AND (L2 subset L1)
    Implemented as: Empty(L1 inter L2') AND Empty(L1' inter L2) *)
val equivalent : 's1 t -> 's2 t -> bool