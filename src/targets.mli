(** Targets.mli
    Defines the oracle functions (targets) for the L* learner.
    These functions act as the "Black Box" that the algorithm must decipher.
*)

(** Type alias for an oracle function: takes a word, returns true/false *)
type oracle_fn = string -> bool

(** List of automated learning scenarios.
    Each entry is a tuple: (file_tag, human_readable_name, oracle_function)
    - file_tag: used for filenames (e.g., "div_by_5")
    - name: used for display in logs
    - oracle_fn: the logic to test
*)
val all : (string * string * oracle_fn) list

(** The Interactive Human Oracle.
    Reads input from stdin (y/n) to determine membership.
    Useful for demonstrating the algorithm live.
*)
val oracle_human : oracle_fn