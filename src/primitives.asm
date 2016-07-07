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

%macro _eq? 0                           ; n1 n2 -- t|f
        mov     eax, t_value
        cmp     rbx, [rbp]
        mov     ebx, f_value
        cmove   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

; ### eq?                               ; obj1 obj2 -- ?
inline eq?, 'eq?'
        _eq?
endinline

; ### =
inline feline_equal, '='                ; n1 n2 -- t|f
        _eq?
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

; ### if
code feline_if, 'if'                    ; ? true false --
        mov     rax, [rbp + BYTES_PER_CELL] ; flag in rax
        mov     rdx, [rbp]              ; true quotation in rdx, false quotation in rbx
        cmp     rax, f_value
        cmovne  rbx, rdx                ; if flag is not f, move true quotation into rbx
        _ callable_code_address         ; code address in rbx
        mov     rax, rbx
        _3drop
        call    rax
        next
endcode

; ### when
code when, 'when'                       ; ? quot --
; if conditional is not f, calls quot
        _swap
        _tagged_if .1
        _ callable_code_address
        mov     rax, rbx
        poprbx
        call    rax
        _else .1
        _drop
        _then .1
        next
endcode

; ### when*
code when_star, 'when*'                 ; ? quot --
; if conditional is not f, calls quot
; conditional remains on the stack to be consumed (or not) by quot
        _over
        _tagged_if .1
        _ callable_code_address
        mov     rax, rbx
        poprbx
        call    rax
        _else .1
        _2drop
        _then .1
        next
endcode

; ### unless
code unless, 'unless'                   ; ? false --
        _swap
        _f
        _equal
        _if .1
        _ callable_code_address
        mov     rax, rbx
        poprbx
        call    rax
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

; ### token-character-literal?
code token_character_literal?, 'token-character-literal?' ; token -- char t | token f
        _dup
        _ string_length
        _lit tagged_fixnum(3)
        _equal
        _zeq_if .1
        _f
        _return
        _then .1

        _lit tagged_zero
        _over
        _ string_nth
        _lit $27
        _tag_char
        _equal
        _zeq_if .2
        _f
        _return
        _then .2

        _lit tagged_fixnum(2)
        _over
        _ string_nth
        _lit $27
        _tag_char
        _equal
        _zeq_if .3
        _f
        _return
        _then .3

        _lit tagged_fixnum(1)
        _swap
        _ string_nth
        _t
        next
endcode

; ### token-string-literal?
code token_string_literal?, 'token-string-literal?' ; token -- string t | token f
        _dup
        _ string_length
        _lit tagged_fixnum(2)
        _ feline_lt
        _tagged_if .1
        _f
        _return
        _then .1

        _lit tagged_zero
        _over
        _ string_nth
        _lit '"'
        _tag_char
        _equal
        _zeq_if .2
        _f
        _return
        _then .2

        _dup
        _ string_length
        _lit tagged_fixnum(1)
        _ fixnum_minus
        _over
        _ string_nth
        _lit '"'
        _tag_char
        _equal
        _zeq_if .3
        _f
        _return
        _then .3

        ; ok, it's a string
        _ string_from                   ; -- untagged-addr untagged-len
        _swap
        _lit 1
        _plus
        _swap
        _lit 2
        _minus

        _ copy_to_string

        _t

        next
endcode

; ### string>number
code string_to_number, 'string>number'  ; string -- n/f
        _ string_from                   ; -- c-addr u

        _dup
        _zeq_if .1
        ; empty string
        _2drop
        _f
        _return
        _then .1

        _ basefetch
        _tor
        _ maybe_change_base             ; -- c-addr2 u2
        _ number?                       ; -- d flag
        _rfrom
        _ basestore

        _zeq_if .2                      ; -- d
        ; conversion failed
        _2drop
        _f
        _return
        _then .2

        _ negative?
        _if .3
        _ dnegate
        _then .3

        ; REVIEW
        _drop

        ; FIXME check range
        _tag_fixnum

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
        _ copy_to_string
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

        _ callable_code_address         ; -- untagged-fixnum code-address

        push    r12
        push    r13
        push    r15
        xor     r12, r12                ; loop index in r12
        mov     r13, rbx                ; code address in r13
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
        _forth_pick
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

; ### pick
code feline_pick, 'pick'                ; x y z -- x y z x
; Factor
        mov     rax, [rbp + BYTES_PER_CELL]
        pushd   rax
        next
endcode

; ### 2over
code feline_2over, '2over'              ; x y z -- x y z x y
; Factor
        _ feline_pick
        _ feline_pick
        next
endcode

; ### write1
code write1, 'write1'                   ; tagged-char --
        _untag_char
        _ emit
        next
endcode

; ### write
code write_, 'write'                    ; string-or-sbuf --
        _ dot_string
        next
endcode

; ### print
code print, 'print'                     ; string-or-sbuf --
        _ dot_string
        _ cr
        next
endcode

; ### local@
code local_fetch, 'local@'              ; index -- value
        _untag_fixnum
        _cells
        add     rbx, r14
        mov     rbx, [rbx]
        next
endcode

; ### local1
code local_store, 'local!'              ; value index --
        _untag_fixnum
        _cells
        add     rbx, r14
        mov     rax, [rbp]
        mov     [rbx], rax
        _2drop
        next
endcode
