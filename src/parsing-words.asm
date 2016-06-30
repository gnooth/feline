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

        ; first char is "
        _drop
        _nip                            ; -- start-of-word

        _ source
        _drop
        _minus
        _oneplus                        ; skip past opening " char
        _to toin
        _lit '"'
        _ parse                         ; -- addr len

        _swap
        _oneminus
        _swap
        _twoplus                        ; -- addr len

        _ copy_to_string
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
        _else .2
        _dup
        _quote "//"
        _ stringequal
        _tagged_if .3
        _drop
        _ comment_to_eol
        _ parse_token
        _then .3
        _then .2
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

; ### [
code parse_quotation, '[', IMMEDIATE|PARSING ; -- quotation
        _quote "]"
        _ parse_until
        _ vector_to_array
        _ array_to_quotation
        next
endcode

; ### \
code quote_symbol, '\', IMMEDIATE|PARSING ; -- symbol
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

; ### :
code define, ':'                        ; --
        _ parse_token
        _dup
        _tagged_if .1
        _ find_symbol
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
