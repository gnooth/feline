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

%macro _feline_equal 0                  ; n1 n2 -- t|f
        mov     eax, t_value
        cmp     rbx, [rbp]
        mov     ebx, f_value
        cmove   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

; ### =
inline feline_equal, '='                ; n1 n2 -- t|f
        _feline_equal
endinline

; ### 0=
inline feline_zeq, '0='
        mov     eax, t_value
        cmp     rbx, tagged_zero
        mov     ebx, f_value
        cmovz   ebx, eax
endinline

; ### not
inline not, 'not'
        mov     eax, t_value
        cmp     rbx, f_value
        mov     ebx, f_value
        cmove   ebx, eax
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

; ### times
code times_, 'times'                    ; tagged-fixnum xt --

        _swap
        _untag_fixnum
        _swap

        push    r12
        mov     r12, [rbp]
        test    r12, r12
        jle     .3
.1:
        call    [rbx]
        dec     r12
        jz      .3
        call    [rbx]
        dec     r12
        jnz     .1
.3:
        pop     r12
.2:
        _2drop
        next
endcode

; ### each-integer
code each_integer, 'each-integer'       ; tagged-fixnum xt --

        _swap
        _untag_fixnum
        _swap

        push    r12
        push    r13
        push    r14
        xor     r12, r12                ; loop index in r12
        mov     r13, [rbx]              ; code address in r13
        mov     r14, [rbp]              ; loop limit in r14
        test    r14, r14
        jle     .2
.1:
        pushd   r12
        _tag_fixnum
        call    r13
        inc     r12
        cmp     r12, r14
        je     .2
        pushd   r12
        _tag_fixnum
        call    r13
        inc     r12
        cmp     r12, r14
        jne     .1
.2:
        pop     r14
        pop     r13
        pop     r12
        _2drop
        next
endcode
