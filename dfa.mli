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
    alpha  : Alphabet.t;
    states : 'state list;
    start  : 'state;
    finals : 'state list;
    delta  : 'state -> char -> 'state;
  }

  (** Membership check *)
  val membership : 's t -> Word.t -> bool

  (** DFA Intersection *)
  val inter : 's1 t -> 's2 t -> ('s1 * 's2) t

  (** DFA Negation / Complement *)
  val negate : 's t -> 's t

  (** Emptiness check *)
  val is_empty : 's t -> bool

  (** DFA Equivalence *)
  val equivalent : 's1 t -> 's2 t -> bool

end
