(*
 * Copyright (c) 2010 Anil Madhavapeddy <anil@recoil.org>
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

exception Parse_error of string * string

let need_more x = Parse_error ("not enough data", x)

type t = string (* length 6 only *)

let compare = String.compare

(* Raw MAC address off the wire (network endian) *)
let of_bytes_exn x =
  if String.length x <> 6
  then raise (Parse_error ("MAC is exactly 6 bytes", x))
  else x

let of_bytes x = try Some (of_bytes_exn x) with _ -> None

(* Read a MAC address colon-separated string *)
let of_string_exn x =
  let s = String.create 6 in
  try Scanf.sscanf x "%1x%1x:%1x%1x:%1x%1x:%1x%1x:%1x%1x:%1x%1x%!"
        (fun a b c d e f g h i j k l ->
          s.[0] <- Char.chr ((a lsl 4) + b);
          s.[1] <- Char.chr ((c lsl 4) + d);
          s.[2] <- Char.chr ((e lsl 4) + f);
          s.[3] <- Char.chr ((g lsl 4) + h);
          s.[4] <- Char.chr ((i lsl 4) + j);
          s.[5] <- Char.chr ((k lsl 4) + l);
          s
        )
  with
  | Scanf.Scan_failure msg -> raise (Parse_error (msg, x))
  | End_of_file -> raise (need_more x)

let of_string x = try Some (of_string_exn x) with _ -> None

let to_string x =
    let chri i = Char.code x.[i] in
    Printf.sprintf "%02x:%02x:%02x:%02x:%02x:%02x"
       (chri 0) (chri 1) (chri 2) (chri 3) (chri 4) (chri 5)

let to_bytes x = x

let broadcast = String.make 6 '\255'

let make_local () =
  let x = String.create 6 in
  let i () = Char.chr (Random.int 256) in
  (* set locally administered and unicast bits *)
  x.[0] <- Char.chr ((((Random.int 256) lor 2) lsr 1) lsl 1);
  x.[1] <- i ();
  x.[2] <- i ();
  x.[3] <- i ();
  x.[4] <- i ();
  x.[5] <- i ();
  x