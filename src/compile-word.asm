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

asm_global compile_verbose_, f_value

; ### +v
code verbose_on, '+v'
        mov     qword [compile_verbose_], t_value
        next
endcode

; ### -v
code verbose_off, '-v'
        mov     qword [compile_verbose_], f_value
        next
endcode

; ### compile-verbose?
code compile_verbose?, 'compile-verbose?'       ; -- ?
        pushrbx
        mov     rbx, [compile_verbose_]
        next
endcode

; initialized in initialize_dynamic_code_space (in main.c)
asm_global code_space_, 0
asm_global code_space_free_, 0
asm_global code_space_limit_, 0

; ### code-space
code code_space, 'code-space'
        pushrbx
        mov     rbx, [code_space_]
        _tag_fixnum
        next
endcode

; ### code-space-free
code code_space_free, 'code-space-free'
        pushrbx
        mov     rbx, [code_space_free_]
        _tag_fixnum
        next
endcode

; ### code-space-limit
code code_space_limit, 'code-space-limit'
        pushrbx
        mov     rbx, [code_space_limit_]
        _tag_fixnum
        next
endcode

%define USE_XALLOC

%ifdef USE_XALLOC

; ### xalloc
code xalloc, 'xalloc'                           ; raw-size -- raw-address
        mov     rax, [code_space_free_]

        add     rbx, rax
        cmp     rbx, [code_space_limit_]
        jae     .1

        ; REVIEW
        ; 16-byte alignment
        add     rbx, 0x0f
        and     bl, 0xf0

        mov     [code_space_free_], rbx

        mov     rbx, rax
        _return

.1:
        _ ?nl
        _write "FATAL ERROR: no code space"
        _ nl
        xcall os_bye

        next
endcode

; ### xfree
code xfree, 'xfree'                             ; raw-address --
        ; for now, do nothing
        _drop

        next
endcode

%endif

; ### raw_allocate_executable
code raw_allocate_executable, 'raw_allocate_executable', SYMBOL_INTERNAL
; raw-size -- raw-address

%ifdef USE_XALLOC

        _ xalloc

%else

        mov     arg0_register, rbx
%ifdef WIN64
        xcall   os_allocate_executable
%else
        xcall   os_malloc
%endif
        mov     rbx, rax

%endif

        next
endcode

; ### raw_free_executable
code raw_free_executable, 'raw_free_executable', SYMBOL_INTERNAL
; raw-address --

%ifdef USE_XALLOC

        _ xfree

%else

        mov     arg0_register, rbx
%ifdef WIN64
        xcall   os_free_executable
%else
        xcall   os_free
%endif
        poprbx

%endif

        next
endcode

asm_global pc_, 0

%macro _pc 0
        _dup
        mov     rbx, [pc_]
%endmacro

; ### initialize-code-block
code initialize_code_block, 'initialize-code-block' ; tagged-size -- tagged-address
        _check_fixnum
        _ raw_allocate_executable       ; -- raw-address
        _tag_fixnum
        next
endcode

; ### precompile-object
code precompile_object, 'precompile-object', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; object -- pair
; all values are untagged
        _dup
        _ symbol?
        _tagged_if .1
        _zero                           ; -- symbol 0
        _else .1
        _zero
        _swap                           ; -- 0 literal-value
        _then .1
        _ two_array
        next
endcode

; ### add-code-size
code add_code_size, 'add-code-size', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; accum pair -- accum
; FIXME arbitrary for now
        _drop
        _lit 25
        _plus
        next
endcode

; ### emit_raw_byte
code emit_raw_byte, 'emit_raw_byte', SYMBOL_INTERNAL    ; byte -> void
        mov     rdx, [pc_]
        mov     [rdx], bl
        add     qword [pc_], 1
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

%define MIN_INT32       -2147483648

%define MAX_INT32       2147483647

; ### min-int32
feline_constant min_int32, 'min-int32', tagged_fixnum(MIN_INT32)

; ### max-int32
feline_constant max_int32, 'max-int32', tagged_fixnum(MAX_INT32)

; ### raw_int32?
code raw_int32?, 'raw_int32?'           ; untagged-fixnum -> ?
        cmp     rbx, MIN_INT32
        jl      .1
        cmp     rbx, MAX_INT32
        jg      .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### int32?
code int32?, 'int32?'                   ; tagged-fixnum -> ?
        test    bl, FIXNUM_TAG
        jz      .1
        _untag_fixnum
        jmp     raw_int32?
.1:
        mov     ebx, f_value
        next
endcode

; ### compile-call
code compile_call, 'compile-call', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; raw-address --
        _dup
        _pc
        add     rbx, 5
        _minus
        _ raw_int32?
        _tagged_if .1
        _lit $0e8
        _ emit_raw_byte                 ; -- raw-address
        _pc
        add     rbx, 4
        _minus
        _ emit_raw_dword
        _return
        _then .1

        ; -- raw-address
        _dup
        _lit MAX_INT32
        _ult
        _if .2
        _lit $0b8
        _ emit_raw_byte
        _ emit_raw_dword
        _else .2
        _lit $48
        _ emit_raw_byte
        _lit $0b8
        _ emit_raw_byte
        _ emit_raw_qword
        _then .2

        _lit $0ff
        _ emit_raw_byte
        _lit $0d0
        _ emit_raw_byte

        next
endcode

%define PUSHRBX_BYTES   $0f86d8d48f85d8948

; ### compile-literal
code compile_literal, 'compile-literal', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; literal --
        _dup
        _ wrapper?
        _tagged_if .1
        _ wrapped
        _then .1

        _lit PUSHRBX_BYTES
        _ emit_raw_qword
        _dup
        _lit $100000000
        _ult
        _if .2
        _lit $0bb
        _ emit_raw_byte
        _ emit_raw_dword
        _else .2
        _lit $48
        _ emit_raw_byte
        _lit $0bb
        _ emit_raw_byte
        _ emit_raw_qword
        _then .2
        next
endcode

; ### inline-primitive
code inline_primitive, 'inline-primitive'       ; symbol --

%ifdef DEBUG
        _dup
        _ symbol_inline?
        _tagged_if_not .1
        _error "symbol not inline"
        _return
        _then .1
%endif

        _dup
        _ symbol_raw_code_address
        _swap
        _ symbol_raw_code_size          ; -- raw-code-address raw-code-size

        _oneminus                       ; adjust size to exclude ret instruction
        _tuck                           ; -- size addr size
        _pc
        _swap
        _ cmove                         ; -- size
        add     qword [pc_], rbx
        poprbx
        next
endcode

; ### compile-primitive
code compile_primitive, 'compile-primitive', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; symbol --
        _dup
%ifdef DEBUG
        _ symbol_always_inline?
%else
        _ symbol_inline?
%endif
        _tagged_if .1
        _ inline_primitive
        _else .1
        _ symbol_raw_code_address
        _ compile_call
        _then .1
        next
endcode

; ### compile-pair
code compile_pair, 'compile-pair', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; pair --
        _dup
        _ array_first
        _zeq_if .1
        _ array_second
        _ compile_literal
        _return
        _then .1                        ; -- pair

        _ array_first                   ; -- symbol
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

; ### primitive-compile-quotation
code primitive_compile_quotation, 'primitive-compile-quotation', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; quotation --

        _debug_?enough 1

        _ compile_verbose?
        _tagged_if .1
        _ ?nl
        _quote "primitive-compile-quotation "
        _ write_string
        _dup
        _ dot_object
        _ nl
        _then .1

        _ check_quotation

        push    this_register
        mov     this_register, rbx
        poprbx                          ; --

        _this_quotation_array
        _lit S_precompile_object
        _ map_array                     ; -- precompiled-array

        _ compile_verbose?
        _tagged_if .2
        _ ?nl
        _dup
        _ dot_object
        _ nl
        _then .2

        _zero
        _over
        _lit S_add_code_size
        _ array_each

        ; add size of return instruction
        _oneplus                        ; -- raw-size
        _tag_fixnum

        _ initialize_code_block         ; -- tagged-address

        _check_fixnum
        mov     [pc_], rbx
        poprbx

        _pc
        _tor

        _lit S_compile_pair
        _ array_each

        _lit $0c3
        _ emit_raw_byte

        _rfetch                         ; -- raw-code-address
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
; quotation -- quotation
        _duptor
        _ primitive_compile_quotation
        _rfrom
        next
endcode

; ### primitive-compile-word
code primitive_compile_word, 'primitive-compile-word', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; symbol --
        _dup
        _ symbol_def
        _ compile_quotation             ; -- symbol quotation

        _dup
        _ quotation_code_address
        _pick
        _ symbol_set_code_address

        _ quotation_code_size
        _swap
        _ symbol_set_code_size

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
        _lit 0x48
        _ emit_raw_byte
        _lit 0xa1
        _ emit_raw_byte

        _dup
        _ check_symbol
        add     rbx, SYMBOL_VALUE_OFFSET
        _ emit_raw_qword

        ; jmp rax
        _lit 0xff
        _ emit_raw_byte
        _lit 0xe0
        _ emit_raw_byte

        _lit tagged_fixnum(12)
        _swap
        _ symbol_set_code_size

        next
endcode
