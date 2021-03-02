; Copyright (C) 2016-2021 Peter Graves <gnooth@gmail.com>

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
; Remove x, call quot, restore x to top of stack after quot returns.
        _ callable_raw_code_address     ; code address in rbx
        push    qword [rbp]             ; save x
        mov     rax, rbx
        _2drop
        call    rax
        _dup
        pop     rbx                     ; restore x
        next
endcode

; ### 2dip
code twodip, '2dip'                     ; x y quot -> x y
; Remove x and y, call quot, restore x and y to top of stack after
; quot returns.
        _ callable_raw_code_address     ; code address in rbx
        mov     rax, rbx                ; code address in rax
        _drop                           ; -> x y
        _tor
        _tor
        call    rax
        _rfrom
        _rfrom
        next
endcode

; ### keep
code keep, 'keep'                       ; .. x quot -> .. x
; Factor
; "Call a quotation with a value on the stack, restoring the value when
; the quotation returns."
        _ callable_raw_code_address     ; code address in rbx
        mov     rax, rbx                ; code address in rax
        _drop
        push    rbx
        call    rax
        _dup
        pop     rbx
        next
endcode

; ### 2keep
code twokeep, '2keep'                   ; .. x y quot -> .. x y
        _ callable_raw_code_address     ; code address in rbx
        mov     rax, rbx                ; code address in rax
        _drop
        push    qword [rbp]
        push    rbx
        call    rax
        _tworfrom
        next
endcode

; ### bi
code bi, 'bi'                           ; x quot1 quot2 ->
; Apply quot1 to x, then apply quot2 to x.
        _ callable_raw_code_address
        _tor
        _ keep
        pop     rax
        call    rax
        next
endcode

; ### tri
code tri, 'tri'                         ; x quot1 quot2 quot3 ->
; Apply quot1 to x, then apply quot2 to x, and finally apply quot3 to x.
        _tor
        _tor
        _ keep
        _rfrom
        _ keep
        _rfrom
        _ callable_raw_code_address
        mov     rax, rbx
        _drop
        call    rax
        next
endcode

; ### cleave
code cleave, 'cleave'                   ; x seq ->
; Apply each quotation in seq to x.
        push    r12
        mov     r12, [rbp]              ; x in r12
        _nip                            ; -> seq
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        _untag_fixnum
        _do_times .1
        _tagged_loop_index
        _this                           ; -> tagged-index handle
        _ nth_unsafe                    ; -> quotation
        _ callable_raw_code_address
        mov     rax, rbx
        mov     rbx, r12                ; -> x
        call    rax
        _loop .1
        pop     this_register
        pop     r12
        next
endcode

; ### 2tri
code twotri, '2tri'                     ; x y quot1 quot2 quot3 ->
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
        _drop
        call    rax
        next
endcode

; ### 2bi
code twobi, '2bi'                       ; x y quot1 quot2 ->
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
        push    qword [rbp]             ; save y
        _2drop                          ; -> x
        call    r12
        _dup
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
        _dup
        pop     rbx                     ; -> y
        call    r12
        _dup
        pop     rbx                     ; -> z
        call    r12

        pop     r12

        ; drop callable
        pop     rax

        next
endcode

; ### ?
inline question, '?'                    ; condition x y -> x-or-y
; If condition is non-nil, returns x, otherwise returns y.
        cmp     qword [rbp + BYTES_PER_CELL], NIL
        mov     rax, [rbp]
        _2nip
        cmovne  rbx, rax
endinline

; ### case
code case, 'case'               ; x array ->
        _ check_array
        push    this_register
        mov     this_register, rbx
        _drop                   ; -> x

        _this_array_raw_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe  ; -> x quotation-or-2array

        _dup
        _ array?
        _tagged_if .2

        _dup
        _ array_first           ; -> x array element
        _pick                   ; -> x array element x
        _ feline_equal
        _tagged_if .3           ; -> x array
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

feline_symbol any, '_'

; ### match?
code match?, 'match?'                   ; x y -> x ?
        cmp     rbx, [rbp]
        jne     .1
        mov     ebx, TRUE
        next
.1:
        _over
        _ equal?
        next
endcode

; ### match*
code match_star, 'match*'               ; x array ->
        _ check_array
        push    this_register
        mov     this_register, rbx      ; this_register: ^array
        _drop                           ; -> x
        _this_array_raw_length
        shr     rbx, 1                  ; divide by 2
        _do_times .1
        _raw_loop_index
        shl     rbx, 1                  ; multiply by 2
        _this_array_nth_unsafe          ; -> x key

        ; check for _
        mov     rax, S_any
        shl     rax, STATIC_OBJECT_TAG_BITS
        or      rax, STATIC_SYMBOL_TAG
        cmp     rbx, rax
        jne     .2
        _2drop
        _raw_loop_index
        shl     rbx, 1
        add     rbx, 1
        _this_array_nth_unsafe
        _ call_quotation
        _unloop
        jmp     .exit

.2:
        _over
        _ feline_equal
        _tagged_if .2
        ; found a match
        _drop
        _raw_loop_index
        shl     rbx, 1
        add     rbx, 1
        _this_array_nth_unsafe
        _ call_quotation
        _unloop
        jmp     .exit
        _then .2

        _loop .1

        ; reached end of loop
        _error "no match"

.exit:
        pop     this_register
        next
endcode

; ### match
code match, 'match', SYMBOL_IMMEDIATE

        _ must_parse_token

        _quote "{"
        _ equal?
        cmp     rbx, NIL
        _drop
        jne     .1
        _error "no {"

.1:
        _quote "}"
        _ parse_until
        _ vector_to_array
        _ maybe_add

        _tick match_star
        _ maybe_add

        next
endcode

; ### old-cond
code old_cond, 'old-cond'               ; array ->
        _ check_array
        push    this_register
        mov     this_register, rbx
        _drop                   ; ->

        _this_array_raw_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe  ; -> 2array-or-quotation

        _dup
        _ array?
        _tagged_if .2           ; -> 2array

        _duptor
        _ array_first           ; -> quotation
        _ call_quotation
        _tagged_if .3           ; ->
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

code fat_arrow, '=>', SYMBOL_IMMEDIATE
        next
endcode

; ### cond
code cond, 'cond'                       ; array ->
        _dup
        _ array_first
        _ quotation?
        _tagged_if_not .1
        _ old_cond
        _return
        _then .1

        _ check_array
        push    this_register
        mov     this_register, rbx
        _drop                           ; -> void

        _this_array_raw_length
        shr     rbx, 1
        _do_times .2

        _raw_loop_index
        shl     rbx, 1
        _this_array_nth_unsafe          ; -> quotation
        _ call_quotation                ; -> ?
        _tagged_if .3
        _raw_loop_index
        shl     rbx, 1
        add     rbx, 1
        _this_array_nth_unsafe
        _ call_quotation
        _unloop
        jmp     .exit
        _then .3

        _loop .2

        ; not found
        _error "no cond"

.exit:
        pop     this_register
        next
endcode

; ### &&
code short_circuit_and, '&&'            ; seq -> ?
; If every quotation returns true, returns the result from the last quotation.
; If any quotation returns nil, returns nil without calling the subsequent
; quotations.
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        sar     rbx, FIXNUM_TAG_BITS
        jz      .exit2
        _do_times .1
        _tagged_loop_index
        _this                           ; -> tagged-index handle
        _ nth_unsafe                    ; -> quotation
        _ call_quotation
        cmp     rbx, NIL
        mov     rax, rbx
        _drop
        jne     .2
        _unloop
        jmp     .exit
.2:
        _loop .1
.exit:
        _dup
        mov     rbx, rax
        pop     this_register
        next
.exit2:
        mov     rbx, NIL
        pop     this_register
        next
endcode

; ### ||
code short_circuit_or, '||'             ; seq -> ?
; Returns the first true result, or nil if every quotation returns nil.
        push    this_register
        mov     this_register, rbx      ; handle to seq in this_register
        _ length
        sar     rbx, FIXNUM_TAG_BITS
        jz      .exit2
        _do_times .1
        _tagged_loop_index
        _this                           ; -> tagged-index handle
        _ nth_unsafe                    ; -> quotation
        _ call_quotation
        cmp     rbx, NIL
        mov     rax, rbx
        _drop
        je      .2
        _unloop
        jmp     .exit
.2:
        _loop .1
.exit:
        _dup
        mov     rbx, rax
        pop     this_register
        next
.exit2:
        mov     rbx, NIL
        pop     this_register
        next
endcode

; ### and*
code and_star, 'and*'                   ; quot1 quot2 -> ?
; Short-circuit `and` for two quotations.
;
; Remove both quotations from the stack and call quot1. If quot1
; returns nil, return nil without calling quot2. Otherwise, call
; quot2 and return the result quot2 returns.

        _tor                            ; move quot2 to return stack
        _ callable_raw_code_address     ; quot1 code address in rbx
        mov     rax, rbx                ; quot1 code address in rax
        _drop                           ; empty stack
        call    rax                     ; call quot1
        cmp     rbx, NIL
        je      .1
        pop     rbx
        _ callable_raw_code_address
        mov     rax, rbx
        _drop
        call    rax
        next
.1:
        _rdrop
        next
endcode

; ### both?
; Deprecated. Use and*.
code both?, 'both?'                     ; quot1 quot2 -> ?
        _ and_star
        next
endcode

; ### or*
code or_star, 'or*'                     ; quot1 quot2 -> ?
; Short-circuit `or` for two quotations.
;
; Remove both quotations from the stack and call quot1. If the
; result is non-nil, return that result without calling quot2.
; Otherwise, call quot2 and return the result quot2 returns.

        _tor                            ; move quot2 to return stack
        _ callable_raw_code_address     ; quot1 code address in rbx
        mov     rax, rbx                ; quot1 code address in rax
        _drop                           ; empty stack
        call    rax                     ; call quot1
        cmp     rbx, NIL
        jne     .1
        pop     rbx
        _ callable_raw_code_address
        mov     rax, rbx
        _drop
        call    rax
        next
.1:
        _rdrop
        next
endcode

; ### either?
; Deprecated. Use or*.
code either?, 'either?'                 ; quot1 quot2 -> ?
        _ or_star
        next
endcode

; ### replicate
code replicate, 'replicate'             ; n quotation -> array
; Factor
; Calls the quotation n times and collects the results into a new array.
; quotation: void -> x

        ; protect callable from gc
        push    rbx

        _ callable_raw_code_address

        push    r12
        push    this_register

        mov     r12, rbx                ; r12: ^code
        _drop                           ; -> n

        _dup
        _ make_array_1
        mov     this_register, rbx      ; this_register: array (handle)
        _drop                           ; -> n

        _untag_fixnum
        _do_times .1

        call    r12

        _tagged_loop_index
        _this
        _ array_set_nth                 ; FIXME array-set-nth-unsafe

        _loop .1

        _dup
        mov     rbx, this_register

        pop     this_register
        pop     r12

        ; drop callable
        pop     rax

        next
endcode
