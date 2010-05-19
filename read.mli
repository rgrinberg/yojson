(* $Id$ *)

(** {3 JSON readers} *)


val from_string :
  ?buf:Buffer.t ->
  ?fname:string ->
  ?lnum:int ->
  string -> json
  (** Read a JSON value from a string.
      @param buf use this buffer at will during parsing instead of creating
      a new one.
      @param fname data file name to be used in error messages. It does
      not have to be a real file.
      @param lnum number of the first line of input. Default is 1.
  *)

val from_channel :
  ?buf:Buffer.t ->
  ?fname:string ->
  ?lnum:int ->
  in_channel -> json
  (** Read a JSON value from a channel.
      See [from_string] for the meaning of the optional arguments. *)

val from_file :
  ?buf:Buffer.t ->
  ?fname:string ->
  ?lnum:int ->
  string -> json
  (** Read a JSON value from a file.
      See [from_string] for the meaning of the optional arguments. *)


type lexer_state = {
  buf : Buffer.t;
    (** Buffer used to accumulate substrings *)
  
  mutable lnum : int;
    (** Current line number (counting from 1) *)

  mutable bol : int;
    (** Absolute position of the first character of the current line
        (counting from 0) *)

  mutable fname : string option;
    (** Name referencing the input file in error messages *)
}

val init_lexer :
  ?buf: Buffer.t ->
  ?fname: string ->
  ?lnum: int -> 
  unit -> lexer_state
  (** Create a fresh lexer_state record. *)

val from_lexbuf :
  lexer_state ->
  ?stream:bool ->
  Lexing.lexbuf -> json
  (** Read a JSON value from a lexbuf.
      A valid initial [lexer_state] can be created with [init_lexer].
      See [from_string] for the meaning of the optional arguments.

      @param stream indicates whether more data may follow. The default value
      is false and indicates that only JSON whitespace can be found between
      the end of the JSON value and the end of the input. *)

val stream_from_string :
  ?buf:Buffer.t ->
  ?fname:string ->
  ?lnum:int ->
  string -> json Stream.t
  (** Input a sequence of JSON values from a string.
      Whitespace between JSON values is fine but not required.
      See [from_string] for the meaning of the optional arguments. *)

val stream_from_channel :
  ?buf:Buffer.t ->
  ?fin:(unit -> unit) ->
  ?fname:string ->
  ?lnum:int ->
  in_channel -> json Stream.t
  (** Input a sequence of JSON values from a channel.
      Whitespace between JSON values is fine but not required.
      @param fin finalization function executed once when the end of the
      stream is reached either because there is no more input or because
      the input could not be parsed, raising an exception.

      See [from_string] for the meaning of the other optional arguments. *)

val stream_from_file :
  ?buf:Buffer.t ->
  ?fname:string ->
  ?lnum:int ->
  string -> json Stream.t
  (** Input a sequence of JSON values from a file.
      Whitespace between JSON values is fine but not required.
      
      See [from_string] for the meaning of the optional arguments. *)

val stream_from_lexbuf :
  lexer_state ->
  ?fin:(unit -> unit) ->
  Lexing.lexbuf -> json Stream.t
  (** Input a sequence of JSON values from a lexbuf.
      A valid initial [lexer_state] can be created with [init_lexer].
      Whitespace between JSON values is fine but not required.
      
      See [stream_from_channel] for the meaning of the optional [fin]
      argument. *)


type json_line = [ `Json of json | `Exn of exn ]
    (** The type of values resulting from a parsing attempt of a JSON value. *)

val linestream_from_channel :
  ?buf:Buffer.t ->
  ?fin:(unit -> unit) ->
  ?fname:string ->
  ?lnum:int ->
  in_channel -> json_line Stream.t
  (** Input a sequence of JSON values, one per line, from a channel.
      Exceptions raised when reading malformed lines are caught
      and represented using [`Exn].

      See [stream_from_channel] for the meaning of the optional [fin]
      argument.
      See [from_string] for the meaning of the other optional arguments. *)

val linestream_from_file :
  ?buf:Buffer.t ->
  ?fname:string ->
  ?lnum:int ->
  string -> json_line Stream.t
  (** Input a sequence of JSON values, one per line, from a file.
      Exceptions raised when reading malformed lines are caught
      and represented using [`Exn].

      See [stream_from_channel] for the meaning of the optional [fin]
      argument.
      See [from_string] for the meaning of the other optional arguments. *)


(**/**)
(* begin undocumented section *)

val finish_string : lexer_state -> Lexing.lexbuf -> string
val finish_escaped_char : lexer_state -> Lexing.lexbuf -> unit
val finish_variant : lexer_state -> Lexing.lexbuf -> json option
val close_variant : lexer_state -> Lexing.lexbuf -> unit
val finish_comment : lexer_state -> Lexing.lexbuf -> unit

val read_space : lexer_state -> Lexing.lexbuf -> unit
val read_eof : Lexing.lexbuf -> bool
val read_null : lexer_state -> Lexing.lexbuf -> unit
val read_bool : lexer_state -> Lexing.lexbuf -> bool
val read_int : lexer_state -> Lexing.lexbuf -> int
val read_number : lexer_state -> Lexing.lexbuf -> [> `Float of float ]
val read_string : lexer_state -> Lexing.lexbuf -> string
val read_ident : lexer_state -> Lexing.lexbuf -> string

val read_sequence :
  ('a -> lexer_state -> Lexing.lexbuf -> 'a) ->
  'a ->
  lexer_state ->
  Lexing.lexbuf -> 'a

val read_list :
  (lexer_state -> Lexing.lexbuf -> 'a) ->
  lexer_state ->
  Lexing.lexbuf -> 'a list

val read_list_rev :
  (lexer_state -> Lexing.lexbuf -> 'a) ->
  lexer_state ->
  Lexing.lexbuf -> 'a list

val read_array_end : Lexing.lexbuf -> unit
val read_array_sep : lexer_state -> Lexing.lexbuf -> unit

val read_array :
  (lexer_state -> Lexing.lexbuf -> 'a) ->
  lexer_state ->
  Lexing.lexbuf -> 'a array

val read_tuple :
  (int -> 'a -> lexer_state -> Lexing.lexbuf -> 'a) ->
  'a ->
  lexer_state ->
  Lexing.lexbuf -> 'a

val read_tuple_end : Lexing.lexbuf -> unit
val read_tuple_sep : lexer_state -> Lexing.lexbuf -> unit

val read_fields :
  ('a -> string -> lexer_state -> Lexing.lexbuf -> 'a) ->
  'a ->
  lexer_state ->
  Lexing.lexbuf -> 'a

val read_object_end : Lexing.lexbuf -> unit
val read_object_sep : lexer_state -> Lexing.lexbuf -> unit
val read_colon : lexer_state -> Lexing.lexbuf -> unit

val read_json : lexer_state -> Lexing.lexbuf -> json


(* end undocumented section *)
(**/**)
