; Copyright (C) 2016-2018 Peter Graves <gnooth@gmail.com>

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

; ### dip
code dip, 'dip'                         ; x quot -> x
; Removes x, calls quot, restores x to top of stack after quot returns.
        _ callable_raw_code_address     ; code address in rbx
        push    qword [rbp]
        mov     rax, rbx
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        call    rax
        pushrbx
        pop     rbx
        next
endcode

; ### 2dip
code twodip, '2dip'                     ; x y quot -- x y
; Remove x and y, call quot, restore x and y to top of stack after
; quot returns.
        _ callable_raw_code_address     ; code address in rbx
        mov     rax, rbx                ; code address in rax
        poprbx                          ; -- x y
        _tor
        _tor
        call    rax
        _rfrom
        _rfrom
        next
endcode

; ### keep
code keep, 'keep'                       ; .. x quot -- .. x
; Factor
; "Call a quotation with a value on the stack, restoring the value when
; the quotation returns."
        _ callable_raw_code_address     ; code address in rbx
        mov     rax, rbx                ; code address in rax
        poprbx
        push    rbx
        call    rax
        pushrbx
        pop     rbx
        next
endcode

; ### 2keep
code twokeep, '2keep'                   ; .. x y quot -- .. x y
        _ callable_raw_code_address     ; code address in rbx
        mov     rax, rbx                ; code address in rax
        poprbx
        push    qword [rbp]
        push    rbx
        call    rax
        _tworfrom
        next
endcode

; ### bi
code bi, 'bi'                           ; x quot1 quot2 --
; Apply quot1 to x, then apply quot2 to x.
        _ callable_raw_code_address
        _tor
        _ keep
        pop     rax
        call    rax
        next
endcode

; ### tri
code tri, 'tri'                         ; x quot1 quot2 quot3 --
; Apply quot1 to x, then apply quot2 to x, and finally apply quot3 to x.
        _tor
        _tor
        _ keep
        _rfrom
        _ keep
        _rfrom
        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        call    rax
        next
endcode

; ### cleave
code cleave, 'cleave'                   ; x seq --
; Apply each quotation in seq to x.
        push    r12
        mov     r12, [rbp]              ; x in r12
        _nip                            ; -- seq
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        _untag_fixnum
        _do_times .1
        _tagged_loop_index
        _this                           ; -- tagged-index handle
        _ nth_unsafe                    ; -- quotation
        _ callable_raw_code_address
        mov     rax, rbx
        mov     rbx, r12                ; -- x
        call    rax
        _loop .1
        pop     this_register
        pop     r12
        next
endcode

; ### 2tri
code twotri, '2tri'                     ; x y quot1 quot2 quot3 --
; Apply quot1 to x and y, then apply quot2 to x and y, and finally apply
; quot3 to x and y.
        _tor
        _tor
        _ twokeep
        _rfrom
        _ twokeep
        _rfrom
        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        call    rax
        next
endcode

; ### 2bi
code twobi, '2bi'                       ; x y quot1 quot2 --
; Apply quot1 to x and y, then apply quot2 to x and y.
        _ callable_raw_code_address
        _tor
        _ twokeep
        pop     rax
        call    rax
        next
endcode

; ### bi@
code bi@, 'bi@'                         ; x y quot ->
; Apply quot to x, then to y.
; Quotation must have stack effect ( obj -> ... ).

        ; protect callable from gc
        push    rbx

        _ callable_raw_code_address

        push    r12                     ; save non-volatile register
        mov     r12, rbx                ; address to call in r12
        mov     rax, [rbp]              ; y in rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2] ; -> x
        push    rax                     ; save y
        call    r12
        pushrbx
        pop     rbx                     ; -> y
        call    r12
        pop     r12

        ; drop callable
        pop     rax

        next
endcode

; ### tri@
code tri@, 'tri@'                       ; x y z quot ->
; Apply quot to x, then to y, then to z.
; Quotation must have stack effect ( obj -> ... ).

        ; protect callable from gc
        push    rbx

        _ callable_raw_code_address

        push    r12                     ; save non-volatile register
        mov     r12, rbx                ; address to call in r12

        mov     rax, [rbp]                      ; z in rax
        mov     rdx, [rbp + BYTES_PER_CELL]     ; y in rdx
        push    rax                     ; save z
        push    rdx                     ; save y

        _3drop                          ; -> x

        call    r12
        pushrbx
        pop     rbx                     ; -> y
        call    r12
        pushrbx
        pop     rbx                     ; -> z
        call    r12

        pop     r12

        ; drop callable
        pop     rax

        next
endcode

; ### ?
code question, '?'                      ; ? true false -- true/false
        cmp     qword [rbp + BYTES_PER_CELL], f_value
        mov     rax, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        cmovne  rbx, rax
        next
endcode

; ### case
code case, 'case'               ; x array --
        _ check_array
        push    this_register
        mov     this_register, rbx
        poprbx                  ; -- x

        _this_array_raw_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe  ; -- x quotation-or-2array

        _dup
        _ array?
        _tagged_if .2

        _dup
        _ array_first           ; -- x array element
        _pick                   ; -- x array element x
        _ feline_equal
        _tagged_if .3           ; -- x array
        _nip
        _ array_second
        _ call_quotation
        _unloop
        jmp     .exit
        _else .3
        _drop
        _then .3

        _else .2
        ; not an array
        ; must be a quotation
        _ call_quotation
        _unloop
        jmp     .exit
        _then .2

        _loop .1

        ; not found
        _error "no case"

.exit:
        pop     this_register
        next
endcode

; ### cond
code cond, 'cond'               ; array --
        _ check_array
        push    this_register
        mov     this_register, rbx
        poprbx                  ; --

        _this_array_raw_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe  ; -- 2array-or-quotation

        _dup
        _ array?
        _tagged_if .2           ; -- 2array

        _duptor
        _ array_first           ; -- quotation
        _ call_quotation
        _tagged_if .3           ; --
        _rfrom
        _ array_second
        _ call_quotation
        _unloop
        jmp     .exit
        _else .3
        _rdrop
        _then .3

        _else .2
        ; not an array
        ; must be a quotation
        _ call_quotation
        _unloop
        jmp     .exit
        _then .2

        _loop .1

        ; not found
        _error "no cond"

.exit:
        pop     this_register
        next
endcode

; ### &&
code short_circuit_and, '&&'            ; seq -> ?
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        _untag_fixnum
        _do_times .1
        _tagged_loop_index
        _this                           ; -- tagged-index handle
        _ nth_unsafe                    ; -- quotation
        _ call_quotation
        cmp     rbx, f_value
        mov     rax, rbx
        poprbx
        jne     .2
        _unloop
        jmp     .exit
.2:
        _loop .1
.exit:
        pushrbx
        mov     rbx, rax
        pop     this_register
        next
endcode

; ### ||
code short_circuit_or, '||'             ; seq -> ?
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        _untag_fixnum
        _do_times .1
        _tagged_loop_index
        _this                           ; -- tagged-index handle
        _ nth_unsafe                    ; -- quotation
        _ call_quotation
        cmp     rbx, f_value
        mov     rax, rbx
        poprbx
        je      .2
        _unloop
        jmp     .exit
.2:
        _loop .1
.exit:
        pushrbx
        mov     rbx, rax
        pop     this_register
        next
endcode

; ### both?
code both?, 'both?'                     ; quot1 quot2 -> ?
; Short-circuit `and` for two quotations.
; Removes both quotations from the stack. Calls quot1.
; Returns f without calling quot2 if quot1 returns f.
; Otherwise, calls quot2 and returns the result quot2
; returns.
        _tor                            ; move quot2 to return stack
        _ callable_raw_code_address     ; quot1 code address in rbx
        mov     rax, rbx                ; quot1 code address in rax
        poprbx                          ; empty stack
        call    rax                     ; call quot1
        cmp     rbx, f_value
        je      .1
        pop     rbx
        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        call    rax
        next
.1:
        _rdrop
        next
endcode

; ### either?
code either?, 'either?'                 ; quot1 quot2 -> ?
; Short-circuit `or` for two quotations.
; Removes both quotations from the stack. Calls quot1.
; Returns the result without calling quot2 if the result
; is not f. Otherwise, calls quot2 and returns the result quot2
; returns.
        _tor                            ; move quot2 to return stack
        _ callable_raw_code_address     ; quot1 code address in rbx
        mov     rax, rbx                ; quot1 code address in rax
        poprbx                          ; empty stack
        call    rax                     ; call quot1
        cmp     rbx, f_value
        jne     .1
        pop     rbx
        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        call    rax
        next
.1:
        _rdrop
        next
endcode
