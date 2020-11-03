; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

; 2 cells: object header, wrapped object
%define WRAPPER_SIZE                    2 * BYTES_PER_CELL

%define WRAPPER_WRAPPED_OFFSET          8

; ### check_wrapper
code check_wrapper, 'check_wrapper'     ; wrapper -> ^wrapper
        cmp     bl, HANDLE_TAG
        jne     error_not_wrapper
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]
        cmp     word [rbx], TYPECODE_WRAPPER
        jne     .error
        next
.error:
        mov     rbx, rax
        jmp     error_not_wrapper
endcode

; ### error-not-wrapper
code error_not_wrapper, 'error-not-wrapper' ; x ->
        _quote "a wrapper"
        _ format_type_error
        next
endcode

; ### <wrapper>
code new_wrapper, '<wrapper>'           ; object -> wrapper

        mov     arg0_register, WRAPPER_SIZE
        _ feline_malloc                 ; returns address in rax

        mov     qword [rax], TYPECODE_WRAPPER
        mov     qword [rax + WRAPPER_WRAPPED_OFFSET], rbx
        mov     rbx, rax

        ; return handle
        _ new_handle                    ; -> handle

        next
endcode

; ### wrapper?
code wrapper?, 'wrapper?'               ; x -> x/nil
; If x is a wrapper, return x unchanged. If x is not a wrapper, return nil.
        cmp     bl, HANDLE_TAG
        jne     .not_a_wrapper
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_WRAPPER
        jne     .not_a_wrapper
        next
.not_a_wrapper:
        mov     ebx, NIL
        next
endcode

; ### wrapped
code wrapped, 'wrapped'                 ; wrapper -> wrapped
        _ check_wrapper
        mov     rbx, [rbx + WRAPPER_WRAPPED_OFFSET]
        next
endcode

; ### literalize
code literalize, 'literalize'           ; obj -> wrapped
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
code wrapper_to_string, 'wrapper>string' ; wrapper -> string
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
