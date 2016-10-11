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

; ### vocab-find-name
code vocab_find_name, 'vocab-find-name' ; name vocab -- symbol/name ?
        _ lookup_vocab
        _dup
        _tagged_if .1
        _ vocab_hashtable
        _ at_star
        _then .1
        next
endcode

; ### find-qualified-name               ; string -- symbol/string ?
code find_qualified_name, 'find-qualified-name'
        _lit ':'
        _tag_char
        _over
        _ index                         ; -- string index/f
        cmp     rbx, f_value
        jnz     .1
        _return
.1:
        ; -- string index
        _dupd                           ; -- string string index

        _quotation .2
        _ string_head
        _end_quotation .2

        _quotation .3
        _lit tagged_fixnum(1)
        _ feline_plus
        _ string_tail
        _end_quotation .3

        _ twobi                         ; -- string head tail

        _swap

        _ vocab_find_name               ; -- string symbol/string ?

        _tagged_if .4
        _nip
        _t
        _else .4
        _drop
        _f
        _then .4

        next
endcode

; ### find-name
code find_name, 'find-name'             ; string -- symbol/string ?
        _dup
        _ current_vocab
        _ vocab_hashtable
        _ at_star
        _tagged_if .0
        _nip
        _t
        _return
        _else .0
        _drop
        _then .0

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

        _ find_qualified_name

        next
endcode

; ### error
code error, 'error'                     ; string --
        _ feline_throw
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
        _ error
        next
endcode

; ### literal?
code literal?, 'literal?'               ; string -- literal/string ?
        _ token_character_literal?
        _tagged_if .1                   ; -- literal
        _t
        _return
        _then .1                        ; -- string

        _ token_string_literal?
        _tagged_if .2                   ; -- literal
        _t
        _return
        _then .2                        ; -- string

        _dup
        _ string_to_number              ; -- string n/f
        _dup
        _tagged_if .3                   ; -- string n
        _nip
        _t
        _return
        _else .3
        _drop
        _then .3                        ; -- string

        _f

        next
endcode

; ### feline-interpret1
code feline_interpret1, 'feline-interpret1' ; string --
        _ literal?
        _tagged_if .1
        _return
        _then .1                        ; -- string

        ; not a literal
        _ find_name                     ; -- symbol/string ?
        _tagged_if .2
        _ call_symbol
        _else .2
        _ undefined
        _then .2                        ; -- symbol

        next
endcode

; ### feline-interpret
code feline_interpret, 'feline-interpret' ; --
        _begin .1
        _ ?stack
        _ parse_token                   ; -- string/f
        _dup
        _tagged_while .1
        _ feline_interpret1
        _repeat .1
        _drop
        next
endcode

; ### feline-reset
code feline_reset, 'feline-reset'
        _ lp0
        _?dup_if .1
        _ lpstore
        _then .1

        _ get_namestack
        _dup
        _ vector?
        _tagged_if .2
        _lit tagged_fixnum(1)
        _swap
        _ vector_set_length
        _then .2

        ; REVIEW
        _zeroto exception

        ; REVIEW windows-ui
        _ forth_standard_output

        jmp     repl
        next                            ; for decompiler
endcode

; ### feline-where
code feline_where, 'feline-where'       ; --
        ; Print source line.
        _ ?nl
        _ source                        ; -- addr len
        _ copy_to_string
        _ write_string

        ; Put ^ on next line after last character of offending token.
        _ nl
        _ parsed_name_start
        _ parsed_name_length
        _plus
        _ source
        _drop
        _minus
        _tag_fixnum
        _ spaces
        _lit '^'
        _tag_char
        _ write_char
        _ nl

        _ source_id
        _zgt
        _if .2
        _ ?nl
        _ source_filename
        _?dup_if .3
        _ write_string
        _ space
        _then .3
        _quote "line "
        _ write_string
        _ source_line_number
        _tag_fixnum
        _ number_to_string
        _ nl
        _then .2

        next
endcode


; ### feline-do-error
code feline_do_error, 'feline-do-error' ; string-or-number --
        _dup
        _ string?
        _tagged_if .0
        _ ?nl
        _ red
        _ foreground
        _ write_string
        _ feline_where
        _ print_backtrace
        _ nl
        _ feline_reset
        _then .0

        ; code below this point is for Forth exceptions
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

; ### feline-query
code feline_query, 'feline-query'       ; --
        _ ?nl
        _quote "accept-string"          ; -- name
        _quote "accept"                 ; -- name vocab-name
        _ ?lookup_symbol                ; -- symbol/f
        _dup
        _tagged_if .1                   ; -- symbol
        _ call_symbol                   ; -- string
        _ string_from                   ; -- c-addr u
        _lit 80
        _ min                           ; -- c-addr u
        _dup
        _ ntib
        _ store
        _ tib
        _ swap
        _ cmove
        _ toin
        _ off
        _else .1
        _drop
        _ prompt
        _ forth_query
        _then .1
        next
endcode

; ### print-datastack
code print_datastack, 'print-datastack' ; --
        _ depth
        _if .1
        _ ?nl
        _ white
        _ foreground
        _quote "--- Data stack:"
        _ write_
        _ feline_dot_s
        _then .1
        next
endcode

; ### repl
code repl, 'repl'                       ; --

        _lit feline_interpret_xt
        _lit interpret_xt
        _tobody
        _store

        _begin .1

        ; REVIEW
        mov     rsp, [rp0_data]

        _ feline_query

        _ tib
        _ ntib
        _fetch
        _zero
        _ set_input

        _ tib
        _ ntib
        _fetch
        _ copy_to_string
        _ new_lexer

        _ begin_scope
        _ lexer
        _ set

        _quotation .1
        _ feline_interpret
        _end_quotation .1
        _quotation .2
        _ feline_do_error
        _end_quotation .2
        _ recover

        _ end_scope

        _ print_datastack

        ; REVIEW
        _ gc

        _again .1
        next
endcode

; ### break
code break, 'break'                     ; --
        _ ?nl
        _ red
        _ foreground
        _quote "break called"
        _ print
        _ white
        _ foreground
        _quote "--- Data stack: "
        _ write_
        _ depth
        _if .1
        _ feline_dot_s
        _else .1
        _quote "Empty"
        _ write_
        _then .1
        _ nl
        _quote "Press c to continue..."
        _ print
        _begin .2
        _ key
        _lit 'c'
        _equal
        _if .3
        _return
        _then .3
        _again .2
        next
endcode
