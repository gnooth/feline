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
.top:
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
        _tagged_if .4
        jmp     .top
        _then .4

        _ token_string_literal?
        _tagged_if .5
        jmp     .top
        _then .5

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
        jmp     .top

.error:
        _drop
        _ undefined

        next
endcode

; ### feline-reset
code feline_reset, 'feline-reset'
        _ lp0
        _?dup_if .1
        _ lpstore
        _then .1

        ; REVIEW
        _zeroto exception

        ; REVIEW windows-ui
        _ standard_output

        jmp     repl
        next                            ; for decompiler
endcode

; ### feline-do-error
code feline_do_error, 'feline-do-error' ; string-or-number --
        _dup
        _ string?
        _tagged_if .0
        _to msg
        _ dotmsg
        _ print_backtrace
        _ feline_reset
        _then .0

        _to exception

        _ exception
        _lit -1
        _ equal
        _if .1
        _ feline_reset                  ; ABORT (no message)
        _then .1

        _ exception
        _lit -2
        _equal
        _if .2
        _ dotmsg                        ; ABORT"
        _ print_backtrace
        _ feline_reset
        _then .2

        ; otherwise...
        _ dotmsg

        _ where

        ; automatically print a backtrace if it is likely to be useful
        _ exception
        _lit -13                        ; undefined word
        _notequal
        _ exception
        _lit -4                         ; data stack underflow
        _notequal
        _ and
        _if .4
        _ print_backtrace
        _then .4
        _ feline_reset
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
        _ feline_do_error
        _then .2
        _ white
        _ foreground
        _ feline_dot_s

        ; REVIEW
        _ gc

        _again .1
        next
endcode
