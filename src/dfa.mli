module Dfa : sig
  module Alphabet : sig
    type t = char list
  end
  module Word : sig
    type t = char list
    val epsilon : t
    val to_string : t -> string
    val of_string : string -> t
  end
  type 'state t = {
    alpha  : Alphabet.t;
    states : 'state list;
    start  : 'state;
    finals : 'state list;
    delta  : 'state -> char -> 'state;
  }
  val membership : 's t -> Word.t -> bool
  val inter : 's1 t -> 's2 t -> ('s1 * 's2) t
  val negate : 's t -> 's t
  val is_empty : 's t -> bool
  val equivalent : 's1 t -> 's2 t -> bool
end
