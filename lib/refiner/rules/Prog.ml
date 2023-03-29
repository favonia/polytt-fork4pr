open Core
open Tactic

let neg_lam ?(name = `Anon) (tp_tac : Chk.tac) (bdy_tac : Var.tac -> Prog.tac) : NegSyn.tac =
  NegSyn.rule @@ fun () ->
  let tp = eval (Chk.run tp_tac D.Univ) in
  NegVar.abstract tp @@ fun neg_var ->
  Var.concrete ~name tp (NegVar.borrow neg_var) @@ fun var ->
  Debug.print "hacky consuming %a = %a@." Ident.pp name D.dump (NegVar.borrow neg_var);
  let setter = NegVar.set neg_var in
  Prog.run (bdy_tac var) ();
  tp, fun actual_value ->
  Debug.print "hacky neg_lam setting %a = %a@." Ident.pp name D.dump actual_value;
  setter actual_value

let pos_let ?(name = `Anon) (tm : Syn.tac) (f : Var.tac -> Prog.tac) =
  Prog.rule @@ fun () ->
  let tp, tm = Syn.run tm in
  let v = Eff.eval tm in
  Var.concrete ~name tp v @@ fun v ->
  Prog.run (f v) ()

let neg_let ?(name = `Anon) (tm : NegSyn.tac) (f : NegVar.tac -> Prog.tac) =
  Prog.rule @@ fun () ->
  let tp, tm = NegSyn.run tm in
  NegVar.abstract ~name tp @@ fun v ->
  tm (NegVar.borrow v);
  Prog.run (f v) ()

let set (pos_tac : Syn.tac) (neg_tac : NegChk.tac) (steps_tac : Prog.tac) : Prog.tac =
  Prog.rule @@ fun q ->
  let pos_tp, pos = Syn.run pos_tac in
  let neg = NegChk.run neg_tac pos_tp in
  neg (eval pos);
  Prog.run steps_tac q

let ap (pos_tac : Chk.tac) (neg_tac : NegChk.tac)
    (phi_tac : Syn.tac)
    ?(pos_name = `Anon) ?(neg_name = `Anon)
    (steps_tac : Var.tac -> NegVar.tac -> Prog.tac) =
  Prog.rule @@ fun r ->
  let phi_tp, phi = Syn.run phi_tac in
  match phi_tp with
  | D.Hom (p, q) ->
    let pos = Chk.run pos_tac (do_base p) in
    let vpos = eval pos in
    let neg = NegChk.run neg_tac (do_fib p vpos) in
    let phi_v = do_hom_elim (eval phi) vpos in
    let phi_base = do_fst phi_v in
    let phi_fib = do_snd phi_v in
    Var.concrete ~name:pos_name (do_base q) phi_base @@ fun pos_var ->
    NegVar.abstract ~name:neg_name (do_fib q (Var.value pos_var)) @@ fun neg_var ->
    neg (do_ap phi_fib (NegVar.borrow neg_var));
    Prog.run (steps_tac pos_var neg_var) r
  | _ ->
    Error.error `TypeError "Must ap a hom to a hom!"

(* end is also a reserved keyword :) *)
let end_ : Prog.tac =
  Prog.rule @@ fun () -> ()
