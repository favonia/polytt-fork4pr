open Core

type empty = |

module Param =
struct
  type data = Global.t
  type tag = unit
  type hook = empty
  type context = empty
end
module Modifier = Yuujinchou.Modifier.Make(Param)
module Scope = Yuujinchou.Scope.Make(Param)(Modifier)


let define name defn =
  match name with
  | `User path ->
    Scope.include_singleton (path, (defn, ()))
  | _ ->
    ()

let run k =
  Scope.run @@ fun () ->
  let resolve path =
    Scope.resolve path
    |> Option.map fst
  in
  Refiner.Eff.Globals.run ~resolve @@ fun () ->
  Refiner.Eff.Hole.run k
