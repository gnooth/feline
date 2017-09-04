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

; ### allocate-executable
code allocate_executable, 'allocate-executable' ; raw-size -- raw-address

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

; ### free-executable
code free_executable, 'free-executable'         ; raw-address --

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
        pushrbx
        mov     rbx, [pc_]
%endmacro

; ### precompile-object
code precompile_object, 'precompile-object' ; object -- pair
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
code add_code_size, 'add-code-size'     ; accum pair -- accum
; FIXME arbitrary for now
        _drop
        _lit 25
        _plus
        next
endcode

; ### emit_byte
code emit_byte, 'emit_byte', SYMBOL_INTERNAL    ; byte --
        _pc
        _cstore
        add     qword [pc_], 1
        next
endcode

; ### emit_dword
code emit_dword, 'emit_dword', SYMBOL_INTERNAL  ; dword --
        _pc
        _lstore
        add     qword [pc_], 4
        next
endcode

; ### emit_qword
code emit_qword, 'emit_qword', SYMBOL_INTERNAL  ; qword --
        _pc
        _store
        add     qword [pc_], 8
        next
endcode

%define MIN_INT32       -2147483648

%define MAX_INT32       2147483647

; ### min-int32
feline_constant min_int32, 'min-int32', tagged_fixnum(MIN_INT32)

; ### max-int32
feline_constant max_int32, 'max-int32', tagged_fixnum(MAX_INT32)

; ### raw_int32?
code raw_int32?, 'raw_int32?'           ; untagged-fixnum -- ?
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
code int32?, 'int32?'                   ; tagged-fixnum -- ?
        _dup_fixnum?_if .1
        _untag_fixnum
        _ raw_int32?
        _else .1
        mov     ebx, f_value
        _then .1
        next
endcode

; ### compile-call
code compile_call, 'compile-call'       ; raw-address --
        _dup
        _pc
        add     rbx, 5
        _minus
        _ raw_int32?
        _tagged_if .1
        _lit $0e8
        _ emit_byte                     ; -- raw-address
        _pc
        add     rbx, 4
        _minus
        _ emit_dword
        _return
        _then .1

        ; -- raw-address
        _dup
        _lit MAX_INT32
        _ult
        _if .2
        _lit $0b8
        _ emit_byte
        _ emit_dword
        _else .2
        _lit $48
        _ emit_byte
        _lit $0b8
        _ emit_byte
        _ emit_qword
        _then .2

        _lit $0ff
        _ emit_byte
        _lit $0d0
        _ emit_byte

        next
endcode

%define PUSHRBX_BYTES   $0f86d8d48f85d8948

; ### compile-literal
code compile_literal, 'compile-literal' ; literal --
        _dup
        _ wrapper?
        _tagged_if .1
        _ wrapped
        _then .1

        _lit PUSHRBX_BYTES
        _ emit_qword
        _dup
        _lit $100000000
        _ult
        _if .2
        _lit $0bb
        _ emit_byte
        _ emit_dword
        _else .2
        _lit $48
        _ emit_byte
        _lit $0bb
        _ emit_byte
        _ emit_qword
        _then .2
        next
endcode

; ### compile-inline
code compile_inline, 'compile-inline'   ; raw-code-address raw-code-size --
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
code compile_primitive, 'compile-primitive' ; symbol --
        _dup
%ifdef DEBUG
        _ symbol_always_inline?
%else
        _ symbol_inline?
%endif
        _tagged_if .1
        _dup
        _ symbol_raw_code_address
        _swap
        _ symbol_raw_code_size
        _ compile_inline
        _else .1
        _ symbol_raw_code_address
        _ compile_call
        _then .1
        next
endcode

; ### compile-pair
code compile_pair, 'compile-pair'       ; pair --
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

; ### compile-quotation-internal
code compile_quotation_internal, 'compile-quotation-internal'     ; quotation --

        _ check_quotation

        push    this_register
        mov     this_register, rbx
        poprbx                          ; --

        _this_quotation_array
        _lit S_precompile_object
        _ map_array                     ; -- precompiled-array

        _zero
        _over
        _lit S_add_code_size
        _ array_each

        ; add size of return instruction
        _oneplus

        _ allocate_executable
        _duptor
        mov     [pc_], rbx
        poprbx                          ; -- precompiled-array          r: -- raw-code-address

        _lit S_compile_pair
        _ array_each

        _lit $0c3
        _ emit_byte

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
code compile_quotation, 'compile-quotation'     ; quotation -- quotation
        _duptor
        _ compile_quotation_internal
        _rfrom
        next
endcode

; ### compile-word
code compile_word, 'compile-word'       ; symbol --
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
