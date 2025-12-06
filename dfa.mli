module Dfa : sig

  module Alphabet : sig
    type t = char list
  end

  module Word : sig
    type t = char list
    val epsilon : t
  end

  type 'state t = {
      alpha : Alphabet.t;
      states : 'state list;
      start : 'state;
      finals : 'state list;
      delta : 'state -> char -> 'state;
  }

  (** DFA Intersection *)
  val inter : 's1 t -> 's2 t -> ('s1 * 's2) t

  (** DFA equivalence *)
  val equivalent : 's1 t -> 's2 t -> bool

end
