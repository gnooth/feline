; Copyright (C) 2016-2017 Peter Graves <gnooth@gmail.com>

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

asm_global last_word_, f_value

; ### last-word
code last_word, 'last-word'             ; -- word
        pushrbx
        mov     rbx, [last_word_]
        next
endcode

; ### set-last-word
code set_last_word, 'set-last-word'     ; word --
        mov     [last_word_], rbx
        poprbx
        next
endcode

; ### swap
inline swap, 'swap'                     ; x1 x2 -- x2 x1
        _debug_?enough 2
        _swap
endinline

; ### drop
inline drop, 'drop'
        _debug_?enough 1
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
        _debug_?enough 1
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

; ### eq?                               ; obj1 obj2 -- ?
inline eq?, 'eq?'
        _eq?
endinline

; ### =
code feline_equal, '='                  ; obj1 obj2 -- ?
        cmp     rbx, [rbp]
        jne     .1
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     ebx, t_value
        _return
.1:
        _ equal?
        next
endcode

%macro  _not 0
        mov     eax, t_value
        cmp     rbx, f_value
        mov     ebx, f_value
        cmove   ebx, eax
%endmacro

; ### not
inline not, 'not'
        _not
endinline

; ### <>
code not_equal, '<>'                    ; obj1 obj2 -- ?
        cmp     rbx, [rbp]
        jne     .1
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     ebx, f_value
        _return
.1:
        _ equal?
        _not
        next
endcode

; ### zero?
inline zero?, 'zero?'
        mov     eax, t_value
        cmp     rbx, tagged_zero
        mov     ebx, f_value
        cmovz   ebx, eax
endinline

; ### and
code feline_and, 'and'                  ; obj1 obj2 -- ?
        cmp     rbx, f_value
        je      .exit
        ; obj2 is not f
        mov     rax, [rbp]
        cmp     rax, f_value
        cmove   rbx, rax
.exit:
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### or
code feline_or, 'or'                    ; obj1 obj2 -- ?
        mov     rax, [rbp]
        cmp     rax, f_value
        cmovne  rbx, rax
        lea     rbp, [rbp + BYTES_PER_CELL]
        next
endcode

; ### if
code feline_if, 'if'                    ; ? true false --
        mov     rax, [rbp + BYTES_PER_CELL] ; condition in rax
        mov     rdx, [rbp]              ; true quotation in rdx, false quotation in rbx
        cmp     rax, f_value
        cmovne  rbx, rdx                ; if condition is not f, move true quotation into rbx
        _ callable_raw_code_address     ; code address in rbx
        mov     rax, rbx
        _3drop
        call    rax
        next
endcode

; ### if*
code if_star, 'if*'                     ; ? true false --
; Factor
; "If the condition is true, it is retained on the stack before the true
; quotation is called. Otherwise, the condition is removed from the stack
; and the false quotation is called."

        mov     rax, [rbp + BYTES_PER_CELL] ; condition in rax
        cmp     rax, f_value
        jne     .1
        ; condition is false
        ; false quotation is already in rbx
        _2nip
        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        call    rax
        _return
.1:
        ; condition is true
        ; drop false quotation
        poprbx                          ; true quotation is now in rbx
        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        call    rax

        next
endcode

; ### when
code when, 'when'                       ; ? quot --
; if conditional is not f, calls quot
        _swap
        _tagged_if .1
        _ callable_raw_code_address
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
        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        call    rax
        _else .1
        _2drop
        _then .1
        next
endcode

; ### unless
code unless, 'unless'                   ; ? quot --
        _swap
        _f
        _equal
        _if .1
        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        call    rax
        _else .1
        _drop
        _then .1
        next
endcode

; ### unless*
code unless_star, 'unless*'             ; ? quot --
        _over
        _f
        _equal
        _if .1
        _nip
        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        call    rax
        _else .1
        _drop
        _then .1
        next
endcode

; ### return-if-no-locals
code return_if_no_locals, 'return-if-no-locals' ; ? quot --
        cmp    qword [rbp], f_value
        je      .1
        _nip
        _ call_quotation
        lea     rsp, [rsp + BYTES_PER_CELL]
        _return
.1:
        _2drop
        next
endcode

; ### return-if-locals
code return_if_locals, 'return-if-locals'       ; ? quot --
        cmp    qword [rbp], f_value
        je      .1
        _nip
        _ call_quotation
        lea     rsp, [rsp + BYTES_PER_CELL]
        _locals_leave
        _return
.1:
        _2drop
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
        poprbx
        _ callable_raw_code_address
        mov     r12, rbx
        poprbx
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

        ; drop quotations
        lea     rsp, [rsp + BYTES_PER_CELL * 2]

        next
endcode

; ### while
code while, 'while'             ; pred body --
; call body until pred returns f

        ; protect quotations from gc
        push    rbx
        push    qword [rbp]

        push    r12
        push    r13
        _ callable_raw_code_address
        mov     r13, rbx        ; body
        poprbx
        _ callable_raw_code_address
        mov     r12, rbx        ; pred
        poprbx
.1:
        call    r12
        cmp     rbx, f_value
        poprbx
        je      .exit
        call    r13
        jmp     .1
.exit:
        pop     r13
        pop     r12

        ; drop quotations
        lea     rsp, [rsp + BYTES_PER_CELL * 2]

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
        _ fixnum_fixnum_lt
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

; ### times
code times_, 'times'                    ; tagged-fixnum xt --

        ; protect quotation from gc
        push    rbx

        _ callable_raw_code_address     ; -- tagged-fixnum code-address

        _swap
        _untag_fixnum                   ; -- code-address n

        push    r12
        mov     r12, rbx                ; n in r12
        push    r13
        mov     r13, [rbp]              ; address to call in r13
        _2drop                          ; clean up the stack now!

        test    r12, r12
        jle     .2
.1:
        call    r13
        dec     r12
        jz      .2
        call    r13
        dec     r12
        jnz     .1
.2:
        pop     r13
        pop     r12

        ; drop quotation
        pop     rax

        next
endcode

; ### each-integer
code each_integer, 'each-integer'       ; n quot --
        ; check that n is a fixnum
        mov     al, byte [rbp]
        and     al, TAG_MASK
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

        ; drop quotation
        pop     rax

        next
endcode

; ### all-integers?
code all_integers?, 'all-integers?'     ; n quot -- ?
        ; check that n is a fixnum
        mov     al, byte [rbp]
        and     al, TAG_MASK
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
        cmp     rbx, f_value
        je      .2
        poprbx
        inc     r12
        cmp     r12, r15
        jne     .1
        pushrbx
        mov     rbx, t_value
.2:
        pop     r15
        pop     r13
        pop     r12

        ; drop quotation
        pop     rax

        next
endcode

; ### find-integer
code find_integer, 'find-integer'       ; tagged-fixnum callable -- i/f
; callable must have stack effect ( i -- ? )

        _swap
        _check_fixnum

        test    rbx, rbx
        jg      .1
        _2drop
        _f
        _return
.1:

        _swap

        ; protect callable from gc
        push    rbx

        push    r12
        push    r13
        push    r15
        xor     r12, r12                ; loop index in r12
        _ callable_raw_code_address
        mov     r13, rbx                ; code address in r13
        mov     r15, [rbp]              ; loop limit in r15
        _2drop                          ; clean up the stack now!
        test    r15, r15
        jle     .3
.2:
        pushd   r12
        _tag_fixnum
        call    r13
        ; test flag returned by quotation
        cmp     rbx, f_value
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jne     .3
        ; flag was f
        ; keep going
        inc     r12
        cmp     r12, r15
        jne     .2
        ; reached end
        ; return f
        _f
        jmp     .4
.3:
        ; return tagged index
        pushd   r12
        _tag_fixnum
.4:
        pop     r15
        pop     r13
        pop     r12

        ; drop quotation
        pop     rax

        next
endcode

; ### depth
code depth, 'depth'                     ; -- fixnum
        _depth
        _tag_fixnum
        next
endcode

; ### get-data-stack
code get_data_stack, 'get-data-stack'   ; -- array
        push r12

        _lit 10
        _ new_vector_untagged
        popd    r12

        _depth
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
        mov     rbp, [sp0_]
        next
endcode

; ### .s
code feline_dot_s, '.s'
        _ get_data_stack
        _quotation .1
        _ nl
        _ dot_object
        _end_quotation .1
        _ each
        next
endcode

; ### number>string
code number_to_string, 'number>string'  ; n -- string
        _dup_fixnum?_if .1
        _ fixnum_to_string
        _return
        _then .1

        _dup
        _ int64?
        _tagged_if .2
        _ int64_to_string
        _return
        _then .2

        _dup
        _ float?
        _tagged_if .3
        _ float_to_string
        _return
        _then .3

        _ error_not_number

        next
endcode

; ### dec.
code decimal_dot, 'dec.'                ; n --
        _ number_to_string
        _ write_string
        next
endcode

; ### >hex
code to_hex, '>hex'                     ; n -- string
        _dup
        _fixnum?_if .1
        _ fixnum_to_hex
        _return
        _then .1

%ifdef FELINE_FEATURE_BIGNUMS
        _dup
        _ bignum?
        _tagged_if .2
        _ bignum_to_hex
        _return
        _then .2
%endif

        _ error_not_number

        next
endcode

; ### hex.
code hexdot, 'hex.'                     ; x --

        mov     eax, ebx
        and     eax, TAG_MASK
        cmp     eax, FIXNUM_TAG
        jne     .1
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
        _return

.4:
        _quote "0x"
        _ write_string
        _ write_string

        next
endcode

; ### bin.
code bindot, 'bin.'                     ; n --
        _ fixnum_to_binary
        _lit tagged_char('%')
        _ write_char
        _ write_string
        next
endcode

; ### untagged.
code untagged_dot, 'untagged.'          ; x --
        _ untagged_to_hex
        _lit tagged_char('$')
        _ write_char
        _ write_string
        _ space
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

%ifdef WIN64_NATIVE
_global standard_output_handle
%endif

_global last_char
_global output_column

; ### charpos
code charpos, 'charpos'                 ; -- n
        pushrbx
        mov     rbx, [output_column]
        _tag_fixnum
        next
endcode

; ### tab
code tab, 'tab'                         ; n --
        _ charpos
        _ generic_minus
        _lit tagged_fixnum(1)
        _ feline_max
        _ spaces
        next
endcode

; ### write-char
code write_char, 'write-char'           ; tagged-char --
        _untag_char
        mov     [last_char], rbx
        cmp     rbx, 10
        je      .1
        inc     qword [output_column]
        jmp     .2
.1:
        xor     eax, eax
        mov     [output_column], rax
.2:
%ifdef WIN64
        ; args in rcx, rdx, r8, r9
        popd    rcx
        mov     rdx, [standard_output_handle]
%else
        ; args in rdi, rsi, rdx, rcx
        popd    rdi
        mov     esi, 1                  ; fd
%endif
        xcall   os_emit_file            ; void os_emit_file(int c, int fd)
        next
endcode

; ### local@
code local_fetch, 'local@'              ; index -- value
        _check_index
        mov     rbx, [r14 + rbx * BYTES_PER_CELL]
        next
endcode

; ### local!
code local_store, 'local!'              ; value index --
        _check_index
        _cells
        add     rbx, r14
        mov     rax, [rbp]
        mov     [rbx], rax
        _2drop
        next
endcode

; ### local-inc
code local_inc, 'local-inc'     ; index --
        _check_index
        _cells
        add     rbx, r14
        mov     rdx, rbx        ; address
        mov     rbx, [rbx]
        _check_fixnum
        add     rbx, 1
        _tag_fixnum
        mov     [rdx], rbx
        _drop
        next
endcode

; ### local-dec
code local_dec, 'local-dec'     ; index --
        _check_index
        _cells
        add     rbx, r14
        mov     rdx, rbx        ; address
        mov     rbx, [rbx]
        _check_fixnum
        sub     rbx, 1
        _tag_fixnum
        mov     [rdx], rbx
        _drop
        next
endcode

; ### space
code space, 'space'                     ; --
        _write_char 32
        next
endcode

; ### spaces
code spaces, 'spaces'                   ; n --

%define spaces_count    256

        _ check_index

        cmp     rbx, spaces_count
        ja      .1
        pushd   spaces_data
        _swap
        _ unsafe_raw_write_chars
        _return

.1:
        _register_do_times .2
        _ space
        _loop .2
        _return

        section .data
        align   DEFAULT_DATA_ALIGNMENT
spaces_data:
        times spaces_count db ' '

%undef spaces_count

endcode

; ### nl
code nl, 'nl'
; Name from Factor.
%ifdef WIN64
        _lit 13
        _tag_char
        _ write_char
%endif
        _lit 10
        _tag_char
        _ write_char
        next
endcode

; ### ?nl
code ?nl, '?nl'
; Name from Factor.
        mov     rax, [last_char]
        ; was last char a newline?
        cmp     rax, 10
        je     .1
        _ nl
.1:
        next
endcode

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
        movsx   rbx, dword [rbx]
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

; ### char-upcase
code char_upcase, 'char-upcase'
        _check_char
        cmp     rbx, 'a'
        jl      .1
        cmp     rbx, 'z'
        jg      .1
        sub     rbx, 'a' - 'A'
.1:
        _tag_char
        next
endcode

; ### binary-digit?
code binary_digit?, 'binary-digit?'     ; char -- n/f
        _check_char
        cmp     ebx, '0'
        jne     .1
        mov     ebx, tagged_zero
        _return
.1:
        cmp     ebx, '1'
        jne     .2
        mov     ebx, tagged_fixnum(1)
        _return
.2:
        mov     ebx, f_value
        next
endcode

; ### hex-digit?
code hex_digit?, 'hex-digit?'           ; char -- n/f
        _ char_upcase
        _check_char
        cmp     ebx, '0'
        jl      .1
        cmp     ebx, '9'
        jg      .1
        sub     ebx, '0'
        _tag_fixnum
        _return
.1:
        cmp     ebx, 'A'
        jl      .2
        cmp     ebx, 'F'
        jg      .2
        sub     ebx, 'A' - 10
        _tag_fixnum
        _return
.2:
        mov     ebx, f_value
        next
endcode

; ### digit?
code digit?, 'digit?'                   ; char -- n/f
        _check_char
        cmp     ebx, '0'
        jl      .1
        cmp     ebx, '9'
        jg      .1
        sub     ebx, '0'
        _tag_fixnum
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### base>integer
code base_to_integer, 'base>integer'    ; string base -- n/f

        _check_fixnum           ; -- string raw-base

        _swap
        _ string_from           ; -- raw-base raw-data-address raw-length

        mov     arg0_register, [rbp]                    ; raw data address
        mov     arg1_register, rbx                      ; raw length
        mov     arg2_register, [rbp + BYTES_PER_CELL]   ; raw base

        _2nip

        xcall   c_string_to_integer

        mov     rbx, rax
        cmp     rax, f_value
        je      .1

        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     new_handle

.1:
        _rep_return
endcode

; ### hex>integer
code hex_to_integer, 'hex>integer'              ; string -- n/f
        _lit tagged_fixnum(16)
        _ base_to_integer
        next
endcode

; ### binary>integer
code binary_to_integer, 'binary>integer'        ; string -- n/f
        _lit tagged_fixnum(2)
        _ base_to_integer
        next
endcode

; ### string>number
code string_to_number, 'string>number'  ; string -- n/f
        _dup
        _ string_empty?
        _tagged_if .1
        mov     ebx, f_value
        _return
        _then .1

        _quote "0x"
        _over
        _ string_has_prefix?
        _tagged_if .2
        _ hex_to_integer
        _return
        _then .2

        _quote "0b"
        _over
        _ string_has_prefix?
        _tagged_if .3
        _lit tagged_fixnum(2)
        _ string_tail
        _ binary_to_integer
        _return
        _then .3

        _ decimal_to_number

        next
endcode

; ### decimal>number
code decimal_to_number, 'decimal>number'        ; string -- n/f

        _ string_from                   ; -- raw-data-address raw-length

        mov     arg1_register, rbx      ; length
        mov     arg0_register, [rbp]    ; address
        _nip

        xcall   c_decimal_to_number

        mov     rbx, rax
        cmp     rax, f_value
        je      .1

        and     al, TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     new_handle

.1:
        _rep_return
endcode

; ### printable?
code printable?, 'printable?'           ; char -- ?
        _check_char
        cmp     rbx, 32
        jl      .1
        cmp     rbx, 126
        jg      .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### allocate
code feline_allocate, 'allocate'        ; tagged-size -- addr

        _ check_index

feline_allocate_untagged:

%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_malloc
        mov     rbx, rax                ; -- addr
        test    rbx, rbx
        jz .1
        _return
.1:
        _error "memory allocation failed"
        next
endcode

; ### free
code feline_free, 'free'                ; addr --
; Argument is untagged.
%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        poprbx
        xcall   os_free                 ; "The free() function returns no value."
        next
endcode

asm_global nrows_data

; ### #rows
code nrows, '#rows'
        pushrbx
        mov     rbx, [nrows_data]
        _tag_fixnum
        next
endcode

asm_global ncols_data

; ### #cols
code ncols, '#cols'
        pushrbx
        mov     rbx, [ncols_data]
        _tag_fixnum
        next
endcode

; ### seed-random
code seed_random, 'seed-random'         ; --

        ; REVIEW
        _rdtsc

        mov     arg0_register, rbx
        poprbx
        xcall   c_seed_random
        next
endcode

; ### random-fixnum
code random_fixnum, 'random-fixnum'     ; -- fixnum
        xcall   c_random
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### random-int64
code random_int64, 'random-int64'       ; -- int64
        xcall   c_random
        pushrbx
        mov     rbx, rax
        _ new_int64
        next
endcode

; ### random-uint64
code random_uint64, 'random-uint64'     ; -- uint64
        xcall   c_random
        pushrbx
        mov     rbx, rax
        _ new_uint64
        next
endcode

; ### lshift
code lshift, 'lshift'   ; x n -- y
; shifts fixnum x to the left by n bits
; n must be >= 0
        _check_index
        _check_fixnum qword [rbp]
        _lshift
        _tag_fixnum
        next
endcode

; ### rshift
code rshift, 'rshift'   ; x n -- y
; shifts fixnum x to the right by n bits
; n must be >= 0
        _check_index
        _check_fixnum qword [rbp]
        _rshift
        _tag_fixnum
        next
endcode

; ### expt
code expt, 'expt'                       ; base power -- result

%ifdef FELINE_FEATURE_BIGNUMS

        ; FIXME incomplete

        _check_index

        _over
        _fixnum?_if .1
%ifdef WIN64
        _swap
        _untag_fixnum
        _ signed_to_bignum
        _swap
%else
        _ gc_disable
        mov     arg1_register, rbx
        poprbx
        _untag_fixnum
        mov     arg0_register, rbx
        poprbx
        xcall   c_fixnum_expt
        pushrbx
        mov     rbx, rax
        _ gc_enable
        _return
%endif
        _then .1

        _over
        _ bignum?
        _tagged_if .2
        _ gc_disable
        mov     arg1_register, rbx
        poprbx
        _handle_to_object_unsafe
        mov     arg0_register, rbx
        poprbx
        xcall   c_bignum_expt
        pushrbx
        mov     rbx, rax
        _ gc_enable
        _return
        _then .2

%else

        ; no bignums
        _dup_fixnum?_if .1
        _ fixnum_to_float
        _then .1
        _ check_float

        _swap

        _dup_fixnum?_if .2
        _ fixnum_to_float
        _then .2
        _ check_float                   ; -- power base

        mov     arg0_register, rbx
        mov     arg1_register, [rbp]
        poprbx
        xcall   c_float_expt
        mov     rbx, rax

        _ new_handle
%endif

        next
endcode

; ### bye
code feline_bye, "bye"
        _ free_locals_stack

        _ interactive?
        _ get
        _tagged_if .1
        _ ?nl
        _write `Bye!\n`
        _then .1

        xcall os_bye

        next
endcode
