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

; ### <wrapper>
code new_wrapper, '<wrapper>'           ; obj -- wrapper
; 2 cells: object header, wrapped
        _lit 2
        _cells
        _dup
        _ allocate_object
        push    this_register
        mov     this_register, rbx
        _swap
        _ erase

        _this_object_set_type OBJECT_TYPE_WRAPPER

        _this_set_slot1

        pushrbx
        mov     rbx, this_register      ; -- wrapper

        ; Return handle.
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### wrapper?
code wrapper?, 'wrapper?'               ; handle -- ?
        _lit OBJECT_TYPE_WRAPPER
        _ type?
        next
endcode

; ### wrapped
code wrapped, 'wrapped'                 ; wrapper -- wrapped
        _dup
        _ wrapper?
        _if .1
        _handle_to_object_unsafe
        _slot1
        _else .1
        _error "not a wrapper"
        _then .1
        next
endcode
