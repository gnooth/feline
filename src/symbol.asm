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

%macro  _this_symbol_set_code_address 0 ; code-address --
        _this_set_slot 8
%endmacro

; ### symbol?
code symbol?, 'symbol?'                 ; handle -- ?
        _lit OBJECT_TYPE_SYMBOL
        _ type?
        next
endcode

; ### error-not-symbol
code error_not_symbol, 'error-not-symbol' ; x --
        _error "not a symbol"
        next
endcode

; ### check-symbol
code check_symbol, 'check-symbol'       ; handle -- symbol
        _ unhandle                      ; -- object-address
        cmp     word [rbx], OBJECT_TYPE_SYMBOL
        jne     .error
        _return
.error:
        _ error_not_symbol
        next
endcode

; ### <symbol>
code new_symbol, '<symbol>'             ; name vocab -- symbol
; 9 cells: object header, name, vocab-name, hashcode, xt, def, props, value, code address

        _lit 9
        _ allocate_cells                ; -- object-address

        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_type OBJECT_TYPE_SYMBOL

        _ vocab_name
        _this_symbol_set_vocab_name

        _this_symbol_set_name

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

        pushrbx
        mov     rbx, this_register      ; -- symbol

        ; Return handle.
        _ new_handle                    ; -- handle

        pop     this_register
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
code symbol_code_address, 'symbol-code-address' ; symbol -- code-address
        _ check_symbol
        _slot 8
        next
endcode

; ### symbol-set-code-address
code symbol_set_code_address, 'symbol-set-code-address' ;  code-address symbol --
        _ check_symbol
        _set_slot 8
        next
endcode

; ### symbol-code
code symbol_code, 'symbol-code'         ; symbol -- code-address inline-size
; REVIEW
; Returned values are untagged.
        _dup
        _ symbol_xt
        _dup
        _tagged_if .1
        _nip
        _dup
        _tocode
        _swap
        _toinline
        _cfetch
        _return
        _else .1
        _drop
        _then .1

        _dup
        _ symbol_def
        _dup
        _tagged_if .2
        _nip
        _ callable_code_address
        _zero
        _return
        _else .2
        _drop
        _then .2                        ; -- symbol

        _ undefined

        next
endcode

; ### call-symbol
code call_symbol, 'call-symbol'         ; symbol --
        _dup
        _ symbol_code_address
        _dup
        _tagged_if .1
        _nip
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
