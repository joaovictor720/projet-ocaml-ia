(** Targets.mli
    Defines the oracle functions (targets) for the L* learner.
*)

(** Type alias for an oracle function: string -> bool *)
type oracle_fn = string -> bool

(** List of automated learning scenarios.
    Each entry is a tuple: (file_tag, human_readable_name, oracle_function)
*)
val all : (string * string * oracle_fn) list

(** The Interactive Human Oracle.
    Reads input from stdin (y/n) to determine membership.
*)
val oracle_human : oracle_fn