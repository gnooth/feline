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

; 10 cells: object header, name, vocab-name, hashcode, xt, def, props, value, code address, code size

%macro  _symbol_name 0                  ; symbol -- name
        _slot1
%endmacro

%macro  _this_symbol_name 0             ; -- name
        _this_slot1
%endmacro

%macro  _this_symbol_set_name 0         ; name --
        _this_set_slot1
%endmacro

%macro  _symbol_vocab_name 0            ; symbol -- vocab-name
        _slot2
%endmacro

%macro  _this_symbol_vocab_name 0       ; -- vocab-name
        _this_slot2
%endmacro

%macro  _this_symbol_set_vocab_name 0   ; vocab-name --
        _this_set_slot2
%endmacro

%macro  _symbol_hashcode 0              ; symbol -- hashcode
        _slot3
%endmacro

%macro  _this_symbol_hashcode 0         ; -- hashcode
        _this_slot3
%endmacro

%macro  _this_symbol_set_hashcode 0     ; hashcode --
        _this_set_slot3
%endmacro

%macro  _symbol_xt 0                    ; symbol -- xt
        _slot4
%endmacro

%macro  _symbol_set_xt 0                ; xt symbol --
        _set_slot4
%endmacro

%macro  _this_symbol_xt 0               ; -- xt
        _this_slot4
%endmacro

%macro  _this_symbol_set_xt 0           ; xt --
        _this_set_slot4
%endmacro

%macro  _symbol_def 0                   ; symbol -- definition
        _slot5
%endmacro

%macro  _symbol_set_def 0               ; definition symbol --
        _set_slot5
%endmacro

%macro  _this_symbol_def 0              ; -- definition
        _this_slot5
%endmacro

%macro  _this_symbol_set_def 0          ; definition --
        _this_set_slot5
%endmacro

%macro  _symbol_props 0
        _slot6
%endmacro

%macro  _symbol_set_props 0             ; props symbol --
        _set_slot6
%endmacro

%macro  _this_symbol_props 0            ; -- props
        _this_slot6
%endmacro

%macro  _this_symbol_set_props 0        ; props --
        _this_set_slot6
%endmacro

%macro  _symbol_value 0                 ; symbol -- value
        _slot 7
%endmacro

%macro  _this_symbol_set_value 0        ; value --
        _this_set_slot 7
%endmacro

%macro  _symbol_code_address 0          ; symbol -- code-address
        _slot 8
%endmacro

%macro  _symbol_set_code_address 0      ; code-address symbol --
        _set_slot 8
%endmacro

%macro  _this_symbol_set_code_address 0 ; code-address --
        _this_set_slot 8
%endmacro

%macro  _symbol_code_size 0             ; symbol -- code-size
        _slot 9
%endmacro

%macro  _symbol_set_code_size 0         ; code-size symbol --
        _set_slot 9
%endmacro

%macro  _this_symbol_set_code_size 0    ; code-size --
        _this_set_slot 9
%endmacro

; ### symbol?
code symbol?, 'symbol?'                 ; x -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _?dup_if .2
        _object_type                    ; -- object-type
        _eq?_literal OBJECT_TYPE_SYMBOL
        _return
        _then .2
        ; Empty handle.
        _f
        _return
        _then .1

        ; Not a handle. Make sure address is in a permissible range.
        _dup
        _ in_static_data_area?
        _zeq_if .3
        ; Address is not in a permissible range.
        ; -- x
        mov     ebx, f_value
        _return
        _then .3

        ; -- object
        _object_type                    ; -- object-type
        _eq?_literal OBJECT_TYPE_SYMBOL

        next
endcode

; ### error-not-symbol
code error_not_symbol, 'error-not-symbol' ; x --
        _error "not a symbol"
        next
endcode

; ### verify_unboxed_symbol
subroutine verify_unboxed_symbol        ; symbol -- symbol
        ; Make sure address is in a permissible range.
        _dup
        _ in_static_data_area?
        _zeq_if .1
        ; Address is not in a permissible range.
        _ error_not_symbol
        _return
        _then .1

        _dup
        _object_type                    ; -- object object-type
        cmp     rbx, OBJECT_TYPE_SYMBOL
        poprbx
        jne .2
        _return
.2:
        _ error_not_symbol
        next
endsub

; ### check_symbol
subroutine check_symbol                 ; handle-or-symbol -- unboxed-symbol
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- object/0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_SYMBOL
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _ error_not_symbol
        _then .1

        ; Not a handle.
        _ verify_unboxed_symbol

        ret
endsub

; ### <symbol>
code new_symbol, '<symbol>'             ; name vocab -- symbol
; 10 cells: object header, name, vocab-name, hashcode, xt, def, props, value, code address, code size

        _lit 10
        _ allocate_cells                ; -- name vocab object-address

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- name vocab

        _this_object_set_type OBJECT_TYPE_SYMBOL

        _tuck
        _ vocab_name
        _this_symbol_set_vocab_name     ; -- vocab name

        _this_symbol_set_name           ; -- vocab

        _this_symbol_name
        _ force_hashcode
        _this_symbol_vocab_name
        _ force_hashcode
        _ hash_combine
        _this_symbol_set_hashcode

        _f
        _this_symbol_set_xt

        _f
        _this_symbol_set_def

        _f
        _this_symbol_set_props

        _f
        _this_symbol_set_value

        _f
        _this_symbol_set_code_address

        _f
        _this_symbol_set_code_size

        pushrbx
        mov     rbx, this_register      ; -- vocab symbol
        pop     this_register

        _ new_handle                    ; -- vocab handle

        _swap
        _dupd                           ; -- handle handle vocab
        _ vocab_add_symbol              ; -- handle

        next
endcode

; ### create-symbol
code create_symbol, 'create-symbol'     ; name vocab -- symbol
; REVIEW does not check for redefinition

        _ lookup_vocab
        _dup
        _tagged_if_not .1
        _error "no such vocab"
        _then .1                        ; -- name vocab

        _ new_symbol                    ; -- symbol

        _dup
        _ new_wrapper
        _ one_quotation
        _over
        _ symbol_set_def                ; -- handle

        _dup
        _ compile_word

        next
endcode

; ### symbol-equal?
code symbol_equal?, 'symbol-equal?'
        _2drop
        _f
        next
endcode

; ### symbol-name
code symbol_name, 'symbol-name'         ; symbol -- name
        _ check_symbol
        _symbol_name
        next
endcode

; ### symbol-hashcode
code symbol_hashcode, 'symbol-hashcode' ; symbol -- hashcode
        _ check_symbol
        _symbol_hashcode
        next
endcode

; ### symbol-vocab-name
code symbol_vocab_name, 'symbol-vocab-name' ; symbol -- vocab-name
        _ check_symbol
        _symbol_vocab_name
        next
endcode

; ### symbol-xt
code symbol_xt, 'symbol-xt'             ; symbol -- xt
        _ check_symbol
        _symbol_xt
        next
endcode

; ### symbol-set-xt
code symbol_set_xt, 'symbol-set-xt'     ; xt symbol --
        _ check_symbol
        _symbol_set_xt
        next
endcode

; ### symbol-def
code symbol_def, 'symbol-def'           ; symbol -- definition
        _ check_symbol
        _symbol_def
        next
endcode

; ### symbol-set-def
code symbol_set_def, 'symbol-set-def'   ; definition symbol --
        _ check_symbol
        _symbol_set_def
        next
endcode

; ### symbol-props
code symbol_props, 'symbol-props'       ; symbol -- props
        _ check_symbol
        _symbol_props
        next
endcode

; ### symbol-prop
code symbol_prop, 'symbol-prop'         ; key symbol -- value
        _ check_symbol
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- key

        _this_symbol_props
        _dup
        _tagged_if .1
        _ at_
        _else .1
        _nip
        _then .1

        pop     this_register
        next
endcode

; ### symbol-set-prop
code symbol_set_prop, 'symbol-set-prop' ; value key symbol --
        _ check_symbol
        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- value key

        _this_symbol_props
        _tagged_if_not .1
        _lit 2
        _ new_hashtable_untagged
        _this_symbol_set_props
        _then .1

        _this_symbol_props
        _ set_at

        pop     this_register
        next
endcode

; ### symbol-help
code symbol_help, 'symbol-help'         ; symbol -- content/f
        _quote "help"
        _swap
        _ symbol_prop
        next
endcode

; ### symbol-set-help
code symbol_set_help, 'symbol-set-help' ; content symbol --
        _quote "help"
        _swap
        _ symbol_set_prop
        next
endcode

; ### symbol-primitive?
code symbol_primitive?, 'symbol-primitive?' ; symbol -- ?
        _quote "primitive"
        _swap
        _ symbol_prop
        next
endcode

; ### symbol-inline?
code symbol_inline?, 'symbol-inline?'   ; symbol -- ?
        _quote "inline"
        _swap
        _ symbol_prop
        next
endcode

; ### symbol-value
code symbol_value, 'symbol-value'       ; symbol -- value
        _ check_symbol
        _slot 7
        next
endcode

; ### symbol-set-value
code symbol_set_value, 'symbol-set-value' ; value symbol --
        _ check_symbol
        _set_slot 7
        next
endcode

; ### symbol-code-address
code symbol_code_address, 'symbol-code-address' ; symbol -- code-address/f
; The code address is stored untagged.
        _ check_symbol
        _symbol_code_address
        _tag_fixnum
        next
endcode

; ### symbol-set-code-address
code symbol_set_code_address, 'symbol-set-code-address' ; code-address symbol --
; The code address is stored untagged.
        _ check_symbol
        _verify_fixnum [rbp]
        _untag_fixnum qword [rbp]
        _symbol_set_code_address
        next
endcode

; ### symbol-code-size
code symbol_code_size, 'symbol-code-size' ; symbol -- code-size/f
; The code size is stored untagged.
        _ check_symbol
        _symbol_code_size
        _tag_fixnum
        next
endcode

; ### symbol-set-code-size
code symbol_set_code_size, 'symbol-set-code-size' ; code-size symbol --
; The code size is stored untagged.
        _ check_symbol
        _verify_fixnum [rbp]
        _untag_fixnum qword [rbp]
        _symbol_set_code_size
        next
endcode

; ### call-symbol
code call_symbol, 'call-symbol'         ; symbol --
        _dup
        _ symbol_code_address
        _dup
        _tagged_if .1
        _nip

        ; REVIEW _untag_fixnum
        _check_fixnum

        mov     rax, rbx
        poprbx
        call    rax
        _return
        _else .1
        _drop
        _then .1                        ; -- symbol

        _dup
        _ symbol_def
        _dup
        _tagged_if .2
        _nip
        _ call_quotation
        _return
        _else .2
        _drop
        _then .2

        _ undefined

        next
endcode
