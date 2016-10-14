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

; ### last-word
value last_word, 'last-word', f

; ### set-last-word
code set_last_word, 'set-last-word'     ; word --
        _to last_word
        next
endcode

; ### swap
inline swap, 'swap'                     ; x1 x2 -- x2 x1
        _swap
endinline

; ### drop
inline drop, 'drop'
        _drop
endinline

; ### 2drop
inline twodrop, '2drop'
        _2drop
endinline

; ### 3drop
inline threedrop, '3drop'
        _3drop
endinline

; ### 4drop
inline fourdrop, '4drop'
        mov     rbx, [rbp + BYTES_PER_CELL * 3]
        lea     rbp, [rbp + BYTES_PER_CELL * 4]
endinline

; ### dup
inline dup, 'dup'
        _dup
endinline

; ### dupd
inline dupd, 'dupd'
        _dupd
endinline

; ### 2dup
inline twodup, '2dup'                   ; x1 x2 -- x1 x2 x1 x2
        _twodup
endinline

; ### 3dup
code threedup, '3dup'                   ; x1 x2 x3 -- x1 x2 x3 x1 x2 x3
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
        mov     rax, [rbp]                      ; x2 in RAX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; x1 in RDX
        mov     [rbp + BYTES_PER_CELL], rax     ; x2
        mov     [rbp], rbx                      ; x3
        mov     rbx, rdx                        ; x1
        next
endcode

; ### -rot
code rrot, '-rot'                       ; x1 x2 x3 -- x3 x1 x2
        mov     rax, [rbp]                      ; x2 in RAX
        mov     rdx, [rbp + BYTES_PER_CELL]     ; x1 in RDX
        mov     [rbp + BYTES_PER_CELL], rbx     ; x3
        mov     [rbp], rdx                      ; x1
        mov     rbx, rax                        ; x2
        next
endcode

; ### over
inline over, 'over'
        _over
endinline

; ### nip
inline nip, 'nip'                       ; x1 x2 -- x2
        _nip
endinline

; ### tuck
code tuck, 'tuck'                       ; x1 x2 -- x2 x1 x2
        _tuck
        next
endcode

; ### swapd
code swapd, 'swapd'                     ; x y z -- y x z
        mov     rax, [rbp]
        mov     rdx, [rbp + BYTES_PER_CELL]
        mov     [rbp + BYTES_PER_CELL], rax
        mov     [rbp], rdx
        next
endcode

; ### 2nip
inline twonip, '2nip'                   ; x y z -- z
        _2nip
endinline

%macro  _eq? 0                          ; obj1 obj2 -- ?
        mov     eax, t_value
        cmp     rbx, [rbp]
        mov     ebx, f_value
        cmove   ebx, eax
        lea     rbp, [rbp + BYTES_PER_CELL]
%endmacro

%macro  _eq?_literal 1                  ; obj -- ?
        mov     eax, t_value
        cmp     rbx, %1
        mov     ebx, f_value
        cmove   ebx, eax
%endmacro

; ### eq?                               ; obj1 obj2 -- ?
inline eq?, 'eq?'
        _eq?
endinline

; ### =
code feline_equal, '='                  ; n1 n2 -- ?
        cmp     rbx, [rbp]
        jne     .1
        lea     rbp, [rbp + BYTES_PER_CELL]
        mov     ebx, t_value
        _return
.1:
        _ equal?
        next
endcode

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

; ### or, 'or'
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
        _ callable_code_address         ; code address in rbx
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
        _ callable_code_address
        mov     rax, rbx
        poprbx
        call    rax
        _return
.1:
        ; condition is true
        ; drop false quotation
        poprbx                          ; true quotation is now in rbx
        _ callable_code_address
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
code unless, 'unless'                   ; ? quot --
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

; ### unless*
code unless_star, 'unless*'             ; ? quot --
        _over
        _f
        _equal
        _if .1
        _nip
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
        _ callable_code_address
        mov     r13, rbx
        poprbx
        _ callable_code_address
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

        _dup
        _lit 1
        _equal
        _if .2

        ; 1-char string
        _drop
        _cfetch
        _ digit
        _if .3
        _tag_fixnum
        _else .3
        _f
        _then .3
        _return

        _then .2

        _ basefetch
        _tor
        _ maybe_change_base             ; -- c-addr2 u2
        _ number?                       ; -- d flag
        _rfrom
        _ basestore

        _zeq_if .4                      ; -- d
        ; conversion failed
        _2drop
        _f
        _return
        _then .4

        _ negative?
        _if .5
        _ dnegate
        _then .5

        ; REVIEW
        _drop

        ; FIXME check range
        _tag_fixnum

        next
endcode

; ### times
code times_, 'times'                    ; tagged-fixnum xt --

        ; protect quotation from gc
        push    rbx

        _ callable_code_address         ; -- tagged-fixnum code-address

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

        ; drop quotation
        pop     rax

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
        _ callable_code_address
        mov     r13, rbx                ; code address in r13
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
        _ get_datastack
        _quotation .1
        _ nl
        _ dot_object
        _end_quotation .1
        _ each
        next
endcode

; ### number>string
code number_to_string, 'number>string'  ; n -- string
        _ fixnum_to_string
        next
endcode

; ### >hex
code to_hex, '>hex'                     ; n -- string
        _ fixnum_to_hex
        next
endcode

; ### hex.
code hexdot, 'hex.'                     ; n --
        _ fixnum_to_hex
        _lit tagged_fixnum('$')
        _ write_char
        _ write_string
        next
endcode

; ### pick
inline feline_pick, 'pick'              ; x y z -- x y z x
; This is the Factor/Feline version of pick.
; The Forth version is different.
        _pick
endinline

; ### 2over
code feline_2over, '2over'              ; x y z -- x y z x y
; This is the Factor/Feline version of 2over.
; The Forth version is different.
        _ feline_pick
        _ feline_pick
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
        _ feline_minus
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

; ### local!
code local_store, 'local!'              ; value index --
        _untag_fixnum
        _cells
        add     rbx, r14
        mov     rax, [rbp]
        mov     [rbx], rax
        _2drop
        next
endcode

; ### space
code space, 'space'                     ; --
        _lit ' '
        _tag_char
        _ write_char
        next
endcode

; ### spaces
code spaces, 'spaces'                   ; n --
        _ check_index
        _zero
        _?do .1
        _ space
        _loop .1
        next
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
code feline_cfetch, 'c@'                ; tagged-fixnum-address -- tagged-fixnum-byte
        _untag_fixnum
        _cfetch
        _tag_fixnum
        next
endcode

; ### error-not-char
code error_not_char, 'error-not-char'   ; x --
        ; REVIEW
        _error "not a char"
        next
endcode

%macro _verify_char 0
        mov     al, bl
        and     al, TAG_MASK
        cmp     al, CHAR_TAG
        jne     error_not_char
%endmacro

; ### verify-char
code verify_char, 'verify-char'         ; char -- char
        _verify_char
        next
endcode

%macro _check_char 0
        _verify_char
        _untag_char
%endmacro

; ### check-char
code check_char, 'check-char'           ; char -- untagged-char
        _check_char
        next
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

extern os_allocate

; ### allocate
code feline_allocate, 'allocate'        ; tagged-size -- addr

        _ check_index

feline_allocate_untagged:

%ifdef WIN64
        mov     rcx, rbx
%else
        mov     rdi, rbx
%endif
        xcall   os_allocate
        mov     rbx, rax                ; -- addr
        test    rbx, rbx
        jz .1
        _return
.1:
        _error "memory allocation failed"
        next
endcode

extern os_free

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

; ### bye
code feline_bye, "bye"
        _ free_locals_stack

        _ interactive?
        _if .1
        _ ?nl
        _quote "Bye!"
        _ write_string
        _ nl
        _then .1

        jmp os_bye
        next
endcode
