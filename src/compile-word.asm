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

; ### pc
value pc, 'pc', 0

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

; ### emit-byte
code emit_byte, 'emit-byte'             ; byte --
        _ pc
        _cstore
        _lit 1
        _plusto pc
        next
endcode

; ### emit-dword
code emit_dword, 'emit-dword'           ; dword --
        _ pc
        _lstore
        _lit 4
        _plusto pc
        next
endcode

; ### emit-qword
code emit_qword, 'emit-qword'           ; qword --
        _ pc
        _store
        _lit 8
        _plusto pc
        next
endcode

; ### compile-call
code compile_call, 'compile-call'       ; addr --
        _dup                            ; -- addr addr

        _ pc
        add     rbx, 5
        _ min_int32
        _plus                           ; -- addr addr low

        _ pc
        add     rbx, 5
        _ max_int32
        _plus                           ; -- addr addr low high

        _ between                       ; -- addr -1/0

        _if .1                          ; -- addr

        _lit $0e8
        _ emit_byte                     ; -- addr

        _ pc
        add     rbx, 4
        _minus
        _ emit_dword

        _else .1

        ; -- addr
        _dup
        _ max_int32
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

        _then .1

        next
endcode

; ### compile-literal
code compile_literal, 'compile-literal' ; literal --
        _dup
        _ wrapper?
        _tagged_if .1
        _ wrapped
        _then .1

        _ pushrbx_bytes
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
code compile_inline, 'compile-inline'   ; tagged-code-address tagged-code-size --
        _untag_2_fixnums                ; -- addr size
        _tuck                           ; -- size addr size
        _ pc
        _swap
        _ cmove                         ; -- size
        _plusto pc
        next
endcode

; ### compile-primitive
code compile_primitive, 'compile-primitive' ; symbol --
        _dup
        _ symbol_inline?
        _tagged_if .1
        _dup
        _ symbol_code_address
        _swap
        _ symbol_code_size
        _ compile_inline
        _else .1
        _ symbol_code_address
        _untag_fixnum
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

        _ compile_literal
        _lit call_symbol
        _ compile_call

        next
endcode

; ### compile-quotation
code compile_quotation, 'compile-quotation' ;  quotation -- code-address
        _dup
        _ quotation_array
        _lit precompile_object_xt
        _ map                           ; -- quotation precompiled-array

        _zero
        _over
        _lit add_code_size_xt
        _ each

        ; add size of return instruction
        _oneplus

        _ allocate_executable
        _duptor
        _to pc                          ; -- quotation precompiled-array        r: -- code-address

        _lit compile_pair_xt
        _ each

        _lit $0c3
        _ emit_byte

        _rfetch                         ; -- quotation code-address
        _swap
        _ quotation_set_code_address

        _rfrom                          ; -- code-address

        next
endcode
