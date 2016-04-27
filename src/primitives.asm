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

; Feline primitives

IN_FELINE

; ### t
inline t, 't'                           ; -- t
        _t
endinline

; ### f
inline f, 'f'                           ; -- f
        _f
endinline

; ### =
inline feline_equal, '='                ; n1 n2 -- t|f
        mov     eax, t_value
        cmp     rbx, [rbp]
        mov     ebx, f_value
        cmove   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### 0=
inline feline_zeq, '0='
        mov     eax, t_value
        cmp     rbx, tagged_zero
        mov     ebx, f_value
        cmovz   ebx, eax
endinline

; ### if-else
code if_else, 'if-else'                 ; ? true false --
        _ rot
        _f
        _equal
        _if .1
        _nip
        _else .1
        _drop
        _then .1
        _ execute
        next
endcode

; ### when
code when, 'when'                       ; ? true --
        _swap
        _f
        _equal
        _if .1
        _drop
        _else .1
        _ execute
        _then .1
        next
endcode

; ### unless
code unless, 'unless'                   ; ? false --
        _swap
        _f
        _equal
        _if .1
        _ execute
        _else .1
        _drop
        _then .1
        next
endcode

; ### feline-interpret-do-literal
code feline_interpret_do_literal, 'feline-interpret-do-literal' ; $addr -- n | d
        _ character_literal?
        _if .1
        _tag_char
        _return
        _then .1

        _ string_literal?
        _if .2
        _ copy_to_transient_string
        _return
        _then .2

        _ number

        _ double?
        _zeq_if .3
        _drop
        _tag_fixnum
        _then .3

        next
endcode

; ### feline-compile-do-literal
code feline_compile_do_literal, 'feline-compile-do-literal' ; $addr --
        _ character_literal?
        _if .1
        _tag_char
        _ literal
        _return
        _then .1

        _ string_literal?
        _if .2                          ; -- c-addr u
        _ copy_to_static_string         ; -- string
        _ literal
        _return
        _then .2

        _ number
        _ double?
        _if .3
        _ flush_compilation_queue
        _ twoliteral
        _else .3
        _drop
; %ifdef USE_TAGS
;         _ use_tags?
;         _if .4
        _tag_fixnum
;         _then .4
; %endif
        _ literal
        _then .3
        next
endcode

; ### feline-interpret1
code feline_interpret1, 'feline-interpret1' ; $addr --
        _ find
        _?dup_if .1
        _ interpret_do_defined
        _else .1                        ; -- c-addr
        _ feline_interpret_do_literal
        _then .1
        next
endcode

; ### feline-compile1
code feline_compile1, 'feline-compile1' ; $addr --
        _ find_local                    ; -- $addr-or-index flag
        _if .1
        _ flush_compilation_queue
        _ compile_local_ref
        _else .1
        _ find
        _?dup_if .2
        _ compile_do_defined
        _else .2                        ; -- c-addr
        _ feline_compile_do_literal
        _then .2
        _then .1
        next
endcode

; ### feline-interpret
code feline_interpret, 'feline-interpret' ; --
; not in standard
        _begin .1
        _ ?stack
        _ blword
        _dupcfetch
        _while .1
        _ statefetch
        _if .2
        _ feline_compile1
        _else .2
        _ feline_interpret1
        _then .2
        _repeat .1
        _drop
        next
endcode

; ### feline-prompt
code feline_prompt, 'feline-prompt'     ; --
        _ green
        _ foreground
        _dotq "Feline> "
        next
endcode
