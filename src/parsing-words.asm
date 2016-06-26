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
code parsing_word?, 'parsing-word?'     ; symbol -- ?
        _ symbol_xt
        _dup
        _tagged_if .1
        _ flags
        _and_literal PARSING
        mov     ebx, f_value
        mov     eax, t_value
        cmovnz  ebx, eax
        _else .1
        mov     ebx, f_value
        _then .1
        next
endcode

; ### process-token
code process_token, 'process-token'     ; string -- object
        _ find_symbol                   ; -- symbol/string ?
        _tagged_if .3                   ; -- symbol
        _dup
        _ parsing_word?
        _tagged_if .4
        _ symbol_xt
        _execute
        _then .4
        _return
        _then .3

        _ token_character_literal?
        _tagged_if .1
        _return
        _then .1

        _ token_string_literal?
        _tagged_if .2
        _return
        _then .2

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
        _ process_token                 ; -- object
        _rfetch
        _ vector_push
        jmp     .top
.bottom:
        _2drop
        _rfrom                          ; -- handle
        next
endcode

; ### V{
code parse_vector, 'V{', IMMEDIATE|PARSING      ; -- handle
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

; ### [[
; transitional
code parse_quotation, '[[', IMMEDIATE|PARSING ; -- quotation
        _quote "]"
        _ parse_until
        _ vector_to_array
        _ array_to_quotation
        next
endcode

; ### \\
; transitional
code quote_symbol, '\\', IMMEDIATE|PARSING ; -- symbol
        _ parse_token
        _dup
        _f
        _eq?
        _tagged_if .1
        _return
        _else .1
        _ find_symbol
        _tagged_if .2
        _return
        _else .2
        _error "undefined word"
        _then .2
        _then .1
        next
endcode

; ### SYMBOL:
code parse_symbol, 'SYMBOL:', PARSING
        _ parse_token                   ; -- string/f
        _dup
        _tagged_if .1
        ; -- string
        _ find_symbol
        _tagged_if .2
        _return
        _else .2
        _ current_vocab
        _ new_symbol
        _dup
        _to last_word
        _ current_vocab
        _ vocab_add_symbol
        _then .2                        ; -- symbol
        _else .1
        _error "attempt to use zero-length string as a name"
        _then .1
        next
endcode

; ### define
code define, 'define'                   ; --
        _ parse_token
        _dup
        _tagged_if .1
        _ find_symbol
        _ not
        _tagged_if .2
        _ current_vocab
        _ new_symbol
        _dup
        _ current_vocab
        _ vocab_add_symbol
        _then .2                        ; -- symbol

        _quote ";"
        _ parse_until
        _ vector_to_array
        _ array_to_quotation            ; -- symbol quotation

        _dup
        _ compile_quotation

        _swap
        _ symbol_set_def                ; --

        _else .1
        _error "attempt to use zero-length string as a name"
        _then .1
        next
endcode

; ### //
code comment_to_eol, '//', IMMEDIATE|PARSING
        _lit 10
        _ parse
        _2drop
        next
endcode
