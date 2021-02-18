; Copyright (C) 2021 Peter Graves <gnooth@gmail.com>

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

; 4 cells: object header, name, type, index
%define LVAR_SIZE                       4 * BYTES_PER_CELL

%define LVAR_NAME_OFFSET                8
%define LVAR_TYPE_OFFSET                16
%define LVAR_INDEX_OFFSET               24

; ### lvar?
code lvar?, 'lvar?'                     ; x -> x/nil
; If x is an lvar, returns x unchanged, otherwise returns nil.
        cmp     bl, HANDLE_TAG
        jne     .no
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_LVAR
        jne     .no
        next
.no:
%if NIL = 0
        xor     ebx, ebx
%else
        mov     ebx, NIL
%endif
        next
endcode

; ### check_lvar
code check_lvar, 'check_lvar'           ; lvar -> ^lvar
        cmp     bl, HANDLE_TAG
        jne     .error2
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]
        cmp     word [rbx], TYPECODE_LVAR
        jne     .error1
        next
.error1:
        mov     rbx, rax
.error2:
        _ error_not_lvar
        next
endcode

; ### verify-lvar
code verify_lvar, 'verify-lvar'         ; lvar -> lvar
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     .error
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_LVAR
        jne     .error
        next
.error:
        _ error_not_lvar
        next
endcode

; ### error-not-lvar
code error_not_lvar, 'error-not-lvar'   ; x ->
        _quote "an lvar"
        _ format_type_error
        next
endcode

; ### make-lvar
code make_lvar, 'make-lvar'             ; void -> lvar

        mov     arg0_register, LVAR_SIZE
        _ feline_malloc                 ; returns address in rax

        mov     qword [rax], TYPECODE_LVAR
        mov     qword [rax + LVAR_NAME_OFFSET], NIL
        mov     qword [rax + LVAR_TYPE_OFFSET], NIL
        mov     qword [rax + LVAR_INDEX_OFFSET], NIL
        _dup
        mov     rbx, rax

        ; return handle
        _ new_handle                    ; -> handle

        next
endcode

; ### lvar-name
code lvar_name, 'lvar-name'             ; lvar -> string/nil
        _ check_lvar
        mov     rbx, [rbx + LVAR_NAME_OFFSET]
        next
endcode

; ### lvar-type
code lvar_type, 'lvar-type'             ; lvar -> type/nil
        _ check_lvar
        mov     rbx, [rbx + LVAR_TYPE_OFFSET]
        next
endcode

; ### lvar-index
code lvar_index, 'lvar-index'           ; lvar -> index/nil
        _ check_lvar
        mov     rbx, [rbx + LVAR_INDEX_OFFSET]
        next
endcode
