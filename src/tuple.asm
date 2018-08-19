; Copyright (C) 2016-2018 Peter Graves <gnooth@gmail.com>

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

; ### error-not-tuple
code error_not_tuple, 'error-not-tuple' ; x --
        ; REVIEW
        _error "not a tuple"
        next
endcode

; ### tuple-instance?
code tuple_instance?, 'tuple-instance?' ; x -- ?
        _ deref
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, LAST_BUILTIN_TYPECODE
        jbe     .1
        mov     ebx, t_value
        next
.1:
        mov     ebx, f_value
        next
endcode

; ### check_tuple_instance
code check_tuple_instance, 'check_tuple_instance', SYMBOL_INTERNAL
; handle -- raw-tuple-instance
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, LAST_BUILTIN_TYPECODE
        jbe     .error
        _nip
        next
.error:
        _drop
        _ error_not_tuple
        next
endcode

; ### tuple-size
code tuple_size, 'tuple-size'           ; tuple -- size
; return number of named slots

        _ check_tuple_instance          ; -> raw-tuple-instance

tuple_size_unchecked:

        _object_raw_typecode
        _ raw_typecode_to_type
        _ type_layout
        _ array_length

        next
endcode

; ### make-instance
code make_instance, 'make-instance'     ; type -> instance

        _ verify_type

        _dup
        _ type_layout
        _ array_raw_length

        ; slot 0 is object header
        add     rbx, 1

        _cells
        _ raw_allocate                  ; -> type address

        _tor                            ; -> type

        _dup
        _ type_raw_typecode             ; -> type raw-typecode

        ; store raw typecode in object header
        _rfetch
        _store                          ; -> type

        _ type_layout
        _ array_raw_length

        mov     rcx, rbx                ; number of slots in rcx
        poprbx

        jrcxz   .2

        mov     eax, f_value

        _rfetch
        add     rbx, BYTES_PER_CELL

        mov     rdx, rbx
        poprbx

 .1:
        mov     [rdx], rax
        add     rdx, BYTES_PER_CELL
        dec     rcx
        jnz     .1

.2:
        _rfrom

        _ new_handle

        next
endcode

; ### tuple>string
code tuple_to_string, 'tuple>string'    ; tuple -> void
        _ check_tuple_instance

        push    this_register
        mov     this_register, rbx
        poprbx

        _quote "tuple{ "
        _ string_to_sbuf

        _this
        _ tuple_size_unchecked
        _check_fixnum
        _register_do_times .1

        _raw_loop_index
        add     rbx, 1
        _this_nth_slot
        _ object_to_string
        _over
        _ sbuf_append_string
        _tagged_char(32)
        _over
        _ sbuf_push

        _loop .1

        pop     this_register

        _tagged_char('}')
        _over
        _ sbuf_push
        _ sbuf_to_string

        next
endcode
