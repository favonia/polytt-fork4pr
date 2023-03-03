(** The values of the core language.
    This module repackages definitions in Data.ml for nicer qualified imports. *)

open Bwd
open Bwd.Infix

module S = Syntax

type labelset = string list
type label = string
type 'a labeled = (string * 'a) list

type t = Data.value =
  | Neu of t * neu
  | Pi of Ident.t * t * tm_clo
  | Lam of Ident.t * tm_clo
  | Sigma of Ident.t * t * tm_clo
  | Pair of t * t
  | Eq of t * t * t
  | Refl of t
  | Nat
  | Zero
  | Succ of t
  | FinSet of labelset
  | Label of labelset * label
  | Univ
  | Poly
  | PolyIntro of t * tm_clo
  | Hom of t * t
  | HomLam of Ident.t * Ident.t * hom_clo
  | FibLam of int * instr list

and tp = t

and neu = Data.neu = { hd : hd; spine : frame bwd }

and hd = Data.hd =
  | Var of int
  | Hole of tp * int
  | Skolem of tp

and frame = Data.frame =
  | Ap of { tp : t; arg : t }
  | Fst
  | Snd
  | NatElim of { mot : t; zero : t; succ : t }
  | Cases of { mot : t; cases : t labeled }
  | Base
  | Fib of { base : t; value : t }
  | HomElim of { base : t; value : t }

and env = t bwd
and 'a clo = 'a Data.clo = Clo of { env : env; body : 'a }
and tm_clo = Data.syn clo
and hom_clo = Data.hom_syn clo

and instr = Data.instr =
  | Const of { write_addr : int; value : t }
  | NegAp of { write_addr : int; read_addr : int; fn : t }

let push_frm {hd; spine} frm =
  {hd; spine = spine #< frm}

let var tp lvl =
  Data.Neu (tp, { hd = Var lvl; spine = Emp })

let hole tp n =
  Data.Neu (tp, { hd = Hole (tp, n); spine = Emp })

let skolem tp =
  Data.Neu (tp, { hd = Skolem tp; spine = Emp })

let pp_sep_list ?(sep = ", ") pp_elem fmt xs =
  Format.pp_print_list ~pp_sep:(fun fmt () -> Format.pp_print_string fmt sep) pp_elem fmt xs

let rec dump fmt =
  function
  | Neu (t, neu) -> Format.fprintf fmt "neu[%a %a]" dump t dump_neu neu
  | Pi (nm, a, b) -> Format.fprintf fmt "pi[%a %a %a]" Ident.pp nm dump a dump_clo b
  | Sigma (nm, a, b) -> Format.fprintf fmt "sigma[%a %a %a]" Ident.pp nm dump a dump_clo b
  | Pair (a, b) -> Format.fprintf fmt "pair[%a %a]" dump a dump b
  | Lam (nm, t) -> Format.fprintf fmt "lam[%a, %a]" Ident.pp nm dump_clo t
  | Eq (t, a, b) -> Format.fprintf fmt "eq[%a, %a, %a]" dump t dump a dump b
  | Refl (a) -> Format.fprintf fmt "refl[%a]" dump a
  | Nat -> Format.fprintf fmt "nat"
  | Zero -> Format.fprintf fmt "zero"
  | Succ n -> Format.fprintf fmt "succ[%a]" dump n
  | FinSet ls -> Format.fprintf fmt "finset[%a]" (pp_sep_list Format.pp_print_string) ls
  | Label (ls, l) -> Format.fprintf fmt "label[%a, %a]" (pp_sep_list Format.pp_print_string) ls Format.pp_print_string l
  | Univ -> Format.fprintf fmt "univ"
  | Poly ->
    Format.fprintf fmt "poly"
  | PolyIntro (base, fib) ->
    Format.fprintf fmt "poly-intro[%a, %a]"
      dump base
      dump_clo fib
  | Hom (p, q) ->
    Format.fprintf fmt "hom[%a, %a]"
      dump p
      dump q
  | HomLam (p_name, q_name, bdy) ->
    Format.fprintf fmt "hom-lam[%a, %a, %a]"
      Ident.pp p_name
      Ident.pp q_name
      dump_hom_clo bdy

and dump_neu fmt { hd = Var i; spine } =
  Format.fprintf fmt "D.var[%i %a]" i dump_spine spine

(* TODO *)
and dump_spine fmt spine = Format.fprintf fmt "$SPINE"

(* TODO *)
and dump_clo fmt (Clo { env; body }) = Format.fprintf fmt "$ENV %a" S.dump body
and dump_hom_clo fmt (Clo { env; body }) = Format.fprintf fmt "FIXME :)"
