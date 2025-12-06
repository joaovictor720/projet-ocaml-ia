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
      alpha : Alphabet.t;
      states : 'state list;
      start : 'state;
      finals : 'state list;
      delta : 'state -> char -> 'state;
    }

  (** Emptiness check *)
  val is_empty : 's t -> bool

end
