(** The values of the core language. 
    This module repackages definitions in Data.ml for nicer qualified imports. *)

open Bwd
open Bwd.Infix

type t = Data.value =
  | Neu of t * neu
  | Pi of Ident.t * t * clo
  | Lam of Ident.t * clo
  | Sigma of Ident.t * t * clo
  | Pair of t * t
  | Univ

and tp = t

and neu = Data.neu = { hd : hd; spine : frame bwd }        

and hd = Data.hd =
  | Var of int

and frame = Data.frame =
  | Ap of { tp : t; arg : t }
  | Fst
  | Snd

and env = t bwd
and clo = Data.clo = Clo of { env : env; body : Data.syn }

let push_frm {hd; spine} frm =
  {hd; spine = spine #< frm}

let var tp lvl =
  Data.Neu (tp, { hd = Var lvl; spine = Emp })
