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

; 14 slots:

%define thread_slot_raw_thread_id        1
%define thread_slot_raw_thread_handle    2
%define thread_slot_raw_sp0              3
%define thread_slot_raw_rp0              4
%define thread_slot_raw_lp0              5
%define thread_slot_quotation            6
%define thread_slot_result               7
%define thread_slot_thread_locals        8

%define thread_slot_saved_rbx            9
%define thread_slot_saved_rsp           10
%define thread_slot_saved_rbp           11
%define thread_slot_saved_r14           12

%define thread_slot_state               13

%define thread_slot_debug_name          14

%define thread_raw_thread_id_slot       qword [rbx + bytes_per_cell * thread_slot_raw_thread_id]
%define thread_raw_thread_handle_slot   qword [rbx + bytes_per_cell * thread_slot_raw_thread_handle]
%define thread_raw_sp0_slot             qword [rbx + bytes_per_cell * thread_slot_raw_sp0]
%define thread_raw_rp0_slot             qword [rbx + bytes_per_cell * thread_slot_raw_rp0]
%define thread_raw_lp0_slot             qword [rbx + bytes_per_cell * thread_slot_raw_lp0]

%define thread_state_slot               qword [rbx + bytes_per_cell * thread_slot_state]

%define THREAD_REGISTERS_OFFSET         bytes_per_cell * thread_slot_saved_rbx

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

; ### thread_set_raw_thread_id
code thread_set_raw_thread_id, 'thread_set_raw_thread_id', SYMBOL_INTERNAL
; raw-thread-id thread --
        _ check_thread
        _set_slot thread_slot_raw_thread_id
        next
endcode

; ### thread-id
code thread_id, 'thread-id'             ; thread -- thread-id
        _ check_thread
        _slot thread_slot_raw_thread_id
        _ normalize
        next
endcode

%ifdef WIN64
; ### thread_set_raw_thread_handle
code thread_set_raw_thread_handle, 'thread_set_raw_thread_handle', SYMBOL_INTERNAL
; raw-thread-id thread --
        _ check_thread
        _set_slot thread_slot_raw_thread_handle
        next
endcode
%endif

; ### thread_raw_sp0
code thread_raw_sp0, 'thread_raw_sp0', SYMBOL_INTERNAL  ; -- raw-sp0
        _ check_thread
        _slot thread_slot_raw_sp0
        next
endcode

; ### thread_set_raw_sp0
code thread_set_raw_sp0, 'thread_set_raw_sp0', SYMBOL_INTERNAL  ; raw-sp0 thread --
        _ check_thread
        _set_slot thread_slot_raw_sp0
        next
endcode

; ### thread-sp0
code thread_sp0, 'thread-sp0'           ; thread -- sp0
        _ thread_raw_sp0
        _tag_fixnum
        next
endcode

; ### thread_raw_rp0
code thread_raw_rp0, 'thread_raw_rp0', SYMBOL_INTERNAL  ; -- raw-rp0
        _ check_thread
        _slot thread_slot_raw_rp0
        next
endcode

; ### thread_set_raw_rp0
code thread_set_raw_rp0, 'thread_set_raw_rp0', SYMBOL_INTERNAL  ; raw-rp0 thread --
        _ check_thread
        _set_slot thread_slot_raw_rp0
        next
endcode

; ### thread-rp0
code thread_rp0, 'thread-rp0'           ; thread -- rp0
        _ thread_raw_rp0
        _tag_fixnum
        next
endcode

; ### thread_raw_lp0
code thread_raw_lp0, 'thread_raw_lp0', SYMBOL_INTERNAL  ; -- raw-lp0
        _ check_thread
        _slot thread_slot_raw_lp0
        next
endcode

; ### thread_set_raw_lp0
code thread_set_raw_lp0, 'thread_set_raw_lp0', SYMBOL_INTERNAL  ; raw-lp0 thread --
        _ check_thread
        _set_slot thread_slot_raw_lp0
        next
endcode

; ### thread-lp0
code thread_lp0, 'thread-lp0'           ; thread -- lp0
        _ thread_raw_lp0
        _tag_fixnum
        next
endcode

; ### thread-quotation
code thread_quotation, 'thread-quotation'       ; thread -- quotation
        _ check_thread
        _slot thread_slot_quotation
        next
endcode

; ### thread-result
code thread_result, 'thread-result'     ; thread -- result
        _ check_thread
        _slot thread_slot_result
        next
endcode

; ### thread_set_result
code thread_set_result, 'thread_set_result', SYMBOL_INTERNAL    ; result thread --
        _ check_thread
        _set_slot thread_slot_result
        next
endcode

; ### thread_saved_rbx
code thread_saved_rbx, 'thread_saved_rbx', SYMBOL_INTERNAL      ; thread -- saved-rbx
        _ check_thread
        _slot thread_slot_saved_rbx
        next
endcode

; ### thread_saved_rsp
code thread_saved_rsp, 'thread_saved_rsp', SYMBOL_INTERNAL      ; thread -- saved-rsp
        _ check_thread
        _slot thread_slot_saved_rsp
        next
endcode

; ### thread_saved_rbp
code thread_saved_rbp, 'thread_saved_rbp', SYMBOL_INTERNAL      ; thread -- saved-rbp
        _ check_thread
        _slot thread_slot_saved_rbp
        next
endcode

; ### thread_saved_r14
code thread_saved_r14, 'thread_saved_r14', SYMBOL_INTERNAL      ; thread -- saved-r14
        _ check_thread
        _slot thread_slot_saved_r14
        next
endcode

; REVIEW
special THREAD_NEW,      'THREAD_NEW'
special THREAD_STARTING, 'THREAD_STARTING'
special THREAD_STOPPED,  'THREAD_STOPPED'
special THREAD_RUNNING,  'THREAD_RUNNING'

; ### thread-state
code thread_state, 'thread-state'       ; thread -- state
        _ check_thread
        _slot thread_slot_state
        next
endcode

; ### thread_set_state
code thread_set_state, 'thread_set_state', SYMBOL_INTERNAL      ; state thread --
        _ check_thread
        _set_slot thread_slot_state
        next
endcode

; ### thread-stopped?
code thread_stopped?, 'thread-stopped?' ; thread -- ?
        _ check_thread
        _slot thread_slot_state
        _ THREAD_STOPPED
        _eq?
        next
endcode

; ### thread-debug-name
code thread_debug_name, 'thread-debug-name'     ; thread -- name
        _ check_thread
        _slot thread_slot_debug_name
        next
endcode

; ### thread-set-debug-name
code thread_set_debug_name, 'thread-set-debug-name'     ; name thread --
        _ check_thread
        _set_slot thread_slot_debug_name
        next
endcode

; ### current-thread
code current_thread, 'current-thread'   ; -- thread
        xcall   os_current_thread
        pushrbx
        mov     rbx, rax
        next
endcode

; ### current-thread-debug-name
code current_thread_debug_name, 'current-thread-debug-name'     ; -- name
        _ current_thread
        _ check_thread
        _slot thread_slot_debug_name
        next
endcode

; ### current_thread_raw_thread_id
code current_thread_raw_thread_id, 'current_thread_raw_thread_id', SYMBOL_INTERNAL
; -- raw-thread-id
        xcall   os_current_thread_raw_thread_id
        pushrbx
        mov     rbx, rax
        next
endcode

; ### current-thread-id
code current_thread_id, 'current-thread-id'     ; -- thread-id
        _ current_thread_raw_thread_id
        _ normalize
        next
endcode

; ### current_thread_raw_sp0
code current_thread_raw_sp0, 'current_thread_raw_sp0', SYMBOL_INTERNAL
        _ current_thread
        _ check_thread
        _slot thread_slot_raw_sp0
        next
endcode

; ### current_thread_raw_sp0_rax
code current_thread_raw_sp0_rax, 'current_thread_raw_sp0_rax', SYMBOL_INTERNAL
; returns raw sp0 in rax
        xcall   os_current_thread       ; get handle of current Feline thread object in rax

        ; rax will be 0 if we haven't called initialize_threads yet
        test    rax, rax
        jz      .too_soon

        _handle_to_object_unsafe_rax
        mov     rax, qword [rax + bytes_per_cell * thread_slot_raw_sp0]
        _return

.too_soon:
        mov     rax, [primordial_sp0_]
        next
endcode

; ### current_thread_raw_rp0
code current_thread_raw_rp0, 'current_thread_raw_rp0', SYMBOL_INTERNAL
        _ current_thread
        _ check_thread
        _slot thread_slot_raw_rp0
        next
endcode

; ### current_thread_raw_rp0_rax
code current_thread_raw_rp0_rax, 'current_thread_raw_rp0_rax', SYMBOL_INTERNAL
; returns raw rp0 in rax
        xcall   os_current_thread       ; get handle of current Feline thread object in rax

        ; rax will be 0 if we haven't called initialize_threads yet
        test    rax, rax
        jz      .too_soon

        _handle_to_object_unsafe_rax
        mov     rax, qword [rax + bytes_per_cell * thread_slot_raw_rp0]
        _return

.too_soon:
        mov     rax, [primordial_rp0_]
        next
endcode

; ### current_thread_raw_lp0
code current_thread_raw_lp0, 'current_thread_raw_lp0', SYMBOL_INTERNAL
        _ current_thread
        _ check_thread
        _slot thread_slot_raw_lp0
        next
endcode

; ### current_thread_save_registers
code current_thread_save_registers, 'current_thread_save_registers', SYMBOL_INTERNAL    ; --
        pushrbx                         ; -- rbx
        _ current_thread
        _ check_thread                  ; -- rbx thread
        _tuck
        _set_slot thread_slot_saved_rbx ; -- thread
        pushrbx
        mov     rbx, rsp
        _over
        _set_slot thread_slot_saved_rsp
        pushrbx
        mov     rbx, rbp
        _over
        _set_slot thread_slot_saved_rbp
        pushrbx
        mov     rbx, r14
        _swap
        _set_slot thread_slot_saved_r14
        next
endcode

; ### get_next_thread_debug_name
code get_next_thread_debug_name, 'get_next_thread_debug_name', SYMBOL_INTERNAL  ; -- name
        _ lock_all_threads
        mov     rax, [thread_number_]
        pushrbx
        mov     rbx, rax
        add     rax, 1
        mov     [thread_number_], rax
        _ unlock_all_threads
        _tag_fixnum
        _quote "thread %d"
        _ format
        next
endcode

; ### new_thread
code new_thread, 'new_thread', SYMBOL_INTERNAL  ; -- thread
        _lit 15
        _ raw_allocate_cells

        mov     qword [rbx], TYPECODE_THREAD

        _lit 8
        _ new_hashtable_untagged
        _over
        _set_slot thread_slot_thread_locals

        _f
        _over
        _set_slot thread_slot_quotation

        _ THREAD_NEW
        _over
        _set_slot thread_slot_state

        _f
        _over
        _set_slot thread_slot_debug_name

        _ new_handle

        next
endcode

; ### <thread>
code make_thread, '<thread>'            ; quotation -- thread

        ; REVIEW locking
        _dup
        _ quotation_raw_code_address
        cmp     rbx, 0
        poprbx
        jnz     .1
        _ compile_quotation

.1:
        _ new_thread
        _duptor

        _ check_thread

        _ get_next_thread_debug_name
        _over
        _set_slot thread_slot_debug_name

        _f
        _over
        _set_slot thread_slot_result

        _tuck
        _set_slot thread_slot_quotation ; -- thread

        _ allocate_locals_stack
        _over
        _set_slot thread_slot_raw_lp0

        xcall   os_thread_initialize_datastack  ; returns raw sp0 in rax
        _dup
        mov     rbx, rax
        _swap
        _set_slot thread_slot_raw_sp0

        _rfrom

        next
endcode

; ### destroy_thread
code destroy_thread, 'destroy_thread', SYMBOL_INTERNAL  ; thread --

        ; free locals stack
        _dup
        _slot thread_slot_raw_lp0
        sub     rbx, 4096
        _ raw_free

        ; zero out object header
        xor     eax, eax
        mov     [rbx], rax

        _ raw_free
        next
endcode

; 0 is reserved for the primordial thread
asm_global thread_number_, 1

asm_global all_threads_, f_value

; ### all-threads
code all_threads, 'all-threads'         ; -- vector
        pushrbx
        mov     rbx, [all_threads_]
        next
endcode

asm_global thread_count_, 1

%macro  _thread_count 0                 ; -- count
        pushrbx
        mov     rbx, [thread_count_]
%endmacro

%macro  _set_thread_count 0
        xchg    [thread_count_], rbx
        poprbx
%endmacro

%macro  _update_thread_count 0
        _ all_threads
        _ vector_raw_length
        _set_thread_count
%endmacro

; ### thread-count
code thread_count, 'thread-count'       ; -- count
        _thread_count
        _tag_fixnum
        next
endcode

asm_global all_threads_lock_, 0

%macro  _all_threads_lock 0
        pushrbx
        mov     rbx, [all_threads_lock_]
%endmacro

; ### lock_all_threads
code lock_all_threads, 'lock_all_threads', SYMBOL_INTERNAL      ; --

        _debug_print "lock all threads"

        _all_threads_lock
        _ mutex_lock
        _tagged_if_not .2
        _error "mutex_lock failed"
        _then .2
        next
endcode

; ### unlock_all_threads
code unlock_all_threads, 'unlock_all_threads', SYMBOL_INTERNAL  ; --

        _debug_print "unlock all threads"

        _all_threads_lock
        _ mutex_unlock
        _tagged_if_not .2
        _error "mutex_unlock failed"
        _then .2
        next
endcode

asm_global primordial_thread_, f_value

; ### primordial-thread
code primordial_thread, 'primordial-thread'     ; -- thread
        pushrbx
        mov     rbx, [primordial_thread_]
        next
endcode

; ### initialize_threads
code initialize_threads, 'initialize_threads', SYMBOL_INTERNAL  ; --

        ; all-threads vector
        _lit 8
        _ new_vector_untagged
        mov     [all_threads_], rbx
        poprbx
        _lit all_threads_
        _ gc_add_root

        ; all-threads lock
        _ make_mutex
        mov     [all_threads_lock_], rbx
        poprbx
        _lit all_threads_lock_
        _ gc_add_root

        ; primordial thread
        _ new_thread                    ; -- thread

        mov     [primordial_thread_], rbx       ; -- thread
        _lit primordial_thread_
        _ gc_add_root

        _quote "thread 0"
        _over
        _ thread_set_debug_name

        pushrbx
        mov     rbx, [primordial_sp0_]
        _over
        _ thread_set_raw_sp0            ; -- thread

        pushrbx
        mov     rbx, [primordial_rp0_]
        _over
        _ thread_set_raw_rp0            ; -- thread

        pushrbx
        mov     rbx, [lp0_]
        _over
        _ thread_set_raw_lp0            ; -- thread

        _ current_thread_raw_thread_id
        _over
        _ thread_set_raw_thread_id

%ifdef WIN64
        xcall   os_current_thread_raw_thread_handle
        pushrbx
        mov     rbx, rax
        _over
        _ thread_set_raw_thread_handle
%endif

        _ THREAD_RUNNING
        _over
        _ thread_set_state

        mov     arg0_register, rbx
        xcall   os_initialize_primordial_thread

        ; no lock needed
        _ all_threads
        _ vector_push

        next
endcode

; ### thread-create
code thread_create, 'thread-create'     ; thread --
        _ verify_thread

        _ THREAD_STARTING
        _over
        _ thread_set_state

        _ lock_all_threads
        _dup
        _ all_threads
        _ vector_push
        _update_thread_count
        _ unlock_all_threads

        mov     arg0_register, rbx
        xcall   os_thread_create        ; returns native thread identifier in rax
        _handle_to_object_unsafe
%ifdef WIN64
        mov     thread_raw_thread_handle_slot, rax
%else
        mov     thread_raw_thread_id_slot, rax
%endif
        poprbx
        next
endcode

; ### thread-join
code thread_join, 'thread-join'         ; thread --
        _ check_thread

        _ THREAD_STOPPED
        _ current_thread
        _ thread_set_state

        _ current_thread_save_registers

%ifdef WIN64
        _slot thread_slot_raw_thread_handle
%else
        _slot thread_slot_raw_thread_id
%endif

        mov     arg0_register, rbx
        poprbx

        xcall   os_thread_join

        _ THREAD_RUNNING
        _ current_thread
        _ thread_set_state

        next
endcode

%ifdef WIN64
; ### thread-suspend
code thread_suspend, 'thread-suspend'   ; thread --
        _ check_thread
        _slot thread_slot_raw_thread_handle
        mov     arg0_register, rbx
        poprbx
        extern  SuspendThread
        xcall   SuspendThread
        next
endcode

; ### thread-resume
code thread_resume, 'thread-resume'   ; thread --
        _ check_thread
        _slot thread_slot_raw_thread_handle
        mov     arg0_register, rbx
        poprbx
        extern  ResumeThread
        xcall   ResumeThread
        next
endcode
%endif

; ### sleep
code sleep, 'sleep'                     ; millis --
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        xcall   os_sleep
        next
endcode

; ### current-thread-locals
code current_thread_locals, 'current-thread-locals'     ; -- hashtable
        _ current_thread
        _ check_thread
        _slot thread_slot_thread_locals
        next
endcode

; ### thread-local-set
code thread_local_set, 'thread-local-set'       ; value symbol thread --
        _ check_thread
        _slot thread_slot_thread_locals
        _ hashtable_set_at
        next
endcode

; ### thread-local-get
code thread_local_get, 'thread-local-get'       ; symbol thread -- value
        _ check_thread
        _slot thread_slot_thread_locals
        _ hashtable_at
        next
endcode

; ### current-thread-local-set
code current_thread_local_set, 'current-thread-local-set'       ; value symbol --
        _ current_thread
        _ thread_local_set
        next
endcode

; ### current-thread-local-get
code current_thread_local_get, 'current-thread-local-get'       ; symbol -- value
        _ current_thread
        _ thread_local_get
        next
endcode

; ### thread_run_internal
code thread_run_internal, 'thread_run_internal', SYMBOL_INTERNAL
; called from C with handle of thread object in arg0_register

        ; save C registers
        push    rbp
        push    rbx

        ; set up data stack
        mov     rbx, arg0_register      ; handle of thread object in rbx
        push    rbx                     ; save thread handle
        _handle_to_object_unsafe        ; raw object address in rbx
        mov     rbp, thread_raw_sp0_slot

        ; make stack depth = 1
        _dup                            ; -- raw-object-address

        ; rp0
        mov     thread_raw_rp0_slot, rsp

        ; lp0
        mov     r14, thread_raw_lp0_slot

        mov     thread_state_slot, S_THREAD_RUNNING

        _slot thread_slot_quotation     ; -- quotation

        _ call_quotation                ; -- ???

        _ get_datastack                ; -- ??? array

        pushrbx
        pop     rbx                     ; -- ??? array handle
        _tuck
        _ thread_set_result             ; -- ??? handle

        _ THREAD_STOPPED
        _over
        _ thread_set_state

        _ lock_all_threads
        _ all_threads
        _ vector_remove_mutating        ; -- vector
        _drop                           ; --
        _update_thread_count
        _ unlock_all_threads

        _debug_print "leaving thread_run_internal"

        ; restore C registers
        pop     rbx
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

; ### mark_thread
code mark_thread, 'mark_thread', SYMBOL_INTERNAL        ; thread --
        _dup
        _slot thread_slot_quotation
        _ maybe_mark_handle
        _dup
        _slot thread_slot_thread_locals
        _ maybe_mark_handle
        _dup
        _slot thread_slot_quotation
        _ maybe_mark_handle
        _slot thread_slot_debug_name
        _ maybe_mark_handle
        next
endcode
