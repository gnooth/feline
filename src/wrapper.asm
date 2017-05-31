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

; ### <wrapper>
code new_wrapper, '<wrapper>'           ; obj -- wrapper
; 2 cells: object header, wrapped object
        _lit 2
        _cells
        _dup
        _ allocate_object
        push    this_register
        mov     this_register, rbx
        _swap
        _ erase

        _this_object_set_raw_typecode TYPECODE_WRAPPER

        _this_set_slot1

        pushrbx
        mov     rbx, this_register      ; -- wrapper

        ; return handle
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### wrapper?
code wrapper?, 'wrapper?'               ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_WRAPPER
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### wrapped
code wrapped, 'wrapped'                 ; wrapper -- wrapped-object
        _dup
        _ wrapper?
        _tagged_if .1
        _handle_to_object_unsafe
        _slot1
        _else .1
        _error "not a wrapper"
        _then .1
        next
endcode

; ### literalize
code literalize, 'literalize'           ; obj -- wrapped
        _dup
        _ symbol?
        _tagged_if .1
        _ new_wrapper
        _return
        _then .1

        _dup
        _ wrapper?
        _tagged_if .2
        _ new_wrapper
        _return
        _then .2

        ; no wrapper needed
        next
endcode

; ### wrapper>string
code wrapper_to_string, 'wrapper>string'        ; wrapper -- string
        _quote "' "
        _ string_to_sbuf
        _swap
        _ wrapped
        _ object_to_string
        _over
        _ sbuf_append_string
        _ sbuf_to_string
        next
endcode
