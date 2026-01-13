(* Type definition to match interface *)
type oracle_fn = string -> bool

(* ========================================== *)
(* AUTOMATED ORACLES                          *)
(* ========================================== *)

(* Target: Even number of 1s (Parity Check)
   Logic: Counts 1s. Returns true if count % 2 == 0.
   Complexity: 2 states.
   Refactored to be purely functional (no refs).
*)
let oracle_even_ones w =
  let count = 
    String.fold_left (fun acc c -> if c = '1' then acc + 1 else acc) 0 w 
  in
  count mod 2 = 0

(* Target: Ends with '0'
   Logic: Checks the last character.
   Complexity: 2 states.
*)
let oracle_end_zero w =
  let len = String.length w in
  len > 0 && w.[len - 1] = '0'

(* Target: Consecutive '1's ("11")
   Logic: Scans for the substring "11".
   Complexity: 3 states.
*)
let oracle_double_one w =
  let rec aux i =
    if i >= String.length w - 1 then false
    else if w.[i] = '1' && w.[i+1] = '1' then true
    else aux (i+1)
  in aux 0

(* Target: Binary number divisible by 5
   Logic: Horner's method for modular arithmetic.
   Formula: remainder = (2 * remainder + bit) mod 5
   Complexity: 5 states (minimal DFA).
*)
let oracle_div5 w =
  if w = "" then false (* Empty string is not a number, reject *)
  else
    let rec calc_mod remainder i =
      if i >= String.length w then remainder
      else
        let bit = if w.[i] = '1' then 1 else 0 in
        let new_remainder = ((remainder * 2) + bit) mod 5 in
        calc_mod new_remainder (i + 1)
    in
    calc_mod 0 0 = 0

(* Target: Binary number divisible by 25
   Logic: Same as div5 but mod 25.
   Complexity: 25 states.
   Note: Excellent for benchmarking Angluin vs. RS (RS is much faster here).
*)
let oracle_div25 w =
  if w = "" then false
  else
    let rec calc_mod remainder i =
      if i >= String.length w then remainder
      else
        let bit = if w.[i] = '1' then 1 else 0 in
        let new_remainder = ((remainder * 2) + bit) mod 25 in
        calc_mod new_remainder (i + 1)
    in
    calc_mod 0 0 = 0

(* Target: Binary number divisible by 7
   Complexity: 7 states.
*)
let oracle_div7 w =
  if w = "" then false
  else
    let rec calc_mod remainder i =
      if i >= String.length w then remainder
      else
        let bit = if w.[i] = '1' then 1 else 0 in
        let new_remainder = ((remainder * 2) + bit) mod 7 in
        calc_mod new_remainder (i + 1)
    in
    calc_mod 0 0 = 0

(* Target: The k-th bit from the end is 1
   Logic: w = u1v where |v| = k-1.
   Complexity: Requires 2^k states.
   bit_4 requires 2^4 = 16 states.
*)
let oracle_bit4 w =
  let k = 4 in
  let len = String.length w in
  if len < k then false
  else w.[len - k] = '1'

(* Target: The 6th bit from the end is 1
   Complexity: Requires 2^6 = 64 states.
   Note: Hard benchmark for memory and query count.
*)
let oracle_bit6 w =
  let k = 6 in
  let len = String.length w in
  if len < k then false
  else w.[len - k] = '1'

(* Target: Length >= 10
   Logic: Simple length check.
   Complexity: 11 states (linear structure).
*)
let oracle_len10 w =
  String.length w >= 10

(* Target: Ends with specific suffix "101101"
   Complexity: Depends on suffix overlaps (KMP style logic implied in DFA).
*)
let oracle_suffix_hard w =
  let pattern = "101101" in
  let n = String.length w in
  let k = String.length pattern in
  if n < k then false
  else String.sub w (n - k) k = pattern

(* Target: Contains substring "110"
   Logic: Search anywhere in the string.
*)
let oracle_contains_110 w =
  let rec check_substring str sub =
    let len_str = String.length str in
    let len_sub = String.length sub in
    if len_sub > len_str then false
    else if String.sub str 0 len_sub = sub then true
    else check_substring (String.sub str 1 (len_str - 1)) sub
  in
  check_substring w "110"

(* ========================================== *)
(* INTERACTIVE ORACLE                         *)
(* ========================================== *)

let oracle_human w =
  Printf.printf "\n[?] Oracle Query: Does the word '%s' belong to the language? (y/n): " w;
  flush stdout; 
  match read_line () with
  | "y" | "Y" | "yes" -> true
  | _ -> false

(* ========================================== *)
(* EXPORTED LIST                              *)
(* ========================================== *)

(* Only automated targets are included here for batch processing *)
let all = [
  ("even_ones",    "Even number of 1s",             oracle_even_ones);
  ("ends_zero",    "Ends with 0",                   oracle_end_zero);
  ("double_one",   "Double 1 (consecutive)",        oracle_double_one);
  ("div_by_5",     "Binary Divisible by 5",         oracle_div5);
  ("div_by_25",    "Binary Divisible by 25 (Hard)", oracle_div25);
  ("div_by_7",     "Binary Divisible by 7",         oracle_div7);
  ("bit_4",        "4th bit from end is 1",         oracle_bit4);
  ("bit_6",        "6th bit from end is 1 (Hard)",  oracle_bit6);
  ("len_10",       "Length >= 10",                  oracle_len10);
  ("suffix_hard",  "Ends with 101101",              oracle_suffix_hard);
  ("contains_110", "Contains pattern 110",          oracle_contains_110);
]