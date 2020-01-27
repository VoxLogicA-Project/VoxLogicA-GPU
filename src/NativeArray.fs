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

#nowarn "9"
namespace VoxLogicA

open Microsoft.FSharp.NativeInterop
open System.Runtime.InteropServices


type NativeArray<'T when 'T : unmanaged> = 
    val ptr : nativeptr<'T>
    val handle : GCHandle
    val length : int
    
    new (p : nativeptr<'T>, l: int, o: obj) = 
        {   ptr = p
            length = l
            handle = GCHandle.Alloc(o) }

    override this.Finalize() =
        this.handle.Free()

    member this.UGet n =  
        assert (this.InBounds n)              
        NativePtr.get this.ptr n
    
    member this.USet n v =
        assert (this.InBounds n)
        NativePtr.set this.ptr n v
    
    member this.InBounds n =
        n >= 0 && n < this.length

    member this.Get n =
        if this.InBounds n 
        then this.UGet n 
        else raise (System.IndexOutOfRangeException())

    member this.Set n v =
        if this.InBounds n 
        then this.USet n v 
        else raise (System.IndexOutOfRangeException())
    
    member this.Iter f =
        for i = 0 to this.length - 1 do
            f (this.UGet i)

    member this.Iteri f =
        for i = 0 to this.length - 1 do
            f i (this.UGet i)
    
    member this.Apply f =
        for i = 0 to this.length do
            this.USet i (f (this.UGet i))

    member this.Applyi f =
        for i = 0 to this.length - 1 do
            this.USet i (f i (this.UGet i))

    member this.Replace f =
        for i = 0 to this.length - 1 do
            this.USet i (f i)
    
    member this.Fill v =
        for i = 0 to this.length - 1 do
            this.USet i v
