; Copyright (C) 2017-2018 Peter Graves <gnooth@gmail.com>

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

; 4 cells: object header, sp0, lp0, callable

%macro  _thread_raw_sp0 0               ; thread -- id
        _slot1
%endmacro

%macro  _thread_set_raw_sp0 0           ; id thread --
        _set_slot1
%endmacro

%macro  _thread_raw_lp0 0               ; thread -- handle
        _slot2
%endmacro

%macro  _thread_set_raw_lp0 0           ; handle thread --
        _set_slot2
%endmacro

; ### thread?
code thread?, 'thread?'                 ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_THREAD
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### error-not-thread
code error_not_thread, 'error-not-thread'       ; x --
        ; REVIEW
        _error "not an thread"
        next
endcode

; ### check_thread
code check_thread, 'check_thread', SYMBOL_INTERNAL      ; handle -- thread
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_THREAD
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_thread
        next
endcode

; ### verify-thread
code verify_thread, 'verify-thread'     ; handle -- handle
; returns argument unchanged
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_THREAD
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_thread
        next
endcode

code current_thread, 'current-thread'   ; -- thread
        ; needs code!
        next
endcode

code new_thread, '<thread>'             ; -- thread
        _lit 4
        _ raw_allocate_cells            ; -- address
        mov     qword [rbx], TYPECODE_THREAD
        _ new_handle
        next
endcode

; extern os_create_thread

; code thread_create, 'thread-create'     ; thread --
;         mov     arg0_register, rbx
;         _drop
;         xcall   os_create_thread
;         next
; endcode

; ### thread>string
code thread_to_string, 'thread>string'  ; thread -- string
        _ verify_thread
        _ object_address                ; -- tagged-fixnum
        _ fixnum_to_hex
        _quote "#<thread 0x%s>"
        _ format
        next
endcode
