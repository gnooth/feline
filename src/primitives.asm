; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

; ### identity
code identity, 'identity'
        next
endcode

asm_global last_word_, NIL

; ### last-word
code last_word, 'last-word'             ; -- word
        _dup
        mov     rbx, [last_word_]
        next
endcode

; ### set-last-word
code set_last_word, 'set-last-word'     ; word --
        mov     [last_word_], rbx
        _drop
        next
endcode

; ### swap
inline swap, 'swap'                     ; x1 x2 -- x2 x1
        _debug_?enough 2
        _swap
endinline

; ### drop
inline drop, 'drop'
        _debug_?enough_1
        _drop
endinline

; ### 2drop
inline twodrop, '2drop'
        _debug_?enough 2
        _2drop
endinline

; ### 3drop
inline threedrop, '3drop'
        _debug_?enough 3
        _3drop
endinline

; ### 4drop
inline fourdrop, '4drop'
        _debug_?enough 4
        _4drop
endinline

; ### dup
inline dup, 'dup'
        _debug_?enough_1
        _dup
endinline

; ### dupd
inline dupd, 'dupd'
        _debug_?enough 2
        _dupd
endinline

; ### 2dup
inline twodup, '2dup'                   ; x1 x2 -- x1 x2 x1 x2
        _debug_?enough 2
        _twodup
endinline

; ### 3dup
code threedup, '3dup'                   ; x1 x2 x3 -- x1 x2 x3 x1 x2 x3
        _debug_?enough 3
        lea     rbp, [rbp - BYTES_PER_CELL * 3]
        mov     [rbp + BYTES_PER_CELL * 2], rbx
        mov     rax, [rbp + BYTES_PER_CELL * 4]
        mov     [rbp + BYTES_PER_CELL], rax
        mov     rax, [rbp + BYTES_PER_CELL * 3]
        mov     [rbp], rax
        next
endcode

; ### rot
code rot, 'rot'                         ; x1 x2 x3 -- x2 x3 x1
        _debug_?enough 3
        mov     rax, [rbp]                      ; x2 in RAX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; x1 in RDX
        mov     [rbp + BYTES_PER_CELL], rax     ; x2
        mov     [rbp], rbx                      ; x3
        mov     rbx, rdx                        ; x1
        next
endcode

; ### -rot
code rrot, '-rot'                       ; x1 x2 x3 -- x3 x1 x2
        _debug_?enough 3
        mov     rax, [rbp]                      ; x2 in RAX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; x1 in RDX
        mov     [rbp + BYTES_PER_CELL], rbx     ; x3
        mov     [rbp], rdx                      ; x1
        mov     rbx, rax                        ; x2
        next
endcode

; ### over
inline over, 'over'
        _debug_?enough 2
        _over
endinline

; ### nip
inline nip, 'nip'                       ; x1 x2 -- x2
        _debug_?enough 2
        _nip
endinline

; ### tuck
code tuck, 'tuck'                       ; x1 x2 -- x2 x1 x2
        _debug_?enough 2
        _tuck
        next
endcode

; ### swapd
code swapd, 'swapd'                     ; x y z -- y x z
        _debug_?enough 3
        mov     rax, [rbp]
        mov     rdx, [rbp + BYTES_PER_CELL]
        mov     [rbp + BYTES_PER_CELL], rax
        mov     [rbp], rdx
        next
endcode

; ### 2nip
inline twonip, '2nip'                   ; x y z -- z
        _debug_?enough 3
        _2nip
endinline

; ### eq?                               ; x y -- ?
inline eq?, 'eq?'
        _eq?
endinline

; ### neq?
inline neq?, 'neq?'                     ; x y -> ?
        cmp     rbx, [rbp]
        mov     eax, TRUE
        mov     ebx, NIL
        cmovne  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### =
code feline_equal, '='                  ; x y -> ?
        _debug_?enough 2
        cmp     rbx, [rbp]
        jne     equal?
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     ebx, TRUE
        next
endcode

; ### as-boolean
inline as_boolean, 'as-boolean'         ; x -> ?
        _as_boolean
endinline

; ### not
inline not, 'not'                       ; x -> ?
        _not
endinline

; ### null?
inline null?, 'null?'                   ; x -> ?
        _not
endinline

; ### nil?                              ; x -> ?
inline nil?, 'nil?'
        _nil?
endinline

; ### <>
code not_equal, '<>'                    ; x y -> ?
        cmp     rbx, [rbp]
        jne     .1
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     ebx, NIL
        next
.1:
        _ equal?
        _not
        next
endcode

; ### zero?
inline zero?, 'zero?'
        _fixnum_zero?
endinline

; ### and
code feline_and, 'and'                  ; obj1 obj2 -> ?
        cmp     rbx, NIL
        je      .exit
        ; obj2 is not nil
        mov     rax, [rbp]
        cmp     rax, NIL
        cmove   rbx, rax
.exit:
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### or
inline feline_or, 'or'                  ; obj1 obj2 -> ?
        mov     rax, [rbp]
        cmp     rax, NIL
        cmovne  rbx, rax
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### if
code feline_if, 'if'                    ; ? quot1 quot2 ->
        cmp     qword [rbp + BYTES_PER_CELL], NIL
        mov     rdx, [rbp]              ; quot1 in rdx, quot2 in rbx
        cmovne  rbx, rdx                ; if condition is not nil, move quot1 into rbx
        _ callable_raw_code_address     ; rbx: ^code
        mov     rax, rbx
        _3drop
%ifdef DEBUG
        call    rax
        next
%else
        jmp     rax
%endif
endcode

; ### if*
code if_star, 'if*'                     ; ? quot1 quot2 ->
; Factor
; "If the condition is true, it is retained on the stack before the true
; quotation is called. Otherwise, the condition is removed from the stack
; and the false quotation is called."

        cmp     qword [rbp + BYTES_PER_CELL], NIL
        jne     .1
        ; condition is false
        ; rbx: quot2
        _ callable_raw_code_address
        mov     rax, rbx
        _3drop
%ifdef DEBUG
        call    rax
        next
%else
        jmp     rax
%endif
.1:
        ; condition is true
        ; drop quot2
        _drop                           ; rbx: quot1
        _ callable_raw_code_address
        mov     rax, rbx
        _drop
%ifdef DEBUG
        call    rax
        next
%else
        jmp     rax
%endif
endcode

; ### when
code when, 'when'                       ; x quotation -> ...
; If x is not nil, drop x, call the quotation, and return the
; results of the call.

; If x is nil, drop both x and the quotation. Return without
; calling the quotation.

        cmp     qword [rbp], NIL
        je      twodrop
        ; x is not nil
        _ callable_raw_code_address
        mov     rax, rbx
        _2drop
        jmp     rax
endcode

; ### when*
code when_star, 'when*'                 ; x quotation -> ...
; If x is not nil, keep x on the stack, call the quotation, and
; return the results of the call; x remains on the stack to be
; consumed or left on the stack by the call.

; If x is nil, drop both x and the quotation. Return without
; calling the quotation.

        cmp     qword [rbp], NIL
        je      twodrop

        ; x is not nil

        ; protect callable from gc
        push    rbx

        _ callable_raw_code_address
        mov     rax, rbx
        _drop
        call    rax

        ; drop callable
        pop     rax

        next
endcode

; ### unless
code unless, 'unless'                   ; x quotation -> ...
; If x is nil, drop x and call the quotation. Return the
; results of the call.

; If x is not nil, drop both x and the quotation. Return
; without calling the quotation.

        cmp     qword [rbp], NIL
        jne     twodrop
        ; x is nil
        _ callable_raw_code_address
        mov     rax, rbx
        _2drop
        jmp     rax
endcode

; ### unless*
code unless_star, 'unless*'             ; x quotation -> ...
; If x is not nil, keep x on the stack and drop the quotation.
; Return without calling the quotation.

; If x is nil, drop x and call the quotation. Return the
; results of the call.

; `x [ y ] unless*` is equivalent to `x [ ] [ y ] if*`

        cmp     qword [rbp], NIL
        jne     drop
        ; x is nil
        _ callable_raw_code_address
        mov     rax, rbx
        _2drop
        jmp     rax
endcode

; ### loop
code feline_loop, 'loop'        ; quotation ->
; call quotation repeatedly until it returns nil

        ; protect quotation from gc
        push    rbx

        push    r12
        _ callable_raw_code_address
        mov     r12, rbx
        _drop
.1:
        call    r12
        cmp     rbx, NIL
        _drop
        je      .exit
        jmp     .1
.exit:
        pop     r12

        ; drop quotation
        lea     rsp, [rsp + BYTES_PER_CELL]

        next
endcode

; ### until
code until, 'until'             ; pred body --
; call body until pred returns t

        ; protect quotations from gc
        push    rbx
        push    qword [rbp]

        push    r12
        push    r13
        _ callable_raw_code_address
        mov     r13, rbx
        _drop
        _ callable_raw_code_address
        mov     r12, rbx
        _drop
.1:
        call    r12
        cmp     rbx, NIL
        _drop
        jne     .exit
        call    r13
        jmp     .1
.exit:
        pop     r13
        pop     r12

        ; drop quotations
        lea     rsp, [rsp + BYTES_PER_CELL * 2]

        next
endcode

; ### while
code while, 'while'             ; predicate body ->
; call body until predicate returns nil

        ; protect quotations from gc
        push    rbx
        push    qword [rbp]

        push    r12
        push    r13
        _ callable_raw_code_address
        mov     r13, rbx        ; r13: body
        mov     rbx, [rbp]
        _ callable_raw_code_address
        mov     r12, rbx        ; r12: predicate
        _2drop

        jmp     .entry

        align   DEFAULT_CODE_ALIGNMENT
.top:
        ; call body
        call    r13

        cmp     qword [stop_for_gc?_], NIL
        je      .entry
        _ safepoint_stop

.entry:
        ; call predicate
        call    r12
        cmp     rbx, NIL
        _drop
        jne     .top

.exit:
        pop     r13
        pop     r12

        ; drop quotations
        lea     rsp, [rsp + BYTES_PER_CELL * 2]

        next
endcode

; ### char-escape-char
code char_escape_char, 'char-escape-char'       ; tagged-char1 -> tagged-char2/nil

        _quote `\a\b\t\n\v\f\r\e '\0'`
        _ string_index
        _dup
        _tagged_if .1
        _quote `abtnvfres'0`
        _ string_nth_unsafe
        _then .1

        next
endcode

; ### char-unescape-char
code char_unescape_char, 'char-unescape-char'   ; tagged-char1 -> tagged-char2/nil

        _quote `abtnvfres"'0\\`
        _ string_index
        _dup
        _tagged_if .1
        _quote `\a\b\t\n\v\f\r\e "'\0'\\`
        _ string_nth_unsafe
        _then .1

        next
endcode

; ### token-character-literal?
code token_character_literal?, 'token-character-literal?'       ; string -> char/string t/nil
        _dup
        _ string_length                 ; ->  string length
        cmp     rbx, tagged_fixnum(3)
        jb      .fail
        _over
        _ string_first_char
        cmp     rbx, tagged_char(0x27)
        _drop
        jne     .fail
        _over
        _ string_last_char
        cmp     rbx, tagged_char(0x27)
        _drop
        jne     .fail

        ; reaching here, length is at least 3
        ; first and last chars are single quotes
        cmp     rbx, tagged_fixnum(3)
        je      .length_is_3
        cmp     rbx, tagged_fixnum(4)
        je      .length_is_4
        cmp     rbx, tagged_fixnum(6)
        je      .length_is_6

.fail:
        _drop
        _nil
        next

.length_is_3:
        _drop                           ; -> string
        _tagged_fixnum(1)
        _swap
        _ string_nth_unsafe
        _true
        next

.length_is_4:
        _drop                           ; -> string
        _tagged_fixnum(1)
        _over
        _ string_nth_unsafe
        cmp     rbx, tagged_char('\')
        jne     .fail
        _drop
        _tagged_fixnum(2)
        _over
        _ string_nth_unsafe             ; -> string char
        _ char_unescape_char
        _dup
        _tagged_if .1
        _nip
        _true
        _else .1
        _drop
        _nil
        _then .1

        next

.length_is_6:
        _drop                           ; -> string
        _tagged_fixnum(1)
        _over
        _ string_nth_unsafe
        cmp     rbx, tagged_char('\')
        jne     .fail
        _drop
        _tagged_fixnum(2)
        _over
        _ string_nth_unsafe
        cmp     rbx, tagged_char('x')
        jne     .fail
        _drop                           ; -> string
        _tagged_fixnum(3)
        _tagged_fixnum(5)
        _pick
        _ string_substring
        _ hex_to_integer
        cmp     rbx, NIL
        jne     .ok
        next
.ok:
        _code_char
        _nip
        _true
        next
endcode

; ### token-string-literal?
code token_string_literal?, 'token-string-literal?' ; token -> string t | token nil
        _dup
        _ string_length
        _lit tagged_fixnum(2)
        _ fixnum_fixnum_lt
        _tagged_if .1
        _nil
        next
        _then .1

        _lit tagged_zero
        _over
        _ string_nth
        _lit '"'
        _tag_char
        _equal
        _zeq_if .2
        _nil
        next
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
        _nil
        next
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

        _true

        next
endcode

; ### times
code times_, 'times'                    ; tagged-fixnum quotation --

        ; protect quotation from gc
        push    rbx

        _ callable_raw_code_address     ; -- tagged-fixnum code-address

        _swap
        _check_fixnum                   ; -- code-address n

        push    r12
        mov     r12, rbx                ; n in r12
        push    r13
        mov     r13, [rbp]              ; address to call in r13
        _2drop                          ; clean up the stack now!

        test    r12, r12
        jle     .exit

        align   DEFAULT_CODE_ALIGNMENT
.top:
        cmp     qword [stop_for_gc?_], NIL
        je      .continue
        _ safepoint_stop
.continue:
        call    r13
        dec     r12
        jz      .exit
        call    r13
        dec     r12
        jnz     .top
.exit:
        pop     r13
        pop     r12

        ; drop quotation
        pop     rax

        next
endcode

; ### each-integer
code each_integer, 'each-integer'       ; n quot ->
        ; verify that n is a fixnum
        mov     rax, [rbp]
        test    al, FIXNUM_TAG
        jz      error_not_fixnum_rax

        ; protect quotation from gc
        push    rbx

        _ callable_raw_code_address     ; -> tagged-fixnum raw-code-address

        push    r12
        push    r13
        push    r15
        mov     r12, tagged_zero
        mov     r13, rbx                ; code address in r13
        mov     r15, [rbp]              ; loop limit in r15
        _2drop                          ; clean up the stack now!
        cmp     r15, tagged_zero
        jle     .2

        align DEFAULT_CODE_ALIGNMENT
.1:
        _dup
        mov     rbx, r12
        call    r13
        add     r12, 2
        cmp     r12, r15
        je     .2
        _dup
        mov     rbx, r12
        call    r13
        add     r12, 2
        cmp     r12, r15
        je     .2
        _dup
        mov     rbx, r12
        call    r13
        add     r12, 2
        cmp     r12, r15
        jne     .1

.2:
        pop     r15
        pop     r13
        pop     r12

        ; drop quotation
        pop     rax

        next
endcode

; ### all-integers?
code all_integers?, 'all-integers?'     ; n quot -- ?
        ; check that n is a fixnum
        mov     al, byte [rbp]
        and     al, FIXNUM_TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     error_not_fixnum

        ; untag n
        _untag_fixnum qword [rbp]

        ; protect quotation from gc
        push    rbx

        _ callable_raw_code_address     ; -- untagged-fixnum code-address

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
        cmp     rbx, NIL
        je      .2
        _drop
        inc     r12
        cmp     r12, r15
        jne     .1
        _dup
        mov     rbx, TRUE
.2:
        pop     r15
        pop     r13
        pop     r12

        ; drop quotation
        pop     rax

        next
endcode

; ### find-integer
code find_integer, 'find-integer'       ; fixnum callable -> fixnum/nil
; callable must have stack effect fixnum -> ?

        _swap
        _check_fixnum

        test    rbx, rbx
        jg      .1
        mov     rbx, NIL
        _nip
        next

.1:
        _tag_fixnum
        _swap                           ; -> fixnum callable

        ; protect callable from gc
        push    rbx

        push    r12
        push    r13
        push    r15

        mov     r12, tagged_zero        ; tagged loop index in r12

        _ callable_raw_code_address
        mov     r13, rbx                ; code address in r13
        mov     r15, [rbp]              ; tagged loop limit in r15
        _2drop                          ; clean up the stack now
        _dup                            ; dup outside the loop
        jmp     .2                      ; jump over alignment padding

        align   DEFAULT_CODE_ALIGNMENT
.2:
        mov     rbx, r12                ; tagged index in rbx

        call    r13
        ; test flag returned by quotation
        cmp     rbx, NIL
        jne     .3
        ; flag was nil
        ; keep going
        add     r12, (1 << FIXNUM_TAG_BITS)
        cmp     r12, r15
        jne     .2
        ; reached end
        ; return nil
        mov     ebx, NIL
        jmp     .4

.3:
        ; return tagged index
        mov     rbx, r12

.4:
        pop     r15
        pop     r13
        pop     r12

        ; drop callable
        pop     rax

        next
endcode

; ### find-integer-in-range
code find_integer_in_range, 'find-integer-in-range' ; start end callable -> fixnum/nil
; callable must have stack effect fixnum -> ?

        ; start
        mov     rax, [rbp + BYTES_PER_CELL]
        test    al, FIXNUM_TAG
        jz      error_not_fixnum_rax
        _untag_fixnum rax               ; start (untagged) in rax

        ; end
        mov     rdx, [rbp]
        test    dl, FIXNUM_TAG
        jz      error_not_fixnum_rdx
        _untag_fixnum rdx               ; end (untagged) in rdx

        ; make sure start is before end
        cmp     rdx, rax
        jg      .1
        _2drop
        mov     ebx, NIL
        next

.1:
        ; protect callable from gc
        push    rbx

        push    r12
        push    r13
        push    r15

        mov     r12, rax                ; loop index in r12
        mov     r15, rdx                ; loop limit in r15

        _ callable_raw_code_address
        mov     r13, rbx                ; code address in r13

        _3drop                          ; clean up the stack now!
.2:
        pushd   r12
        _tag_fixnum
        call    r13
        ; test flag returned by quotation
        cmp     rbx, NIL
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jne     .3
        ; flag was nil
        ; keep going
        inc     r12
        cmp     r12, r15
        jne     .2
        ; reached end
        ; return nil
        _nil
        jmp     .4
.3:
        ; return tagged index
        pushd   r12
        _tag_fixnum
.4:
        pop     r15
        pop     r13
        pop     r12

        ; drop callable
        pop     rax

        next
endcode

; ### find-last-integer-in-range
code find_last_integer_in_range, 'find-last-integer-in-range' ; start end callable -> i/nil
; callable must have stack effect ( i -> ? )

; Applies the callable to each integer from end - 1 down to start. If the
; callable returns a true value for some integer in the specified range,
; iteration stops and that integer is returned. Otherwise the word returns nil.

        ; start
        mov     rax, [rbp + BYTES_PER_CELL]
        test    al, FIXNUM_TAG
        jz      error_not_fixnum_rax
        _untag_fixnum rax               ; start (untagged) in rax

        ; end
        mov     rdx, [rbp]
        test    dl, FIXNUM_TAG
        jz      error_not_fixnum_rdx
        _untag_fixnum rdx               ; end (untagged) in rdx

        ; make sure start is before end
        cmp     rdx, rax
        jg      .1
        _2drop
        mov     ebx, NIL
        next

.1:
        ; protect callable from gc
        push    rbx

        push    r12
        push    r13
        push    r15

        sub     rdx, 1
        mov     r12, rdx                ; end - 1 (starting loop index) in r12
        mov     r15, rax                ; start (loop limit) in r15

        _ callable_raw_code_address
        mov     r13, rbx                ; code address in r13

        _3drop                          ; clean up the stack now!
.2:
        pushd   r12
        _tag_fixnum
        call    r13
        ; test flag returned by quotation
        cmp     rbx, NIL
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jne     .3
        ; flag was nil
        ; keep going as long as loop index >= start
        dec     r12
        cmp     r12, r15
        jge     .2
        ; reached start of range
        ; return nil
        _nil
        jmp     .4
.3:
        ; return tagged index
        pushd   r12
        _tag_fixnum
.4:
        pop     r15
        pop     r13
        pop     r12

        ; drop callable
        pop     rax

        next
endcode

; ### depth
code depth, 'depth'                     ; -- fixnum
        _depth
        _tag_fixnum
        next
endcode

; ### get-datastack
code get_datastack, 'get-datastack'     ; -> array

        _ current_thread_raw_sp0        ; -> raw-sp0
        mov     rcx, rbx                ; rcx = raw sp0
        sub     rbx, rbp                ; rbx = raw depth (number of bytes)
        shr     rbx, 3                  ; rbx = raw depth (number of cells)

        ; subtract 1 since we've put an extra item on the stack
        sub     rbx, 1                  ; rbx = raw depth (number of cells)

        push    rcx                     ; save rcx = raw sp0

        _tag_fixnum
        _ make_array_1

        pop     rcx                     ; restore rcx = raw sp0

        push    rbx                     ; save array handle

        _handle_to_object_unsafe

        push    this_register
        mov     this_register, rbx

        mov     rbx, rcx                ; rbx = raw sp0

        sub     rcx, BYTES_PER_CELL

        sub     rbx, rbp
        shr     rbx, 3
        sub     rbx, 1                  ; -> raw-depth

        _dup
        _register_do_times .1

        sub     rcx, BYTES_PER_CELL
        mov     rax, [rcx]

        mov     [this_register + ARRAY_DATA_OFFSET + index_register * 8], rax

        _loop .1

        pop     this_register

        pop     rbx                     ; -> handle

        next
endcode

; ### clear
code clear, 'clear'                     ; ??? --
; clear the current thread's data stack
        _ current_thread_raw_sp0_rax
        mov     rbp, rax
        next
endcode

; ### number>string
code number_to_string, 'number>string'  ; n -- string
        test    bl, FIXNUM_TAG
        jnz     fixnum_to_string

        _dup
        _ object_raw_typecode
        mov     rax, rbx
        _drop

        cmp     rax, TYPECODE_INT64
        je      int64_to_string
        cmp     rax, TYPECODE_UINT64
        je      uint64_to_string
        cmp     rax, TYPECODE_FLOAT
        je      float_to_string

        _ error_not_number

        next
endcode

; ### dec.
code decimal_dot, 'dec.'                ; n --
        _ number_to_string
        _ write_string
        next
endcode

; ### dec.r
code decimal_dot_r, 'dec.r'             ; n width -> void
        _check_fixnum
        _swap
        _ number_to_string              ; -> raw-width string
        push    rbx
        _ string_raw_length             ; -> raw-width raw-length
        _minus
        js      .1
        _tag_fixnum
        _ spaces
        _dup
.1:
        pop     rbx
        _ write_string
        next
endcode

; ### >hex
code to_hex, '>hex'                     ; n -- string
        _dup
        _fixnum?_if .1
        _ fixnum_to_hex
        next
        _then .1

        _ error_not_number

        next
endcode

; ### hex.
code hexdot, 'hex.'                     ; x -> void

        test    bl, FIXNUM_TAG
        jz      .1
        _untag_fixnum
        _ raw_int64_to_hex
        jmp     .4

.1:
        _dup
        _ uint64?
        _tagged_if .2
        _ uint64_to_hex
        jmp     .4
        _then .2

        _dup
        _ int64?
        _tagged_if .3
        _ int64_to_hex
        jmp     .4
        _then .3

        _error "unsupported"
        next

.4:
        _quote "0x"
        _ write_string
        _ write_string

        next
endcode

; ### raw.
code rawdot, 'raw.'                     ; x -> void
        _ normalize_unsigned
        _ hexdot
        next
endcode

; ### bin.
code bindot, 'bin.'                     ; n --
        _ fixnum_to_binary
        _quote "0b"
        _ write_string
        _ write_string
        next
endcode

; ### pick
inline pick, 'pick'                     ; x y z -- x y z x
; This is the Factor/Feline version of pick.
; The Forth version is different.
        _pick
endinline

; ### 2over
code feline_2over, '2over'              ; x y z -- x y z x y
; This is the Factor/Feline version of 2over.
; The Forth version is different.
        mov     [rbp - BYTES_PER_CELL], rbx     ; z
        mov     rax, [rbp + BYTES_PER_CELL]     ; x
        mov     rbx, [rbp]                      ; y
        mov     [rbp - BYTES_PER_CELL * 2], rax
        lea     rbp, [rbp - BYTES_PER_CELL * 2]
        next
endcode

%ifdef WIN64
_global standard_output_handle
_global error_output_handle
%endif

asm_global last_char_, 10

_global output_column

; ### c@
code cfetch, 'c@'       ; address -- unsigned-byte
        _check_fixnum
        _cfetch
        _tag_fixnum
        next
endcode

; ### c@s
code cfetchs, 'c@s'     ; address -- signed-byte
        _check_fixnum
        movsx   rbx, byte [rbx]
        _tag_fixnum
        next
endcode

; ### w@
code wfetch, 'w@'       ; address -- uint16
        _check_fixnum
        _wfetch
        _tag_fixnum
        next
endcode

; ### l@
code lfetch, 'l@'       ; address -- uint32
        _check_fixnum
        mov     ebx, [rbx]
        _tag_fixnum
        next
endcode

; ### l@s
code lfetchs, 'l@s'     ; address -- int32
        _check_fixnum
        movsxd  rbx, dword [rbx]
        _tag_fixnum
        next
endcode

; ### @
code fetch, '@'                         ; address -- uint64
        _check_fixnum
        _fetch
        _ new_uint64
        next
endcode

; ### c!
code cstore, 'c!'                       ; byte address --
        _check_index
        _swap
        _check_fixnum
        _swap
        mov     al, [rbp]
        mov     [rbx], al
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        next
endcode

; ### l!
code lstore, 'l!'                       ; dword tagged-address --
        _check_index
        _swap
        _ integer_to_raw_bits
        _swap
        mov     eax, [rbp]
        mov     [rbx], eax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        next
endcode

; ### !
code store, '!'                         ; qword tagged-address --
        _check_index
        _swap
        _ integer_to_raw_bits
        _swap
        mov     rax, [rbp]
        mov     [rbx], rax
        mov     rbx, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        next
endcode

; ### copy_bytes
subroutine copy_bytes
; arg0_register: untagged source address
; arg1_register: untagged destination address
; arg2_register: untagged count
; does not support overlapping moves
        test    arg2_register, arg2_register
        jle     .1
        xor     eax, eax
.2:
        movzx   r10d, byte [arg0_register + rax]
        mov     [arg1_register + rax], r10b
        add     rax, 1
        cmp     arg2_register, rax
        jne     .2
.1:
        ret
endsub

; ### unsafe-copy-bytes
code unsafe_copy_bytes, 'unsafe-copy-bytes' ; source destination count -> void
; does not support overlapping moves
        _check_fixnum
        mov     arg2_register, rbx      ; count
        _drop
        _check_fixnum
        mov     arg1_register, rbx      ; destination
        _drop
        _check_fixnum
        mov     arg0_register, rbx      ; source
        _drop
        _ copy_bytes
        next
endcode

; ### copy_cells
subroutine copy_cells
; arg0_register: untagged source address
; arg1_register: untagged destination address
; arg2_register: untagged count
; does not support overlapping moves
        test    arg2_register, arg2_register
        je      .1
        xor     eax, eax
.2:
        mov     r10, [arg0_register + rax * BYTES_PER_CELL]
        mov     [arg1_register + rax * BYTES_PER_CELL], r10
        add     rax, 1
        cmp     arg2_register, rax
        jne     .2
.1:
        ret
endsub

; ### fill_cells
subroutine fill_cells
; arg0_register: untagged address
; arg1_register: x
; arg2_register: untagged count
        test    arg2_register, arg2_register
        jz      .exit
        sub     arg2_register, 1
        align   DEFAULT_CODE_ALIGNMENT
.top:
        mov     [arg0_register + arg2_register * BYTES_PER_CELL], arg1_register
        sub     arg2_register, 1
        js      .exit
        mov     [arg0_register + arg2_register * BYTES_PER_CELL], arg1_register
        sub     arg2_register, 1
        js      .exit
        mov     [arg0_register + arg2_register * BYTES_PER_CELL], arg1_register
        sub     arg2_register, 1
        js      .exit
        mov     [arg0_register + arg2_register * BYTES_PER_CELL], arg1_register
        sub     arg2_register, 1
        jns     .top
.exit:
        _rep_return
endsub

; ### char-lower-case?
code char_lower_case?, 'char-lower-case?' ; char -> char/nil
        _verify_char
        mov     rax, rbx
        mov     edx, NIL
        shr     rax, CHAR_TAG_BITS
        sub     rax, 'a'
        cmp     rax, 25
        cmova   rbx, rdx
        next
endcode

; ### char-upper-case?
code char_upper_case?, 'char-upper-case?' ; char -> char/nil
        _verify_char
        mov     rax, rbx
        mov     edx, NIL
        shr     rax, CHAR_TAG_BITS
        sub     rax, 'A'
        cmp     rax, 25
        cmova   rbx, rdx
        next
endcode

; ### char-downcase
code char_downcase, 'char-downcase'
        _verify_char
        mov     rax, rbx
        shr     rax, CHAR_TAG_BITS
        sub     rax, 'A'
        cmp     rax, 25
        ja      .1
        ; char is upper case
        or      rbx, 0x2000
.1:
        next
endcode

; ### char-upcase
code char_upcase, 'char-upcase'
        _verify_char
        mov     rax, rbx
        shr     rax, CHAR_TAG_BITS
        sub     rax, 'a'
        cmp     rax, 25
        ja      .1
        ; char is lower case
        and     rbx, 0xdfff
.1:
        next
endcode

; ### char-ci=?
code char_ci_equal?, 'char-ci=?'        ; x y -> ?
        cmp     bl, CHAR_TAG
        jne     error_not_char
        _swap
        cmp     bl, CHAR_TAG
        jne     error_not_char
        cmp     rbx, [rbp]
        jne     .1
        _nip
        mov     ebx, TRUE
        next
.1:
        shr     rbx, CHAR_TAG_BITS      ; bl: x (raw 8-bit char)
        sub     bl, 'A'
        cmp     bl, 25
        ja      .2
        ; char is upper case
        or      bl, 0x20
.2:
        mov     rax, [rbp]
        shr     rax, CHAR_TAG_BITS      ; bl: y (raw 8-bit char)
        sub     al, 'A'
        cmp     al, 25
        ja      .3
        ; char is upper case
        or      al, 0x20
.3:
        cmp     al, bl
        mov     eax, TRUE
        mov     ebx, NIL
        cmove   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### binary-digit?
code binary_digit?, 'binary-digit?'     ; char -> n/nil
        _check_char
        cmp     ebx, '0'
        jne     .1
        mov     ebx, tagged_zero
        next
.1:
        cmp     ebx, '1'
        jne     .2
        mov     ebx, tagged_fixnum(1)
        next
.2:
        mov     ebx, NIL
        next
endcode

; ### hex-digit?
code hex_digit?, 'hex-digit?'           ; char -- n/nil
        _ char_upcase
        _check_char
        cmp     ebx, '0'
        jl      .1
        cmp     ebx, '9'
        jg      .1
        sub     ebx, '0'
        _tag_fixnum
        next
.1:
        cmp     ebx, 'A'
        jl      .2
        cmp     ebx, 'F'
        jg      .2
        sub     ebx, 'A' - 10
        _tag_fixnum
        next
.2:
        mov     ebx, NIL
        next
endcode

; ### digit?
code digit?, 'digit?'                   ; char -- n/nil
        _check_char
        cmp     ebx, '0'
        jl      .1
        cmp     ebx, '9'
        jg      .1
        sub     ebx, '0'
        _tag_fixnum
        next
.1:
        mov     ebx, NIL
        next
endcode

; ### base>integer
code base_to_integer, 'base>integer'    ; string base -- n/nil

        _check_fixnum           ; -- string raw-base

        _swap
        _ string_from           ; -- raw-base raw-data-address raw-length

        mov     arg0_register, [rbp]                    ; raw data address
        mov     arg1_register, rbx                      ; raw length
        mov     arg2_register, [rbp + BYTES_PER_CELL]   ; raw base

        _2nip

        xcall   c_string_to_integer

        mov     rbx, rax
        cmp     rax, NIL
        je      .1

        and     al, FIXNUM_TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     new_handle

.1:
        _rep_return
endcode

; ### hex>integer
code hex_to_integer, 'hex>integer'      ; string -> n/nil
        _lit tagged_fixnum(16)
        _ base_to_integer
        next
endcode

; ### binary>integer
code binary_to_integer, 'binary>integer' ; string -> n/nil
        _lit tagged_fixnum(2)
        _ base_to_integer
        next
endcode

; ### string>number
code string_to_number, 'string>number'  ; string -> n/nil
        _dup
        _ string_empty?
        _tagged_if .1
        mov     ebx, NIL
        next
        _then .1

        _quote "0x"
        _over
        _ string_has_prefix?
        cmp     rbx, NIL
        _drop
        jne     hex_to_integer

        _quote "-0x"
        _over
        _ string_has_prefix?
        cmp     rbx, NIL
        _drop
        jne     hex_to_integer

        _quote "0b"
        _over
        _ string_has_prefix?
        _tagged_if .2
        _lit tagged_fixnum(2)
        _swap
        _ string_tail
        _ binary_to_integer
        next
        _then .2

        _quote "-0b"
        _over
        _ string_has_prefix?
        _tagged_if .3
        _lit tagged_fixnum(3)
        _swap
        _ string_tail
        _ binary_to_integer
        _ generic_negate
        next
        _then .3

        _ decimal_to_number

        next
endcode

; ### string->index
code string_to_index, 'string->index'   ; string -> index/nil
        _ string_to_number
        cmp     rbx, NIL
        je      .1
        test    bl, FIXNUM_TAG
        jz      .2
        test    rbx, rbx
        js      .2
.1:
        next
.2:
        mov     ebx, NIL
        next
endcode

; ### decimal>number
code decimal_to_number, 'decimal>number'        ; string -- n/nil
        _duptor
        _ string_first_char
        _eq? tagged_char('-')
        _tagged_if .1
        _rfetch
        _ decimal_to_signed
        _else .1
        _rfetch
        _ decimal_to_unsigned
        _then .1                        ; -- n/nil

        _dup
        _tagged_if .2
        _rdrop
        next
        _then .2

        ; not an integer
        _drop
        _rfrom
        _ string_to_float
        next
endcode

; ### decimal>unsigned
code decimal_to_unsigned, 'decimal>unsigned'    ; string -- unsigned/nil

        _ check_string

        ; return nil if string is empty
        _dup
        _string_raw_length
        test    rbx, rbx
        _drop
        jnz     .1
        mov     ebx, NIL
        next
.1:

        push    this_register
        popd    this_register           ; --

        _zero                           ; -- accum

        _this_string_raw_length
        _register_do_times .loop

        mov     eax, 10
        mul     rbx

        jno     .no_overflow
        _unloop
        pop     this_register
        mov     ebx, NIL
        next

.no_overflow:
        mov     rbx, rax

        _raw_loop_index
        _this_string_nth_unsafe         ; -- accum untagged-char
        sub     ebx, '0'                ; 0 <= ebx <= 9 if valid decimal digit
        cmp     ebx, 10
        jb      .2                      ; unsigned comparison
        _nip
        _unloop
        pop     this_register
        mov     ebx, NIL
        next
.2:
        add     qword [rbp], rbx

        jnc     .no_carry
        _nip
        _unloop
        pop     this_register
        mov     ebx, NIL
        next

.no_carry:
        _drop
        _loop .loop

        pop     this_register           ; -- raw-int64

        _ normalize_unsigned

        next
endcode

; ### decimal>signed
code decimal_to_signed, 'decimal>signed'        ; string -- signed/nil

        _ check_string

        _dup
        _string_raw_length
        cmp     rbx, 2
        _drop
        jge     .1
        mov     ebx, NIL
        next

.1:
        _dup
        _string_first_unsafe
        cmp     rbx, '-'
        _drop
        je      .2
        mov     ebx, NIL
        next

.2:
        push    this_register
        popd    this_register           ; --

        _zero                           ; -- accum

        _this_string_raw_length
        _lit 1
        _register_do_range .loop

        imul    rbx, 10

        jno     .no_overflow
        _unloop
        pop     this_register
        mov     ebx, NIL
        next

.no_overflow:
        _raw_loop_index
        _this_string_nth_unsafe         ; -- accum untagged-char

        sub     ebx, '0'                ; 0 <= ebx <= 9 if valid decimal digit
        cmp     ebx, 10
        jb      .3                      ; unsigned comparison
        _nip
        _unloop
        pop     this_register
        mov     ebx, NIL
        next
.3:
        add     qword [rbp], rbx

        ; if sign flag is not set, addition did not overflow
        jns     .no_carry

        ; sign flag is set

        ; MOST_NEGATIVE_INT64 is a special case
        ; if this is not the last time through the loop, the next imul will overflow
        mov     rax, MOST_NEGATIVE_INT64        ; 0x8000000000000000
        cmp     qword [rbp], rax
        je      .no_carry

        ; not MOST_NEGATIVE_INT64
        _nip
        _unloop
        pop     this_register
        mov     ebx, NIL
        next

.no_carry:
        _drop
        _loop .loop

        pop     this_register           ; -- raw-int64

        ; MOST_NEGATIVE_INT64 is a special case
        ; we don't need to negate it
        mov     rax, MOST_NEGATIVE_INT64
        cmp     rbx, rax
        je      new_int64

        neg     rbx

        mov     rax, MOST_NEGATIVE_FIXNUM
        cmp     rbx, rax
        jl      new_int64

        _tag_fixnum

        next
endcode

; ### printable-char?
code printable_char?, 'printable-char?' ; x -- ?
        cmp     bl, CHAR_TAG
        jne     .1
        cmp     rbx, tagged_char(32)
        jl      .1
        cmp     rbx, tagged_char(126)
        jg      .1
        next
.1:
        mov     ebx, NIL
        next
endcode

; ### code-char
code code_char, 'code-char'             ; tagged_fixnum -> tagged-char
        test    bl, FIXNUM_TAG
        jz      error_not_fixnum
        _code_char
        next
endcode

; ### char-code
code char_code, 'char-code'             ; tagged-char -> tagged-fixnum
        cmp     bl, CHAR_TAG
        jne     error_not_char
        _char_code
        next
endcode

; ### char?
inline char?, 'char?'                   ; x -> x/nil
; If x is a char, returns x unchanged.
; If x is not a char, returns nil.
        cmp     bl, CHAR_TAG
        mov     eax, NIL
        cmovne  ebx, eax
endinline

; ### verify-char
code verify_char, 'verify-char'         ; x -> char
        _verify_char
        next
endcode

; ### char-hashcode
inline char_hashcode, 'char-hashcode'   ; tagged-char -- tagged-fixnum
        ; REVIEW collisions with fixnums
        _char_code
endinline

; ### whitespace?
code whitespace?, 'whitespace?'         ; x -> ?
; return t if x is a space or tab character
; otherwise return nil (no error if x is not a character)
        cmp     rbx, tagged_char(32)
        jne     .1
        mov     ebx, TRUE
        next
.1:
        cmp     rbx, tagged_char(9)
        mov     ebx, NIL
        mov     eax, TRUE
        cmove   ebx, eax
        next
endcode

; ### char>string
code char_to_string, 'char>string'      ; tagged-char -- string

        _verify_char

        ; space char is a special case
        _dup
        _tagged_char(' ')
        _eq?
        _tagged_if .1
        _drop
        _quote "'\s'"
        next
        _then .1

        _lit 3
        _ new_sbuf_untagged
        _tor

        _lit tagged_char("'")
        _rfetch
        _ sbuf_push                     ; -- tagged-char

        _dup
        _ char_escape_char
        _dup
        _tagged_if .4
        _nip
        _lit tagged_char('\')
        _rfetch
        _ sbuf_push
        _rfetch
        _ sbuf_push
        jmp     .5
        _else .4
        _drop
        _then .4

        _dup
        _ printable_char?
        _tagged_if .2

        _rfetch
        _ sbuf_push

        _else .2

        _quote '\x'
        _rfetch
        _ sbuf_append_string            ; -- tagged-char

        _char_code
        _ fixnum_to_hex                 ; -- string

        _dup
        _ string_raw_length
        cmp     rbx, 1
        _drop
        jne     .3
        _lit tagged_char('0')
        _rfetch
        _ sbuf_push
.3:
        _rfetch
        _ sbuf_append_string

        _then .2

.5:
        _lit tagged_char("'")
        _rfetch
        _ sbuf_push

        _rfrom
        _ sbuf_to_string

        next
endcode

; ### free
code feline_free, 'free'                ; addr --
; Argument is untagged.
        mov     arg0_register, rbx
        _drop
        xcall   os_free                 ; "The free() function returns no value."
        next
endcode

asm_global terminal_rows_

; ### terminal-rows
code terminal_rows, 'terminal-rows'
        _dup
        mov     rbx, [terminal_rows_]
        _tag_fixnum
        next
endcode

asm_global terminal_columns_

; ### terminal-columns
code terminal_columns, 'terminal-columns'
        _dup
        mov     rbx, [terminal_columns_]
        _tag_fixnum
        next
endcode

; ### seed-random
code seed_random, 'seed-random'         ; --

        ; REVIEW
        _rdtsc

        mov     arg0_register, rbx
        _drop
        xcall   c_seed_random
        next
endcode

; ### random-fixnum
code random_fixnum, 'random-fixnum'     ; -- fixnum
        xcall   c_random
        _dup
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### random-int64
code random_int64, 'random-int64'       ; -- int64
        xcall   c_random
        _dup
        mov     rbx, rax
        _ new_int64
        next
endcode

; ### random-uint64
code random_uint64, 'random-uint64'     ; -- uint64
        xcall   c_random
        _dup
        mov     rbx, rax
        _ new_uint64
        next
endcode

; ### expt
code expt, 'expt'                       ; base power -- result

        _dup_fixnum?_if .1
        _ fixnum_to_float
        _then .1
        _ check_float

        _swap

        _dup_fixnum?_if .2
        _ fixnum_to_float
        _then .2
        _ check_float                   ; -> power base

        mov     arg0_register, rbx
        mov     arg1_register, [rbp]
        _drop
        xcall   c_float_expt
        mov     rbx, rax

        _ new_handle

        next
endcode

; ### win64?
inline win64?, 'win64?'                 ; void -> ?
%ifdef WIN64
        _true
%else
        _nil
%endif
endinline

; ### linux?
inline linux?, 'linux?'                 ; void -> ?
%ifdef WIN64
        _nil
%else
        _true
%endif
endinline

; ### debug?
inline debug?, 'debug?'                 ; void -> ?
%ifdef DEBUG
        _true
%else
        _nil
%endif
endinline

; ### get-environment-variable
code get_environment_variable, 'get-environment-variable' ; name -- value
        _ string_raw_data_address
%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_getenv
        pushd   rbx
        mov     rbx, rax
        pushd   rbx
        test    rbx, rbx
        jz      .1
        _ zstrlen
        jmp     .2
.1:
        xor     ebx, ebx
.2:
        _ copy_to_string
        next
endcode

; ### bye
code bye, "bye"

        _ interactive?
        _ get
        _tagged_if .1
        _ ?nl
        _ output_style
        _ show_cursor
        _write `Bye!\n`
        _then .1

        xcall os_bye

        next
endcode
