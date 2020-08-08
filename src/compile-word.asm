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

asm_global compile_verbose_, NIL

; ### +v
code verbose_on, '+v'
        mov     qword [compile_verbose_], TRUE
        next
endcode

; ### -v
code verbose_off, '-v'
        mov     qword [compile_verbose_], NIL
        next
endcode

; ### compile-verbose?
code compile_verbose?, 'compile-verbose?' ; -> ?
        _dup
        mov     rbx, [compile_verbose_]
        next
endcode

asm_global pc_, 0

%macro _pc 0
        _dup
        mov     rbx, [pc_]
%endmacro

; ### initialize-code-block
code initialize_code_block, 'initialize-code-block' ; tagged-size -> tagged-address
        _check_fixnum
        _ raw_allocate_executable       ; -> raw-address
        _tag_fixnum
        next
endcode

; ### precompile-object
code precompile_object, 'precompile-object', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; object -> pair
; all values are untagged
        _dup
        _ symbol?
        _tagged_if .1
        _zero                           ; -> symbol 0
        _else .1
        _zero
        _swap                           ; -> 0 literal-value
        _then .1
        _ two_array
        next
endcode

; ### add-code-size
code add_code_size, 'add-code-size', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; accum pair -> accum
; FIXME arbitrary for now
        _drop
        _lit 25
        _plus
        next
endcode

%macro _emit_raw_byte 1
        mov     rdx, [pc_]
        add     qword [pc_], 1
        mov     byte [rdx], %1
%endmacro

; ### emit_raw_byte
code emit_raw_byte, 'emit_raw_byte', SYMBOL_INTERNAL    ; byte -> void
        mov     rdx, [pc_]
        add     qword [pc_], 1
        mov     [rdx], bl
        _drop
        next
endcode

; ### emit_raw_dword
code emit_raw_dword, 'emit_raw_dword', SYMBOL_INTERNAL  ; dword -> void
        mov     rdx, [pc_]
        mov     [rdx], ebx
        add     qword [pc_], 4
        _drop
        next
endcode

; ### emit_raw_qword
code emit_raw_qword, 'emit_raw_qword', SYMBOL_INTERNAL  ; qword -> void
        mov     rdx, [pc_]
        mov     [rdx], rbx
        add     qword [pc_], 8
        _drop
        next
endcode

; ### compile-call
code compile_call, 'compile-call', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; raw-address -> void
        _dup
        _pc
        add     rbx, 5
        _minus                          ; -> raw-address signed-displacement

        ; does the signed displacement fit in 32 bits?
        cmp     rbx, MIN_INT32
        jl      .1
        cmp     rbx, MAX_INT32
        jg      .1

        _drop                           ; -> raw-address
        _emit_raw_byte 0xe8
        _pc
        add     rbx, 4
        _minus
        _ emit_raw_dword
        next

.1:
        _drop                           ; -> raw-address
        cmp     rbx, MAX_INT32
        jl      .2

        ; raw address fits in 32 bits
        _emit_raw_byte 0xb8
        _ emit_raw_dword                ; mov eax, raw-address
        jmp     .3

.2:
        ; raw address does not fit in 32 bits
        _emit_raw_byte 0x48
        _emit_raw_byte 0xb8
        _ emit_raw_qword                ; mov rax, raw-address

.3:
        _emit_raw_byte 0xff
        _emit_raw_byte 0xd0             ; call rax

        next
endcode

%define DUP_BYTES 0xf86d8d48f85d8948

; ### compile-literal
code compile_literal, 'compile-literal', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; literal -> void
        _dup
        _ wrapper?
        _tagged_if .1
        _ wrapped
        _then .1

        _lit DUP_BYTES
        _ emit_raw_qword
        _dup
        _lit 0x100000000
        _ult
        _if .2
        _emit_raw_byte 0xbb
        _ emit_raw_dword
        _else .2
        _emit_raw_byte 0x48
        _emit_raw_byte 0xbb
        _ emit_raw_qword
        _then .2
        next
endcode

asm_global forward_jumps_, NIL

code forward_jumps, 'forward-jumps'     ; -> vector/nil
        _dup
        mov     rbx, [forward_jumps_]
        next
endcode

; ### add-forward-jump-address
code add_forward_jump_address, 'add-forward-jump-address' ; tagged-address -> void
        cmp     qword [forward_jumps_], NIL
        jne     .1
        _lit 8
        _ make_vector_untagged
        mov     qword [forward_jumps_], rbx
        _drop
.1:
        _ forward_jumps
        _ vector_push
        next
endcode

; ### inline-primitive
code inline_primitive, 'inline-primitive' ; symbol -> void

%ifdef DEBUG
        _dup
        _ symbol_inline?
        _tagged_if_not .1
        _error "symbol not inline"
        _return
        _then .1
%endif

        push    rbx
        _ symbol_raw_code_address
        _dup
        pop     rbx
        _ symbol_raw_code_size          ; -> raw-code-address raw-code-size

        sub     rbx, 1                  ; adjust size to exclude ret instruction

        mov     arg0_register, [rbp]    ; source address
        mov     arg1_register, [pc_]    ; destination address
        mov     arg2_register, rbx      ; size
        _ copy_bytes                    ; -> addr size

        add     qword [pc_], rbx
        _2drop
        next
endcode

; ### ?exit-no-locals
always_inline ?exit_no_locals, '?exit_no_locals'
        cmp     rbx, NIL
        _drop
        je      .1
        ret
.1:
endinline

; ### ?exit_locals
always_inline ?exit_locals, '?exit_locals'
        cmp     rbx, NIL
        _drop
        ; 2-byte jne
        db      0x0f
        db      0x85
?exit_locals_patch:
        ; These bytes will be patched.
        db      0
        db      0
        db      0
        db      0
endinline

; ### ?exit-locals-patch-offset
code ?exit_locals_patch_offset, '?exit-locals-patch-offset'     ; void -> fixnum
        _dup
        mov     rbx, ?exit_locals_patch
        sub     rbx, ?exit_locals
        _tag_fixnum
        next
endcode

; ### compile-?exit-locals
code compile_?exit_locals, 'compile-?exit-locals' ;  symbol -> void
; symbol is the name of the function being compiled (?exit_locals)

        _pc
        add       rbx, ?exit_locals_patch - ?exit_locals
        _tag_fixnum
        _ add_forward_jump_address      ; -> symbol

        _ inline_primitive              ; -> empty

        next
endcode

; ### fix-call
code fix_call, 'fix-call'               ; call-address target-address -> void
; arguments are tagged fixnums

        ; [rbp]: address of call instruction (0xe8)
        ; rbx: address of call target

        _check_fixnum qword [rbp]       ; untag call address
        _check_fixnum                   ; untag target address
        _over                   ; -> call-address target-address call-address
        add     rbx, 5          ; rbx: untagged address of first byte of next instruction
        _minus                  ; -> call-address delta
        _swap                   ; -> delta call-address
        add     rbx, 1          ; skip over 0xe8

        _lstore

        next
endcode

; ### ?return-no-locals
always_inline ?return_no_locals, '?return_no_locals' ; ? quot ->
        cmp     qword [rbp], NIL
        je      .1
        _nip
..@?return_no_locals_patch:     ; use ..@ prefix to avoid interfering with local labels
        _ call_quotation
        ret
.1:
        _2drop
endinline

; ### compile-?return-no-locals
code compile_?return_no_locals, 'compile-?return-no-locals' ; symbol -> void
; symbol is the name of the function being compiled (?return-no-locals)

        _pc
        add     rbx, ..@?return_no_locals_patch - ?return_no_locals
        _tag_fixnum                     ; -> symbol tagged-call-address

        _swap                           ; -> tagged-call-address symbol
        _ inline_primitive              ; -> tagged-call-address

        _tick call_quotation
        _ symbol_code_address           ; -> tagged-call-address tagged-target-address

        _ fix_call                      ; -> empty

        next
endcode

; ### ?return-locals
always_inline ?return_locals, '?return_locals' ; ? quot ->
        cmp     qword [rbp], NIL
        je      .1
        _nip
..@?return_locals_patch1:       ; use ..@ prefix to avoid interfering with local labels
        _ call_quotation
        db      0xe9            ; jmp
..@?return_locals_patch2:
        ; These bytes will be patched.
        db      0
        db      0
        db      0
        db      0
.1:
        _2drop
endinline

; ### compile-?return-locals
code compile_?return_locals, 'compile-?return-locals' ; symbol -> void
; symbol is the name of the function being compiled (?returnx-locals)

        _pc
        add     rbx, ..@?return_locals_patch1 - ?return_locals
        _tag_fixnum                     ; address to patch for call

        _pc
        add     rbx, ..@?return_locals_patch2 - ?return_locals
        _tag_fixnum                     ; address to patch for jump to exit

        ; -> symbol patch1-address patch2-address
        _ add_forward_jump_address      ; -> symbol patch1-address

        _swap                           ; -> patch1-address symbol
        _ inline_primitive              ; -> patch1-address

        _tick call_quotation
        _ symbol_code_address           ; -> patch1-address call-target-address

        ; -> patch1-address call-target-address
        _ fix_call                      ; -> empty

        next
endcode

; ### compile-primitive
code compile_primitive, 'compile-primitive', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; symbol -> void
        _dup
%ifdef DEBUG
        _ symbol_always_inline?
%else
        _ symbol_inline?
%endif
        _tagged_if .1

        ; -> symbol
        push    rbx
        _ check_symbol                  ; -> symbol ^symbol
        mov     rax, rbx                ; rax: ^symbol
        pop     rbx

        cmp     rax, symbol_raw_address(?exit_locals)
        je      compile_?exit_locals
        cmp     rax, symbol_raw_address(?return_no_locals)
        je      compile_?return_no_locals
        cmp     rax, symbol_raw_address(?return_locals)
        je      compile_?return_locals

        _ inline_primitive

        _else .1
        _ symbol_raw_code_address
        _ compile_call
        _then .1
        next
endcode

; ### compile-pair
code compile_pair, 'compile-pair', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; pair -> void
        _dup
        _ array_first
        _zeq_if .1
        _ array_second
        _ compile_literal
        _return
        _then .1                        ; -> pair

        _ array_first                   ; -> symbol
        _dup
        _ symbol_primitive?
        _tagged_if .2
        _ compile_primitive
        _return
        _then .2

        ; not a primitive
        _ symbol_raw_code_address
        _ compile_call

        next
endcode

; ### compile-prolog
code compile_prolog, 'compile-prolog', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE

        _ locals_count          ; -> tagged-fixnum
        test    bl, FIXNUM_TAG
        jz      error_not_fixnum
        sar     rbx, FIXNUM_TAG_BITS
        jz      drop            ; nothing to do if locals-count is 0

        ; we have locals
        _emit_raw_byte 0x41
        _emit_raw_byte 0x56     ; push r14

        _emit_raw_byte 0x48
        _emit_raw_byte 0x81
        _emit_raw_byte 0xec

        ; -> raw-count (in rbx)
        shl     rbx, 3          ; convert cells to bytes
        _ emit_raw_dword        ; sub rsp, number of bytes

        _emit_raw_byte 0x49
        _emit_raw_byte 0x89
        _emit_raw_byte 0xe6     ; mov r14, rsp

        ; -> empty
        next
endcode

asm_global exit_address_, 0

; ### exit-address
code exit_address, 'exit-address'       ; void -> fixnum
        _dup
        mov     rbx, [exit_address_]
        _tag_fixnum
        next
endcode

; ### patch-forward-jump
code patch_forward_jump, 'patch-forward-jump' ; tagged-address -> void
        _ exit_address          ; -> tagged-address tagged-exit-address
        _check_fixnum           ; -> tagged-address untagged-exit-address
        _over                   ; -> tagged-address untagged-exit-address tagged-address
        _check_fixnum           ; -> tagged-address untagged-exit-address untagged-address
        add     rbx, 4          ; address of next instruction's first byte in rbx
        _minus                  ; -> tagged-address delta
        _tag_fixnum
        _swap
        _ lstore
        next
endcode

; ### patch-forward-jumps
code patch_forward_jumps, 'patch-forward-jumps' ; address -> void

        _ forward_jumps

        cmp     rbx, NIL
        je      drop

        _tick patch_forward_jump
        _ vector_each
        mov     qword [forward_jumps_], NIL

        next
endcode

; ### compile-epilog
code compile_epilog, 'compile-epilog', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE

        mov     rax, [pc_]
        mov     [exit_address_], rax

        _ locals_count          ; -> tagged-fixnum
        test    bl, FIXNUM_TAG
        jz      error_not_fixnum
        sar     rbx, FIXNUM_TAG_BITS
        jz      drop            ; nothing to do if locals-count is 0

        ; we have locals
        _emit_raw_byte 0x48
        _emit_raw_byte 0x81
        _emit_raw_byte 0xc4

        ; -> raw-count (in rbx)
        shl     rbx, 3          ; convert cells to bytes
        _ emit_raw_dword        ; add rsp, number of bytes

        ; -> empty
        _emit_raw_byte 0x41
        _emit_raw_byte 0x5e     ; pop r14

        next
endcode

; ### primitive-compile-quotation
code primitive_compile_quotation, 'primitive-compile-quotation', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; quotation -> void

        _debug_?enough 1

        _ check_quotation               ; -> ^quotation

        push    this_register
        mov     this_register, rbx      ; ^quotation in this_register
        _drop                           ; -> empty

        _this_quotation_array
        _tick precompile_object
        _ map_array                     ; -> precompiled-array

        _zero
        _over
        _tick add_code_size
        _ array_each

        ; add size of return instruction
        _oneplus                        ; -> raw-size
        _tag_fixnum

        _ initialize_code_block         ; -> tagged-address

        _check_fixnum                   ; -> untagged-address
        mov     [pc_], rbx

        ; save untagged address of code block on the return stack
        push    rbx
        _drop                           ; -> empty

        ; prolog
        _ compile_prolog

        ; body
        _tick compile_pair
        _ each

        ; epilog
        _ compile_epilog

        _emit_raw_byte 0xc3

        _ patch_forward_jumps

        _rfetch                         ; -> raw-code-address
        _this_quotation_set_raw_code_address

        _pc
        _rfrom
        _minus
        _this_quotation_set_raw_code_size

        pop     this_register

        next
endcode

; ### compile-quotation
code compile_quotation, 'compile-quotation', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; quotation -> quotation
        _duptor
        _ primitive_compile_quotation
        _rfrom
        next
endcode

; ### primitive-compile-word
code primitive_compile_word, 'primitive-compile-word' ; symbol -> void

        _dup
        _ symbol_get_locals_count
        _check_fixnum
        mov     [locals_count_], rbx
        _drop

        _dup
        _ symbol_def
        _ compile_quotation             ; -> symbol quotation

        _dup
        _ quotation_code_address
        _pick
        _ symbol_set_code_address

        _ quotation_code_size
        _swap
        _ symbol_set_code_size

        _ forget_locals

        next
endcode

deferred compile_word, 'compile-word', primitive_compile_word

; ### compile-deferred
code compile_deferred, 'compile-deferred'       ; symbol -> void
        _lit tagged_fixnum(16)
        _ initialize_code_block         ; -> symbol tagged-code-address

        _dup
        _check_fixnum
        mov     [pc_], rbx
        _drop

        _over
        _ symbol_set_code_address       ; -> symbol

        ; movabs rax, qword [moffset64]
        _emit_raw_byte 0x48
        _emit_raw_byte 0xa1

        _dup
        _ check_symbol
        add     rbx, SYMBOL_VALUE_OFFSET
        _ emit_raw_qword

        ; jmp rax
        _emit_raw_byte 0xff
        _emit_raw_byte 0xe0

        _lit tagged_fixnum(12)
        _swap
        _ symbol_set_code_size

        next
endcode
