; Copyright (C) 2017-2019 Peter Graves <gnooth@gmail.com>

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

; 2 slots: object header, name

asm_global keyword_hashtable_

code keyword_hashtable, 'keyword-hashtable'     ; -- hashtable
        _dup
        mov     rbx, [keyword_hashtable_]
        next
endcode

%macro  _keyword_name 0                 ; keyword -- name
        _slot1
%endmacro

%macro  _this_keyword_set_name 0        ; name --
        _this_set_slot1
%endmacro

; ### keyword?
code keyword?, 'keyword?'               ; x -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_KEYWORD
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### verify-keyword
code verify_keyword, 'verify-keyword'   ; keyword -- keyword
        _dup
        _ keyword?
        _tagged_if_not .1
        _ error_not_keyword
        _then .1
        next
endcode

; ### check_keyword
code check_keyword, 'check_keyword', SYMBOL_INTERNAL      ; x -- keyword
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_KEYWORD
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_keyword
        next
endcode

; ### string>keyword
code string_to_keyword, 'string>keyword'        ; string -- keyword

        _lit 2
        _ raw_allocate_cells            ; -- name raw-object-address

        push    this_register
        mov     this_register, rbx

        mov     rbx, [rbp]              ; -- name name

        _this_object_set_raw_typecode TYPECODE_KEYWORD

        _this_keyword_set_name          ; -- name

        _dup
        mov     rbx, this_register      ; -- name keyword
        pop     this_register

        _ new_handle                    ; -- name handle

        _swap
        _dupd                           ; -- handle handle name
        _ keyword_hashtable
        _ hashtable_set_at              ; -- handle

        next
endcode

; ### intern-keyword
code intern_keyword, 'intern-keyword'   ; string -- keyword
         _dup
        _ keyword_hashtable
        _ hashtable_at_star
        cmp     rbx, f_value
        _drop
        je      .not_found
        _nip
        _return

.not_found:                             ; -- string f
        _drop                           ; -- string
        _ string_to_keyword             ; -- keyword
        next
endcode

; ### keyword-name
code keyword_name, 'keyword-name'       ; keyword -> name
        _ check_keyword
        _keyword_name
        next
endcode

; ### keyword->string
code keyword_to_string, 'keyword->string' ; keyword -> string
        _quote ":"
        _swap
        _ keyword_name
        _ string_append
        next
endcode

; ### keyword-hashcode
code keyword_hashcode, 'keyword-hashcode' ; keyword -> hashcode
        _ object_address
        _untag_fixnum
        shr     rbx, 3
        _tag_fixnum
        next
endcode
