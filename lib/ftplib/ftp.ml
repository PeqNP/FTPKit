
(* Ftp module             *)
(* bindings to C library  *)

(* NOTES:

  - low level file transfer functions are not available so far

  - this is a crude translation of the C API.  A better API should use
    OCaml features such as exceptions...
*)

(* setting of global parameters *)

external set_verbose : bool -> unit = "caml_setverbose"
external set_safeput : bool -> unit = "caml_setsafeput"

(* The default values are what you want. Believe me. *)
external set_passive : bool -> unit = "caml_setpassive"
external set_sendport : bool -> unit = "caml_setsendport"

(* get version string *)

external version : unit -> string = "caml_version"

(* generic ls
              long ls? file/rdir  file list  *)

external gls : bool -> string -> string list = "caml_ftp_ls"

let ls = gls true			(* long ls *)
let nlist = gls false			(* name list *)


external send_cmd : string -> string = "caml_ftp_sendcommand"


(* all these functions only perform side-effects
   they return true on success, false on failure *)

                (* site      login     passwd *)
external connect : string -> string -> string -> bool = "caml_ftp_open"

external close : unit   -> bool = "caml_ftp_close"

external cd    : string -> bool = "caml_ftp_cd"
external mkdir : string -> bool = "caml_ftp_mkdir"
external rmdir : string -> bool = "caml_ftp_rmdir"

external delete : string -> bool = "caml_ftp_delete"

               (* oldname   newname *)
external rename : string -> string -> bool = "caml_ftp_rename"

              (*  rst   append   local     remote  *)
external gput   : int -> bool -> string -> string -> bool = "caml_ftp_put"

let put = gput 0 false


external put_unique : string -> string -> string = "caml_ftp_putunique"

              (*  rst    remote    local *)
external gget   : int -> string -> string -> bool = "caml_ftp_get"

let get = gget 0
