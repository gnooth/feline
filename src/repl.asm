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

; ### find-symbol
code find_symbol, 'find-symbol'         ; string -- symbol/string ?
        _ context_vector
        _ vector_length
        _untag_fixnum
        _zero
        _?do .1
        _dup                            ; -- string string
        _i
        _ context_vector
        _ vector_nth_untagged           ; -- string string vocab
        _ vocab_hashtable
        _ at_star                       ; -- string symbol/f ?
        _tagged_if .2
        _nip
        _t
        _unloop
        _return
        _then .2
        _drop
        _loop .1
        _f
        next
endcode

; ### find-string
code find_string, 'find-string'         ; string -- xt t | string f
        _ context_vector
        _ vector_length
        _untag_fixnum
        _zero
        _?do .1
        _dup                            ; -- string string
        _i
        _ context_vector
        _ vector_nth_untagged           ; -- string string vocab
        _ vocab_hashtable
        _ at_                           ; -- string symbol|f
        _dup
        _tagged_if .2
        _ symbol_xt                     ; -- string xt
        _nip
        _t
        _unloop
        _return
        _then .2
        _drop
        _loop .1
        _f
        next
endcode

; ### undefined
code undefined, 'undefined'             ; string/symbol --
        _dup
        _ symbol?
        _tagged_if .1
        _ symbol_name
        _then .1
        _quote " ?"
        _ concat
        _ throw
        next
endcode

; ### execute-symbol
code execute_symbol, 'execute-symbol'   ; symbol --
        _dup
        _ symbol_xt
        _dup
        _tagged_if .1
        _nip
        _execute
        _return
        _else .1
        _drop
        _then .1                        ; -- symbol

        _dup
        _ symbol_def
        _dup
        _tagged_if .2
        _nip
        _ call_quotation
        _return
        _else .2
        _drop
        _then .2

        _ undefined

        next
endcode

; ### eval
code eval, 'eval'                       ; --
        _begin .1
        _ ?stack
        _ parse_token
        _dup
        _tagged_if .2
        _ verify_string
        _ find_symbol
        _tagged_if .3
        _ execute_symbol
        _else .3

        _ token_character_literal?
        _tagged_if .41
        _return
        _then .41

        _ token_string_literal?
        _tagged_if .42
        _return
        _then .42

        _dup
        _ string_to_number
        cmp     rbx, f_value
        je      .error
        _nip

        _then .3
        _else .2
        _drop
        _return
        _then .2
        _again .1

.error:
        _drop
        _ undefined

        next
endcode

; ### repl
code repl, 'repl'                       ; --

        _lit eval_xt
        _lit interpret_xt
        _tobody
        _store

        _begin .1

        ; REVIEW
        mov     rsp, [rp0_data]

        _ ?cr
        _ green
        _ foreground
        _dotq "> "
        _ query
        _ tib
        _ ntib
        _fetch
        _zero
        _ set_input
        _lit eval_xt
        _ catch
        _?dup_if .2
        ; THROW occurred
        _ do_error
        _then .2
        _ white
        _ foreground
        _ feline_dot_s

        ; REVIEW
        _ gc

        _again .1
        next
endcode
