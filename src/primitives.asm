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

; ### zero?
inline zero?, 'zero?'
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
inline if_else, 'if-else'               ; ? true false --
        mov     rax, [rbp + BYTES_PER_CELL] ; flag in rax
        mov     rdx, [rbp]              ; true quotation in rdx, false quotation in rbx
        cmp     rax, f_value
        cmovne  rbx, rdx                ; if flag is not f, move true quotation into rbx
        mov     rax, [rbx]
        _3drop
        call    rax
endinline

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

; ### until
code feline_until, 'until'              ; pred body --
        push    r12
        push    r13
        mov     r13, [rbx]              ; body call address in r13
        mov     r12, [rbp]
        mov     r12, [r12]              ; pred call address in r12
        _2drop
.1:
        call    r12
        cmp     rbx, f_value
        poprbx
        jne     .exit
        call    r13
        jmp     .1
.exit:
        pop     r13
        pop     r12
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
        _tag_fixnum
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

; ### times
code times_, 'times'                    ; tagged-fixnum xt --

        _swap
        _untag_fixnum                   ; -- xt n

        push    r12
        mov     r12, rbx                ; n in r12
        push    r13
        mov     rax, [rbp]              ; xt in rax
        mov     r13, [rax]              ; address to call in r13
        _2drop                          ; clean up the stack now!

        test    r12, r12
        jle     .3
.1:
        call    r13
        dec     r12
        jz      .3
        call    r13
        dec     r12
        jnz     .1
.3:
        pop     r13
        pop     r12
.2:
        next
endcode

; ### each-integer
code each_integer, 'each-integer'       ; tagged-fixnum xt --

        _swap
        _untag_fixnum
        _swap

        push    r12
        push    r13
        push    r15
        xor     r12, r12                ; loop index in r12
        mov     r13, [rbx]              ; code address in r13
        mov     r15, [rbp]              ; loop limit in r15
        _2drop                          ; clean up the stack now!
        test    r15, r15
        jle     .2
.1:
        pushd   r12
        _tag_fixnum
        call    r13
        inc     r12
        cmp     r12, r15
        je     .2
        pushd   r12
        _tag_fixnum
        call    r13
        inc     r12
        cmp     r12, r15
        jne     .1
.2:
        pop     r15
        pop     r13
        pop     r12
        next
endcode

; ### find-integer
code find_integer, 'find-integer'       ; tagged-fixnum xt -- i|f
; Quotation must have stack effect ( ... i -- ... ? ).

        _swap
        _untag_fixnum
        _swap

        push    r12
        push    r13
        push    r15
        xor     r12, r12                ; loop index in r12
        mov     r13, [rbx]              ; code address in r13
        mov     r15, [rbp]              ; loop limit in r15
        _2drop                          ; clean up the stack now!
        test    r15, r15
        jle     .2
.1:
        pushd   r12
        _tag_fixnum
        call    r13
        ; test flag returned by quotation
        cmp     rbx, f_value
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jne     .2
        ; flag was f
        ; keep going
        inc     r12
        cmp     r12, r15
        jne     .1
        ; reached end
        ; return f
        _f
        jmp     .3
.2:
        ; return tagged index
        pushd   r12
        _tag_fixnum
.3:
        pop     r15
        pop     r13
        pop     r12
        next
endcode

; ### dip
code dip, 'dip'                         ; x quot -- x
; Removes x, calls quot, restores x to top of stack after quot returns.
        _swap
        _tor                            ; -- quot       r: -- x
        _execute
        _rfrom
        next
endcode

; ### bi@
code bi_at, 'bi@'                       ; x y quot --
; Applies quotation to x, then to y.
; Quotation must have stack effect ( obj -- ... ).
        push    r12                     ; save non-volatile register
        mov     r12, [rbx]              ; address to call in r12
        mov     rax, [rbp]              ; y in rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2] ; -- x
        push    rax                     ; save y
        call    r12
        pushrbx
        pop     rbx                     ; -- y
        call    r12
        pop     r12
        next
endcode

; ### get-datastack
code get_datastack, 'get-datastack'     ; -- array
        push r12

        _lit 10
        _ new_vector_untagged
        popd    r12

        _ depth
        mov     rcx, rbx
        jrcxz   .2
.1:
        push    rcx
        pushd   rcx
        _pick
        pushd   r12
        _ vector_push
        pop     rcx
        loop    .1
.2:
        poprbx

        pushd   r12                     ; -- vector
        pop     r12

        _ vector_to_array               ; -- array

        next
endcode

; ### clear
code clear, 'clear'
; Clear the data stack.
        mov     rbp, [sp0_data]
        next
endcode

; ### .s
code feline_dot_s, '.s'
        _ get_datastack                 ; -- handle
        _ check_array                   ; -- array
        _dup
        _array_length
        _zero
        _?do .1
        _i
        _over
        _array_nth_unsafe
        _ cr
        _ dot_object
        _loop .1
        _drop
        next
endcode

; ### number>string
code number_to_string, 'number>string'  ; n -- string
        _ check_fixnum
        _ basefetch
        _tor
        _ decimal
        _ paren_dot
        _ copy_to_string
        _rfrom
        _ basestore
        next
endcode
