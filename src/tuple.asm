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

%macro _tuple_layout_of 0               ; tuple -- layout
        _slot 1
%endmacro

; ### tuple-size
code tuple_size, 'tuple-size'           ; tuple -- size
; return number of named slots

        _ check_tuple_instance

tuple_size_unchecked:

        _tuple_layout_of
        _ array_second

        next
endcode

; ### tuple>string
code tuple_to_string, 'tuple>string'    ; tuple --
        _ check_tuple_instance

        push    this_register
        mov     this_register, rbx
        poprbx                          ; --

        _quote "tuple{ "
        _ string_to_sbuf

        _this_slot 1                    ; -- layout
        _dup
        _ first
        _ object_to_string
        _pick
        _ sbuf_append_string
        _tagged_char(32)
        _pick
        _ sbuf_push

        _ second
        _untag_fixnum

        _register_do_times .1

        _raw_loop_index
        add     rbx, 2
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
