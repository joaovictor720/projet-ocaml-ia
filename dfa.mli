module Dfa : sig

  module Alphabet : sig
    type t = char list
  end

  module Word : sig
    type t = char list
    val epsilon : t
  end

  (** Deterministic Finite Automaton *)
  type 'state t = {
      alpha : Alphabet.t;  (*alphabet*)
      states : 'state list;  (*ensemble des etats*)
      start : 'state;   (*etat init*)
      finals : 'state list;  (*etats finaux*)
      delta : 'state -> char -> 'state;  (*fonction de transition*)
    }

  (** Membership check *)
  val membership : 's t -> Word.t -> bool

 (**) (** DFA Intersection *)
  val inter : 's1 t -> 's2 t -> ('s1 * 's2) t

  (** DFA Negation *)
  val negate : 's t -> 's t

  (** Emptiness check *)
  val is_empty : 's t -> bool

  (** DFA equivalence  *)
  val equivalent : 's1 t -> 's2 t -> bool
end
