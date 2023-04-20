open Tactic

let formation ?(name = `Anon) base_tac fam_tac =
  Syn.rule @@ fun () ->
  let base = Chk.run base_tac D.Univ in
  let fam = Var.abstract ~name (eval base) @@ fun a ->
    Chk.run (fam_tac a) D.Univ
  in
  (D.Univ, S.Sigma(name, base, fam))

let intro tac_fst tac_snd =
  Chk.rule @@ function
  | D.Sigma (_, a, clo) ->
    let t1 = Chk.run tac_fst a in
    let t2 = Chk.run tac_snd (inst_clo clo (eval t1)) in
    S.Pair (t1, t2)
  | _ ->
    Error.error `TypeError "Expected element of Σ."

let fst tac =
  Syn.rule @@ fun () ->
  let tp, tm = Syn.run tac in
  match tp with
  | D.Sigma (_, a, _clo) ->
    a, S.Fst tm
  | _ ->
    Error.error `TypeError "Expected element of Σ."

let snd tac =
  Syn.rule @@ fun () ->
  let tp, tm = Syn.run tac in
  match tp with
  | D.Sigma (_, _a, clo) ->
    let fib = inst_clo clo (do_fst @@ eval tm) in
    fib, S.Snd tm
  | _ ->
    Error.error `TypeError "Expected element of Σ."
