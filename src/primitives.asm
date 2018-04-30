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

; ### eq?                               ; x y -- ?
inline eq?, 'eq?'
        _eq?
endinline

; ### neq?
inline neq?, 'neq?'                     ; x y -- ?
        mov     eax, t_value
        cmp     rbx, [rbp]
        mov     ebx, f_value
        cmovne  ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
endinline

; ### =
code feline_equal, '='                  ; x y -- ?

        _debug_?enough 2

        cmp     rbx, [rbp]
        jne     .1
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     ebx, t_value
        _return
.1:
        _ equal?
        next
endcode

; ### not
inline not, 'not'
        _not
endinline

; ### <>
code not_equal, '<>'                    ; x y -- ?
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
        _fixnum_zero?
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

        cmp     qword [rbp], f_value
        je      .1
        _ callable_raw_code_address
        mov     rax, rbx
        poprbx
        jmp     rax

.1:
        _2drop
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
code token_character_literal?, 'token-character-literal?'       ; token -- char t | token f

        _duptor

        _ check_string

        push    this_register
        mov     this_register, rbx
        _drop                           ; --    r: -- token

        cmp     this_string_raw_length, 3
        jl      .fail

        ; length >= 3
        cmp     this_string_first_unsafe, 0x27
        jne     .fail

        _this_string_last_unsafe
        cmp     rbx, 0x27
        _drop
        jne     .fail

        cmp     this_string_raw_length, 3
        jne     .fail

        _this_string_second_unsafe
        _tag_char

        pop     this_register
        _rdrop
        _t
        _return

.fail:
        pop     this_register
        _rfrom
        _f
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
        cmp     qword [stop_for_gc?_], f_value
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
code each_integer, 'each-integer'       ; n quot --
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
code clear, 'clear'                     ; ??? --
; clear the current thread's data stack
        _ current_thread_raw_sp0_rax
        mov     rbp, rax
        next
endcode

; ### number>string
code number_to_string, 'number>string'  ; n -- string
        test    bl, FIXNUM_TAG
        jnz fixnum_to_string

        _dup
        _ object_raw_typecode
        mov     rax, rbx
        poprbx

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

; ### >hex
code to_hex, '>hex'                     ; n -- string
        _dup
        _fixnum?_if .1
        _ fixnum_to_hex
        _return
        _then .1

        _ error_not_number

        next
endcode

; ### hex.
code hexdot, 'hex.'                     ; x --

        mov     eax, ebx
        and     eax, FIXNUM_TAG_MASK
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
        _quote "0b"
        _ write_string
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

asm_global last_char_, 10

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
        _ generic_max
        _ spaces
        next
endcode

; ### write-char
code write_char, 'write-char'           ; tagged-char --
        _check_char
        mov     [last_char_], rbx
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

; ### write-char-escaped
code write_char_escaped, 'write-char-escaped'   ; tagged-char --
        _check_char
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

; ### write-string-escaped
code write_string_escaped, 'write-string-escaped'       ; string --
        _quotation .1
        _ write_char_escaped
        _end_quotation .1
        _ each
        next
endcode

; ### local@
code local_fetch, 'local@'              ; index -- value
        _check_index
        mov     rbx, [r14 + rbx * BYTES_PER_CELL]
        next
endcode

; ### local_0_fetch
inline local_0_fetch, 'local_0_fetch', SYMBOL_INTERNAL  ; -- value
        pushrbx
        mov     rbx, [r14]
endinline

; ### local_1_fetch
inline local_1_fetch, 'local_1_fetch', SYMBOL_INTERNAL  ; -- value
        pushrbx
        mov     rbx, [r14 + BYTES_PER_CELL]
endinline

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

; ### local_0_store
inline local_0_store, 'local_0_store', SYMBOL_INTERNAL  ; value --
        mov     [r14], rbx
        poprbx
endinline

; ### local_1_store
inline local_1_store, 'local_1_store', SYMBOL_INTERNAL  ; value --
        mov     [r14 + BYTES_PER_CELL], rbx
        poprbx
endinline

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

%define spaces_count    256

        section .data
        align   DEFAULT_DATA_ALIGNMENT
spaces_:
        times spaces_count db ' '

; ### spaces
code spaces, 'spaces'                   ; n --

        _check_fixnum                   ; -- raw-count
        test    rbx, rbx
        jng     .exit

        cmp     rbx, spaces_count
        jg      .1
        _dup
        mov     qword [rbp], spaces_    ; -- raw-address raw-count
        _ unsafe_raw_write_chars
        _return

.1:
        _register_do_times .2
        _ space
        _loop .2
        _return

.exit:
        _drop
        next
endcode

%undef spaces_count

; ### nl
code nl, 'nl'
%ifdef WIN64
        _quote `\r\n`
        _ write_string
        mov     qword [last_char_], 10
        xor     eax, eax
        mov     [output_column], rax
%else
        _lit tagged_char(10)
        _ write_char
%endif
        next
endcode

; ### ?nl
code ?nl, '?nl'
        ; was last char a newline?
        cmp     qword [last_char_], 10
        jne     nl
        next
endcode

; ### print
code print, 'print'
        _ generic_write
        _ nl
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

; ### copy-bytes
code copy_bytes, 'copy-bytes'           ; source destination count --
; FIXME inefficient, does not support overlapping moves

        _check_fixnum
        _ rrot
        _check_fixnum
        _ rrot
        _check_fixnum
        _ rrot                          ; -- source destination count

%ifdef WIN64
        push    rdi
        push    rsi
%endif

        mov     rcx, rbx                        ; count
        mov     rdi, [rbp]                      ; destination
        mov     rsi, [rbp + BYTES_PER_CELL]     ; source
        mov     rbx, [rbp + BYTES_PER_CELL * 2]
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        jrcxz   .1
        rep     movsb

.1:

%ifdef WIN64
        pop     rsi
        pop     rdi
%endif

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

        and     al, FIXNUM_TAG_MASK
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
        cmp     rbx, f_value
        poprbx
        jne     hex_to_integer

        _quote "-0x"
        _over
        _ string_has_prefix?
        cmp     rbx, f_value
        poprbx
        jne     hex_to_integer

        _quote "0b"
        _over
        _ string_has_prefix?
        _tagged_if .2
        _lit tagged_fixnum(2)
        _ string_tail
        _ binary_to_integer
        _return
        _then .2

        _quote "-0b"
        _over
        _ string_has_prefix?
        _tagged_if .3
        _lit tagged_fixnum(3)
        _ string_tail
        _ binary_to_integer
        _ generic_negate
        _return
        _then .3

        _ decimal_to_number

        next
endcode

; ### decimal>number
code decimal_to_number, 'decimal>number'        ; string -- n/f
%if 0
        _ string_from                   ; -- raw-data-address raw-length

        mov     arg1_register, rbx      ; length
        mov     arg0_register, [rbp]    ; address
        _nip

        xcall   c_decimal_to_number

        mov     rbx, rax
        cmp     rax, f_value
        je      .1

        and     al, FIXNUM_TAG_MASK
        cmp     al, FIXNUM_TAG
        jne     new_handle

.1:
        _rep_return
%else
        _duptor
        _ string_first_char
        _eq? tagged_char('-')
        _tagged_if .1
        _rfetch
        _ decimal_to_signed
        _else .1
        _rfetch
        _ decimal_to_unsigned
        _then .1                        ; -- n/f

        _dup
        _tagged_if .2
        _rdrop
        _return
        _then .2

        ; not an integer
        _drop
        _rfrom
        _ string_to_float
        next
%endif
endcode

%if 0
; ### xdecimal>number
code xdecimal_to_number, 'xdecimal>number'      ; string -- n/f
        _duptor
        _ string_first_char
        _eq? tagged_char('-')
        _tagged_if .1
        _rfetch
        _ decimal_to_signed
        _else .1
        _rfetch
        _ decimal_to_unsigned
        _then .1                        ; -- n/f

        _dup
        _tagged_if .2
        _rdrop
        _return
        _then .2

        ; not an integer
        _drop
        _rfrom
        _ string_to_float
        next
endcode
%endif

; ### raw_digit?
code raw_digit?, 'raw_digit?', SYMBOL_INTERNAL  ; untagged-char -- ?
        cmp     ebx, '0'
        jl      .no
        cmp     ebx, '9'
        jg      .no
        mov     ebx, t_value
        next
.no:
        mov     ebx, f_value
        next
endcode

; ### decimal>unsigned
code decimal_to_unsigned, 'decimal>unsigned'    ; string -- unsigned/f

        _ check_string

        ; return f if string is empty
        _dup
        _string_raw_length
        test    rbx, rbx
        poprbx
        jnz     .1
        mov     ebx, f_value
        _return
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
        mov     ebx, f_value
        _return

.no_overflow:
        mov     rbx, rax

        _raw_loop_index
        _this_string_nth_unsafe         ; -- accum untagged-char
        _dup
        _ raw_digit?
        _tagged_if_not .2
        _nip
        _unloop
        pop     this_register
        mov     ebx, f_value
        _return
        _then .2

        sub     ebx, '0'
        add     qword [rbp], rbx

        jnc     .no_carry
        _nip
        _unloop
        pop     this_register
        mov     ebx, f_value
        _return

.no_carry:
        poprbx
        _loop .loop

        pop     this_register           ; -- raw-int64

        _ normalize_unsigned

        next
endcode

; ### decimal>signed
code decimal_to_signed, 'decimal>signed'        ; string -- signed/f

        _ check_string

        _dup
        _string_raw_length
        cmp     rbx, 2
        poprbx
        jge     .1
        mov     ebx, f_value
        _return

.1:
        _dup
        _string_first_unsafe
        cmp     rbx, '-'
        poprbx
        je      .2
        mov     ebx, f_value
        _return

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
        mov     ebx, f_value
        _return

.no_overflow:
        _raw_loop_index
        _this_string_nth_unsafe         ; -- accum untagged-char

        _dup
        _ raw_digit?
        _tagged_if_not .3
        _drop
        _unloop
        pop     this_register
        mov     ebx, f_value
        _return
        _then .3

        sub     ebx, '0'
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
        mov     rbx, f_value
        _return

.no_carry:
        poprbx
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
        _dup
        _char?
        _tagged_if .1
        _untag_char
        cmp     rbx, 32
        jl      .2
        cmp     rbx, 126
        jg      .2
        mov     ebx, t_value
        _return
        _then .1
.2:
        mov     ebx, f_value
        next
endcode

; ### code-char
inline code_char, 'code-char'           ; tagged_fixnum -- tagged-char
        _code_char
endinline

; ### char-code
inline char_code, 'char-code'           ; tagged-char -- tagged-fixnum
        _char_code
endinline

; ### char?
inline char?, 'char?'                   ; x -- ?
        _char?
endinline

; ### char-hashcode
inline char_hashcode, 'char-hashcode'   ; tagged-char -- tagged-fixnum
        ; REVIEW collisions with fixnums
        _char_code
endinline

; ### char>string
code char_to_string, 'char>string'      ; tagged-char -- string

        _verify_char

        ; space char is a special case
        _dup
        _tagged_char(' ')
        _eq?
        _tagged_if .1
        _drop
        _quote "'\x20'"
        _return
        _then .1

        _lit 3
        _ new_sbuf_untagged
        _tor

        _lit tagged_char("'")
        _rfetch
        _ sbuf_push                     ; -- tagged-char

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

        _lit tagged_char("'")
        _rfetch
        _ sbuf_push

        _rfrom
        _ sbuf_to_string

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

asm_global terminal_height_

; ### terminal-height
code terminal_height, 'terminal-height'
        pushrbx
        mov     rbx, [terminal_height_]
        _tag_fixnum
        next
endcode

asm_global terminal_width_

; ### terminal-width
code terminal_width, 'terminal-width'
        pushrbx
        mov     rbx, [terminal_width_]
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
        _ check_float                   ; -- power base

        mov     arg0_register, rbx
        mov     arg1_register, [rbp]
        poprbx
        xcall   c_float_expt
        mov     rbx, rax

        _ new_handle

        next
endcode

; ### windows?
code windows?, 'windows?'               ; -- ?
%ifdef WIN64
        _t
%else
        _f
%endif
        next
endcode

; ### linux?
code linux?, 'linux?'                   ; -- ?
%ifdef WIN64
        _f
%else
        _t
%endif
        next
endcode

; ### debug?
code debug?, 'debug?'                   ; -- ?
%ifdef DEBUG
        _t
%else
        _f
%endif
        next
endcode

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
code feline_bye, "bye"
        _ free_locals_stack

        _ interactive?
        _ get
        _tagged_if .1
        _ ?nl
        _ output_style
        _write `Bye!\n`
        _then .1

        xcall os_bye

        next
endcode
