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

%macro  _this_symbol_hashcode 0         ; -- hashcode
        _this_slot2
%endmacro

%macro  _this_symbol_set_hashcode 0     ; hashcode --
        _this_set_slot2
%endmacro

%macro  _symbol_vocab 0                 ; symbol -- vocab
        _slot3
%endmacro

%macro  _this_symbol_vocab 0            ; -- vocab
        _this_slot3
%endmacro

%macro  _this_symbol_set_vocab 0        ; vocab --
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

; ### symbol?
code symbol?, 'symbol?'                 ; handle -- t|f
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_SYMBOL
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-symbol
code error_not_symbol, 'error-not-symbol' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a symbol"
        next
endcode

; ### check-symbol
code check_symbol, 'check-symbol'       ; handle -- symbol
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object|0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_SYMBOL
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_symbol
        next
endcode

; ### <symbol>
code new_symbol, '<symbol>'             ;  name vocab -- symbol
        _lit 5                          ; -- name vocab 5
        _cells                          ; -- name vocab 40
        _dup                            ; -- name vocab 40 40
        _ allocate_object               ; -- name vocab 40 object-address
        push    this_register
        mov     this_register, rbx      ; -- name vocab 40 object-address
        _swap
        _ erase                         ; -- name vocab

        _this_object_set_type OBJECT_TYPE_SYMBOL

        _this_symbol_set_vocab
        _this_symbol_set_name

        _f
        _this_symbol_set_hashcode

        _f
        _this_symbol_set_xt

        pushrbx
        mov     rbx, this_register      ; -- symbol

        ; Return handle.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### symbol-name
code symbol_name, 'symbol-name'         ; symbol -- name
        _ check_symbol
        _symbol_name
        next
endcode

; ### symbol-vocab
code symbol_vocab, 'symbol-vocab'         ; symbol -- vocab
        _ check_symbol
        _symbol_vocab
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
