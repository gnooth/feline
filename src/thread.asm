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

; 6 cells: object header, sp0, rp0, lp0, quotation, result

%macro  _thread_raw_sp0 0               ; thread -- sp0
        _slot1
%endmacro

%macro  _thread_set_raw_sp0 0           ; sp0 thread --
        _set_slot1
%endmacro

%macro  _thread_raw_rp0 0               ; thread -- rp0
        _slot2
%endmacro

%macro  _thread_set_raw_rp0 0           ; rp0 thread --
        _set_slot2
%endmacro

%macro  _thread_raw_lp0 0               ; thread -- lp0
        _slot3
%endmacro

%macro  _thread_set_raw_lp0 0           ; lp0 thread --
        _set_slot3
%endmacro

%macro  _thread_quotation 0             ; thread -- quotation
        _slot4
%endmacro

%macro  _thread_set_quotation 0         ; quotation thread --
        _set_slot4
%endmacro

%macro  _thread_result 0                ; thread -- result
        _slot5
%endmacro

%macro  _thread_set_result 0            ; result thread --
        _set_slot5
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

; ### current-thread
code current_thread, 'current-thread'   ; -- thread
        _error "current-thread needs code!"
        next
endcode

; ### <thread>
code new_thread, '<thread>'             ; -- thread
        _lit 6
        _ raw_allocate_cells            ; -- address
        mov     qword [rbx], TYPECODE_THREAD

%ifdef WIN64
        extern os_thread_initialize_data_stack
        xcall   os_thread_initialize_data_stack ; returns tos in rax
        _dup
        mov     rbx, rax
        _over
        _thread_set_raw_sp0
%endif

        _ new_handle
        next
endcode

extern os_create_thread

; ### thread-create
code thread_create, 'thread-create'     ; thread --

%ifdef WIN64
        mov     arg0_register, rbx
        _drop
        xcall   os_create_thread
%endif

        next
endcode

; ### thread_run_internal
code thread_run_internal, 'thread_run_internal', SYMBOL_INTERNAL
; called from C with handle of thread object in arg0_register

        push    rbp

        ; set up data stack
        mov     rbx, arg0_register      ; handle of thread object in rbx
        _ deref                         ; object address in rbx
        mov     rbp, qword [rbx + BYTES_PER_CELL]

        ; FIXME
        _quotation .1
        _lit tagged_fixnum(42)
        _lit tagged_fixnum(17)
        _ generic_plus
        _ dot_object
        _ nl
        _quote "Hello!"
        _ write_string
        _end_quotation .1

        _ call_quotation

        pop     rbp
        next
endcode

; ### thread>string
code thread_to_string, 'thread>string'  ; thread -- string
        _ verify_thread

        ; REVIEW
        _ object_address                ; -- tagged-fixnum
        _ fixnum_to_hex
        _quote "#<thread 0x%s>"
        _ format

        next
endcode
