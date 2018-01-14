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

%define thread_raw_sp0_slot     qword [rbx + BYTES_PER_CELL]

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

; ### thread_set_raw_sp0
code thread_set_raw_sp0, 'thread_set_raw_sp0', SYMBOL_INTERNAL  ; sp0 thread --
        _ check_thread
        _thread_set_raw_sp0
        next
endcode

; ### thread-sp0
code thread_sp0, 'thread-sp0'           ; thread -- sp0
        _ check_thread
        _thread_raw_sp0
        _tag_fixnum
        next
endcode

; ### thread-quotation
code thread_quotation, 'thread-quotation'       ; thread -- quotation
        _ check_thread
        _thread_quotation
        next
endcode

; ### current-thread
code current_thread, 'current-thread'   ; -- thread

%ifdef WIN64
        extern os_current_thread
        xcall os_current_thread
        _dup
        mov     rbx, rax
%else
        _error "unimplemented"
%endif

        next
endcode

; ### new_thread
code new_thread, 'new_thread', SYMBOL_INTERNAL  ; -- thread
        _lit 6
        _ raw_allocate_cells
        mov     qword [rbx], TYPECODE_THREAD
        _ new_handle
        next
endcode

; ### <thread>
code make_thread, '<thread>'            ; quotation -- thread
        _ new_thread
        _duptor

        _ check_thread

        _tuck
        _thread_set_quotation

%ifdef WIN64
        extern os_thread_initialize_data_stack
        xcall   os_thread_initialize_data_stack ; returns sp0 in rax
        _dup
        mov     rbx, rax
        _swap
        _thread_set_raw_sp0
%endif

        _rfrom
        next
endcode

asm_global all_threads_, f_value

; ### all-threads
code all_threads, 'all-threads'         ; -- vector
        pushrbx
        mov     rbx, [all_threads_]
        next
endcode

; ### initialize_primordial_thread
code initialize_primordial_thread, 'initialize_primordial_thread', SYMBOL_INTERNAL
        _lit 8
        _ new_vector_untagged
        mov     [all_threads_], rbx
        poprbx
        _lit all_threads_
        _ gc_add_root

        _ new_thread

        pushrbx
        mov     rbx, [sp0_]
        _over
        _ thread_set_raw_sp0            ; -- vector

%ifdef WIN64
        mov     arg0_register, rbx

        extern os_initialize_primordial_thread
        xcall   os_initialize_primordial_thread
%endif

        _ all_threads
        _ vector_push

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
        mov     rbp, thread_raw_sp0_slot

        _dup
        _thread_quotation

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
