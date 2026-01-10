(* ========================================== *)
(* TARGET ORACLES                             *)
(* ========================================== *)

let oracle_even_ones w =
  let count = ref 0 in
  String.iter (fun x -> if x = '1' then incr count) w;
  !count mod 2 = 0

let oracle_end_zero w =
  let len = String.length w in
  len > 0 && w.[len - 1] = '0'

let oracle_double_one w =
  let rec aux i =
    if i >= String.length w - 1 then false
    else if w.[i] = '1' && w.[i+1] = '1' then true
    else aux (i+1)
  in aux 0

let oracles = [
  ("even_ones", "Even number of 1s", oracle_even_ones);
  ("ends_zero", "Ends with 0", oracle_end_zero);
  ("double_one", "Double 1 (consecutive)", oracle_double_one);
]