// Copyright 2018 Vincenzo Ciancia.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
//
// A copy of the license is available in the file "Apache_License.txt".
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

namespace VoxLogicA

open Hopac  

exception RefCountException of r : int
    with override this.Message = sprintf "Value referenced, with reference count already %d, which is less than 0. This should never happen, please report it as a bug." this.r

type RefCount() =
    let refcount = ref 0
    interface System.IDisposable with
        member this.Dispose() =
            ErrorMsg.Logger.Debug <| sprintf "Stub: Called Dispose of %A : RefCount with reference count %d" this !refcount
    
    member this.Delete() = 
        ErrorMsg.Logger.Debug <| sprintf "Stub: Called Delete on object %A." this
    abstract member Reference : unit -> unit
    default this.Reference () =
        lock refcount (fun () -> 
            ErrorMsg.Logger.Debug <| sprintf "reference value %d->%d %A" !refcount (!refcount+1) (this.GetHashCode())
            if !refcount >= 0 then refcount := !refcount + 1
            else raise <| RefCountException !refcount)
    abstract member Dereference : unit -> unit
    default this.Dereference() =         
        lock refcount (fun () ->
            ErrorMsg.Logger.Debug <| sprintf"dereference value %d->%d %A" !refcount (!refcount-1) (this.GetHashCode())
            refcount := !refcount - 1
            if !refcount = 0 then 
                this.Delete())

// type ComputationHandle() = 
//     inherit RefCount()

//     let mutable computation = None

//     let iv = new IVar<obj>()

//     member __.SetComputation (c : #RefCount()) = computation <- Some c

//     override __.Reference() = match computation with Some c -> c.Reference() | None -> ()
//     override __.Dereference() = match computation with Some c -> c.Dereference() | None -> ()

//     member __.Write(x) = IVar.fill iv x 
//     member __.Read() = IVar.read iv
//     member __.Fail(exn) = IVar.FillFailure (iv,exn)

type ModelChecker(model : IModel) =
    let operatorFactory = OperatorFactory(model)
    let formulaFactory = FormulaFactory()       
    let cache = System.Collections.Generic.Dictionary<int,IVar<_>>()            
    let mutable alreadyChecked = 0
    let startChecker i = 
        job {   let iv = new IVar<_>()
                let f = formulaFactory.[i]
                let op = f.Operator                
                do! Job.queue <|
                        Job.tryWith                                                  
                            (job {  // cache.[f'.Uid] below never fails !
                                    // because formula uids give a topological sort of the dependency graph
                                    let computations = (Array.map (fun (f' : Formula) -> cache.[f'.Uid]) f.Arguments)
                                    let! arguments = Job.seqCollect (Array.map IVar.read computations)  
                                    for (arg : obj) in Seq.distinct arguments do 
                                        try (arg :?> RefCount).Reference()
                                        with :? System.InvalidCastException -> ()
                                    ErrorMsg.Logger.Debug (sprintf "About to execute: %s (id: %d)" f.Operator.Name f.Uid)
                                    ErrorMsg.Logger.Debug (sprintf "Arguments: %A" arguments)
                                    let! x = op.Eval (Array.ofSeq arguments)     
                                    for arg in Seq.distinct arguments do 
                                        try (arg :?> RefCount).Dereference()
                                        with :? System.InvalidCastException -> ()                                            
                                    ErrorMsg.Logger.Debug (sprintf "Finished: %s (id: %d)" f.Operator.Name f.Uid)
                                    ErrorMsg.Logger.Debug (sprintf "Result: %A" <| x)  
                                    do! IVar.fill iv x } )
                            (fun exn -> ErrorMsg.Logger.DebugOnly (exn.ToString()); IVar.fillFailure iv exn)
                cache.[i] <- iv }
                    
    member __.OperatorFactory = operatorFactory    
    member __.FormulaFactory = formulaFactory
    member __.Check =
        // this method must be called before Get(f) for f added after the previous invocation of Check()
        // corollary: this method must be called at least once before any invocation of Get        
        // It is important that the ordering of formulas is a topological sort of the dependency graph
        // this method should not be invoked concurrently from different threads or concurrently with get
        ErrorMsg.Logger.Debug (sprintf "Running %d tasks" (formulaFactory.Count - alreadyChecked))
        job {   for i = alreadyChecked to formulaFactory.Count - 1 do   
                    // ErrorMsg.Logger.DebugOnly (sprintf "Starting task %d" i)
                    do! startChecker i
                alreadyChecked <- formulaFactory.Count                  }
    member __.Get (f : Formula) =   
        job {      
            let! res = IVar.read cache.[f.Uid]  
            try (res :?> RefCount).Reference()        
            with :? System.InvalidCastException -> ()
            return res
        }
        


