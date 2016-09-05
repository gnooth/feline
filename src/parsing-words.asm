; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

; This program is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.

; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.

; You should have received a copy of the GNU General Public License
; along with this program.  If not, see <http://www.gnu.org/licenses/>.

file __FILE__

; ### parse-string
code parse_string, 'parse-string'       ; -- string
        _lit 128
        _ new_sbuf_untagged             ; -- sbuf
        _tor

        _lit '"'
        _tag_char
        _rfetch
        _ sbuf_push

        _begin .1
        _ slashsource
        _lit '"'
        _ scan
        _nip
        _if .2
        _lit '"'
        _ parse                         ; -- addr len
        _rfetch                         ; -- addr len sbuf
        _ rrot                          ; -- sbuf addr len
        _ sbuf_append_chars             ; --

        _rfrom

        _lit '"'
        _tag_char
        _over
        _ sbuf_push
        _ sbuf_to_string

        _return
        _then .2

        _rfetch
        _ slashsource
        _ sbuf_append_chars

        _lit $0a
        _tag_char
        _rfetch
        _ sbuf_push

        _ refill
        _zeq
        _until .1
        next
endcode

; ### ?scan-token
code maybe_scan_token, '?scan-token'    ; -- string/f

        _ source                        ; -- source-addr source-length

        _dup
        _zeq_if .1
        ; end of input
        _2drop
        _f
        _return
        _then .1

        _ tuck                          ; -- source-length source-addr source-length
        _from toin                      ; -- source-length source-addr source-length >in
        _slashstring                    ; -- source-length addr1 #left

        _dup
        _zeq_if .2
        ; end of input
        _3drop
        _f
        _return
        _then .2

        _ skip_whitespace               ; -- source-length start-of-word #left

        ; now looking at first non-whitespace char
        _over
        _cfetch
        _lit '"'
        _equal
        _if .3                          ; -- source-length start-of-word #left
        ; first non-whitespace char is "
        _drop
        _nip                            ; -- start-of-word
        ; update >in
        _ source
        _drop
        _minus
        _oneplus                        ; skip past opening " char
        _to toin
        ; return token
        _quote '"'
        _return
        _then .3

        _dupd                           ; -- source-length start-of-word start-of-word #left
        _ scan_to_whitespace            ; -- source-length start-of-word end-of-word #left
        _tor                            ; -- source-length start-of-word end-of-word                    r: #left
        _over_minus                     ; -- source-length start-of-word word-length
        _ rot                           ; -- start-of-word word-length source-length
        _rfrom                          ; -- start-of-word word-length source-length #left              r: --
        _dup                            ; -- start-of-word word-length source-length #left #left
        _ zne                           ; -- start-of-word word-length source-length #left -1|0
        _plus                           ; -- start-of-word word-length source-length #left-1|#left
        _minus
        _to toin

        _twodup
        _to parsed_name_length
        _to parsed_name_start

        _?dup_if .4
        _ copy_to_string
        _else .4
        mov     rbx, f_value
        _then .4
        next
endcode

; ### parse-token
code parse_token, 'parse-token'         ; -- string/f
        _ maybe_scan_token
        _dup
        _tagged_if .1

        _dup
        _quote "("
        _ stringequal
        _tagged_if .2
        _drop
        _ paren
        _ parse_token
        _return
        _then .2

        _dup
        _quote "//"
        _ stringequal
        _tagged_if .3
        _drop
        _ comment_to_eol
        _ parse_token
        _return
        _then .3

        _dup
        _quote '"'
        _ stringequal
        _tagged_if .4
        _drop
        _ parse_string
        _return
        _then .4

        _then .1
        next
endcode

; ### t
code t, 't', PARSING                    ; -- t
        _t
        next
endcode

; ### f
code f, 'f', PARSING                    ; -- f
        _f
        next
endcode

; ### parsing-word?
code parsing_word?, 'parsing-word?'     ; object -- ?
        _dup
        _ symbol?
        _tagged_if .1
        _quote "parsing"
        _swap
        _ symbol_prop
        _else .1
        _drop
        _f
        _then .1
        next
endcode

; ### process-token
code process_token, 'process-token'     ; string -- object
        _ local_names
        _if .1
        _dup
        _ local_names                   ; -- string string vector
        _ vector_find_string            ; -- string index/f t|f
        _tagged_if .2                   ; -- string index
        _nip
        _ accum
        _ vector_push

        _quote "local@"
        _quote "feline"
        _ lookup_symbol

        _return
        _else .2                        ; -- string f
        _drop
        _then .2
        _then .1

        _ token_string_literal?
        _tagged_if .6
        _return
        _then .6

        _ find_name                     ; -- symbol/string ?
        _tagged_if .3                   ; -- symbol
        _dup
        _ parsing_word?
        _tagged_if .4
        _ call_symbol
        _then .4
        _return
        _then .3

        _ token_character_literal?
        _tagged_if .5
        _return
        _then .5

        _dup
        _ string_to_number
        cmp     rbx, f_value
        je      .error
        _nip
        _return

.error:
        _drop
        _ undefined

        next
endcode

; ### accum
value accum, 'accum', f_value
; top level accumulator

; ### parse-until
code parse_until, 'parse-until'         ; delimiter -- vector
; REVIEW Delimiter is a string.

        _lit 10
        _ new_vector_untagged
        _tor                            ; -- delimiter          r: -- vector

.top:
        _ parse_token                   ; -- delimiter string/f
        cmp     rbx, f_value
        jne     .1
        poprbx
        _ refill
        _if .2
        jmp     .top
        _then .2
        _error "unexpected end of input"
.1:                                     ; -- delimiter string
        _twodup                         ; -- d s d s
        _ string_equal?                 ; -- d s ?
        cmp     rbx, f_value
        poprbx
        jne     .bottom
        _ process_token                 ; -- object/nothing
        cmp     rbx, nothing
        jne     .3
        poprbx
        jmp     .top
.3:
        _rfetch
        _ vector_push
        jmp     .top
.bottom:
        _2drop
        _rfrom                          ; -- vector

        next
endcode

; ### V{
code parse_vector, 'V{', PARSING        ; -- handle
        _quote "}"
        _ parse_until

        _ statefetch
        _if .2
        ; Add the newly-created vector to gc-roots. This protects it from
        ; being collected and also ensures that its children will be scanned.
        _dup
        _ gc_add_root
        _ literal
        _then .2

        next
endcode

; ### {
code parse_array, '{', PARSING          ; -- handle
        _quote "}"
        _ parse_until
        _ vector_to_array
        next
endcode

; ### [
code parse_quotation, '[', PARSING      ; -- quotation
        _quote "]"
        _ parse_until
        _ vector_to_array
        _ array_to_quotation
        next
endcode

; ### \
; We need some additional comment text here so that NASM isn't
; confused by the '\' in the explicit tag.
; "NASM uses backslash (\) as the line continuation character;
; if a line ends with backslash, the next line is considered to
; be a part of the backslash-ended line."
code quote_symbol, '\', PARSING         ; -- symbol
        _ parse_token
        _dup
        _tagged_if_not .1
        _error "unexpected end of input"
        _return
        _then .1

        _ find_name
        _tagged_if .2
        _ new_wrapper
        _return
        _else .2
        _ undefined
        _then .2

        next
endcode

; ### SYMBOL:
code parse_symbol, 'SYMBOL:', PARSING   ; -- nothing
        _ parse_token                   ; -- string/f
        _dup
        _tagged_if_not .1
        _drop
        _error "unexpected end of input"
        _return
        _then .1

        ; -- string
        _dup
        _ current_vocab
        _ vocab_hashtable
        _ at_star                       ; -- string value/f ?
        _tagged_if .2
        ; -- string symbol
        _2drop
        _nothing
        _return
        _then .2

        ; -- string f
        _drop
        _ current_vocab
        _ new_symbol
        _dup
        _to last_word
        _ current_vocab
        _ vocab_add_symbol
        _nothing
        next
endcode

; ### define-local-internal
code define_local_internal, 'define-local-internal' ; vector --
        _ using_locals?
        _zeq_if .2
        ; first local in this definition
        _ initialize_local_names
        _quote "locals-enter"
        _quote "feline"
        _ lookup_symbol
        _lit tagged_zero
        _ feline_pick
        _ vector_insert_nth_destructive
        _then .2                        ; -- vector

        ; FIXME verify that we're inside a named quotation

        _ parse_token                   ; -- vector string

        ; add name to quotation locals so it can be found
        ; assign index
        _ local_names
        _ vector_push

        ; add tagged index to quotation as literal
        _ locals_defined
        _oneminus
        _tag_fixnum
        _ over
        _ vector_push

        ; add local! to quotation as symbol
        _quote "local!"
        _quote "feline"
        _ lookup_symbol

        _swap
        _ vector_push

        next
endcode

; ### parse-definition
code parse_definition, 'parse-definition' ; -- vector
        _lit 10
        _ new_vector_untagged
        _duptor
        _to accum
.top:
        _ parse_token                   ; -- delimiter string/f
        cmp     rbx, f_value
        jne     .1
        poprbx
        _ refill
        _if .2
        jmp     .top
        _then .2
        _error "unexpected end of input"
.1:                                     ; --  string
        _dup                            ; --
        _quote '"'
        _ string_equal?                 ; -- s ?
        cmp     rbx, f_value
        poprbx
        jne     .bottom

        _dup
        _quote ";"
        _ string_equal?
        _tagged_if .3
        _drop
        jmp     .bottom
        _then .3

        _ process_token                 ; -- object/nothing

        cmp     rbx, nothing
        jne     .4
        poprbx
        jmp     .top
.4:

        _rfetch
        _ vector_push
        jmp     .top

.bottom:
        _rfrom                          ; -- vector
        next
endcode

; ### :
code define, ':'                        ; --
        _f
        _to accum

        _zeroto using_locals?

        _ parse_token
        _dup
        _tagged_if .1
        _ find_name
        _tagged_if .2
        ; REVIEW
        _ ?cr
        _dotq "redefining "
        _dup
        _ symbol_name
        _ write_
        _else .2
        _ current_vocab
        _ new_symbol
        _dup
        _ current_vocab
        _ vocab_add_symbol
        _then .2                        ; -- symbol

        _dup
        _ set_last_word                 ; -- symbol

        _ parse_definition

        _ using_locals?
        _if .3
        _quote "locals-leave"
        _quote "feline"
        _ lookup_symbol
        _ accum
        _ vector_push
        _then .3

        _f
        _to accum                       ; -- symbol vector

        _ vector_to_array
        _ array_to_quotation            ; -- symbol quotation

        _dup
        _ compile_quotation             ; -- symbol quotation code-address
        _ feline_pick
        _ symbol_set_code_address       ; -- symbol quotation
        _swap
        _ symbol_set_def                ; --

        _zeroto using_locals?
        _zeroto local_names

        _else .1
        _error "attempt to use zero-length string as a name"
        _then .1
        next
endcode

; ### //
code comment_to_eol, '//', PARSING
        _lit 10
        _ parse
        _2drop
        next
endcode

; ### :>
code define_local, ':>', PARSING

        _ using_locals?
        _zeq_if .2
        ; first local in this definition
        _ initialize_local_names
        _quote "locals-enter"
        _quote "feline"
        _ lookup_symbol
        _lit tagged_zero
        _ accum
        _ vector_insert_nth_destructive
        _then .2

        ; FIXME verify that we're inside a named quotation

        _ parse_token                   ; -- string

        ; add name to quotation locals so it can be found
        ; assign index
        _ local_names
        _ vector_push

        ; add tagged index to quotation as literal
        _ locals_defined
        _oneminus
        _tag_fixnum
        _ accum
        _ vector_push

        ; add local! to quotation as symbol
        _quote "local!"
        _quote "feline"
        _ lookup_symbol
        _ accum
        _ vector_push

        ; return nothing
        _nothing
        next
endcode

; ### <<
code parse_immediate, '<<', PARSING
        _quote ">>"
        _ parse_until
        _ vector_to_array
        _ array_to_quotation
        _ call_quotation
        next
endcode

; ### HELP:
code parse_help, 'HELP:', PARSING       ; -- nothing
        _ parse_token                   ; -- string/f
        _dup
        _tagged_if_not .1
        _drop
        _error "unexpected end of input after HELP:"
        _return
        _then .1                        ; -- string

        _ find_name
        _tagged_if_not .2
        _ undefined
        _return
        _then .2                        ; -- symbol

        _quote ";"
        _ parse_until
        _ vector_to_array               ; -- symbol array

        _swap
        _ symbol_set_help

        ; return nothing
        _nothing
        next
endcode
