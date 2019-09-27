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

%define PREFIX THREAD

DEFINE_SLOT RAW_THREAD_ID, 1
DEFINE_SLOT RAW_THREAD_HANDLE, 2
DEFINE_SLOT RAW_SP0, 3
DEFINE_SLOT RAW_RP0, 4
DEFINE_SLOT QUOTATION, 5
DEFINE_SLOT RESULT, 6
DEFINE_SLOT THREAD_LOCALS, 7
DEFINE_SLOT SAVED_RBX, 8
DEFINE_SLOT SAVED_RSP, 9
DEFINE_SLOT SAVED_RBP, 10
DEFINE_SLOT STATE, 11
DEFINE_SLOT DEBUG_NAME, 12
DEFINE_SLOT CATCHSTACK, 13

%undef PREFIX

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
code check_thread, 'check_thread', SYMBOL_INTERNAL ; thread -> ^thread
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
code verify_thread, 'verify-thread'     ; thread -> thread
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
code thread_set_raw_thread_id, 'thread_set_raw_thread_id', SYMBOL_INTERNAL ; raw-thread-id thread -> void
        _ check_thread
        _set_slot THREAD_RAW_THREAD_ID_SLOT#
        next
endcode

; ### thread-id
code thread_id, 'thread-id'             ; thread -- thread-id
        _ check_thread
        _slot THREAD_RAW_THREAD_ID_SLOT#
        _ normalize
        next
endcode

%ifdef WIN64
; ### thread_set_raw_thread_handle
code thread_set_raw_thread_handle, 'thread_set_raw_thread_handle', SYMBOL_INTERNAL ; raw-thread-id thread -> void
        _ check_thread
        _set_slot THREAD_RAW_THREAD_HANDLE_SLOT#
        next
endcode
%endif

; ### thread_raw_sp0
code thread_raw_sp0, 'thread_raw_sp0', SYMBOL_INTERNAL ; -> raw-sp0
        _ check_thread
        _slot THREAD_RAW_SP0_SLOT#
        next
endcode

; ### thread_set_raw_sp0
code thread_set_raw_sp0, 'thread_set_raw_sp0', SYMBOL_INTERNAL  ; raw-sp0 thread -> void
        _ check_thread
        _set_slot THREAD_RAW_SP0_SLOT#
        next
endcode

; ### thread-sp0
code thread_sp0, 'thread-sp0'           ; thread -> sp0
        _ thread_raw_sp0
        _tag_fixnum
        next
endcode

; ### thread_raw_rp0
code thread_raw_rp0, 'thread_raw_rp0', SYMBOL_INTERNAL  ; -> raw-rp0
        _ check_thread
        _slot THREAD_RAW_RP0_SLOT#
        next
endcode

; ### thread_set_raw_rp0
code thread_set_raw_rp0, 'thread_set_raw_rp0', SYMBOL_INTERNAL  ; raw-rp0 thread -> void
        _ check_thread
        _set_slot THREAD_RAW_RP0_SLOT#
        next
endcode

; ### thread-rp0
code thread_rp0, 'thread-rp0'           ; thread -> rp0
        _ thread_raw_rp0
        _tag_fixnum
        next
endcode

; ### thread-catchstack
code thread_catchstack, 'thread-catchstack' ; void -> vector
        _ check_thread
        _slot THREAD_CATCHSTACK_SLOT#
        next
endcode

; ### thread-set-catchstack
code thread_set_catchstack, 'thread-set-catchstack' ; vector thread -> void
        _ check_thread
        _set_slot THREAD_CATCHSTACK_SLOT#
        next
endcode

; ### thread-quotation
code thread_quotation, 'thread-quotation' ; thread -> quotation
        _ check_thread
        _slot THREAD_QUOTATION_SLOT#
        next
endcode

; ### thread-result
code thread_result, 'thread-result'     ; thread -> result
        _ check_thread
        _slot THREAD_RESULT_SLOT#
        next
endcode

; ### thread_set_result
code thread_set_result, 'thread_set_result', SYMBOL_INTERNAL ; result thread -> void
        _ check_thread
        _set_slot THREAD_RESULT_SLOT#
        next
endcode

; ### thread_saved_rbx
code thread_saved_rbx, 'thread_saved_rbx', SYMBOL_INTERNAL ; thread -> saved-rbx
        _ check_thread
        _slot THREAD_SAVED_RBX_SLOT#
        next
endcode

; ### thread_saved_rsp
code thread_saved_rsp, 'thread_saved_rsp', SYMBOL_INTERNAL ; thread -> saved-rsp
        _ check_thread
        _slot THREAD_SAVED_RSP_SLOT#
        next
endcode

; ### thread_saved_rbp
code thread_saved_rbp, 'thread_saved_rbp', SYMBOL_INTERNAL ; thread -> saved-rbp
        _ check_thread
        _slot THREAD_SAVED_RBP_SLOT#
        next
endcode

; REVIEW
special THREAD_NEW,      'THREAD_NEW'
special THREAD_STARTING, 'THREAD_STARTING'
special THREAD_STOPPED,  'THREAD_STOPPED'
special THREAD_RUNNING,  'THREAD_RUNNING'

; ### thread-state
code thread_state, 'thread-state'       ; thread -> state
        _ check_thread
        _slot THREAD_STATE_SLOT#
        next
endcode

; ### thread_set_state
code thread_set_state, 'thread_set_state', SYMBOL_INTERNAL ; state thread -> void
        _ check_thread
        _set_slot THREAD_STATE_SLOT#
        next
endcode

; ### thread-stopped?
code thread_stopped?, 'thread-stopped?' ; thread -> ?
        _ check_thread
        _slot THREAD_STATE_SLOT#
        _ THREAD_STOPPED
        _eq?
        next
endcode

; ### thread-debug-name
code thread_debug_name, 'thread-debug-name' ; thread -> name
        _ check_thread
        _slot THREAD_DEBUG_NAME_SLOT#
        next
endcode

; ### thread-set-debug-name
code thread_set_debug_name, 'thread-set-debug-name' ; name thread -> void
        _ check_thread
        _set_slot THREAD_DEBUG_NAME_SLOT#
        next
endcode

; ### current-thread
code current_thread, 'current-thread'   ; -> thread
        xcall   os_current_thread
        pushrbx
        mov     rbx, rax
        next
endcode

; ### current-thread-debug-name
code current_thread_debug_name, 'current-thread-debug-name' ; -> name
        _ current_thread
        _ check_thread
        _slot THREAD_DEBUG_NAME_SLOT#
        next
endcode

; ### current_thread_raw_thread_id
code current_thread_raw_thread_id, 'current_thread_raw_thread_id', SYMBOL_INTERNAL ; -> raw-thread-id
        xcall   os_current_thread_raw_thread_id
        pushrbx
        mov     rbx, rax
        next
endcode

; ### current-thread-id
code current_thread_id, 'current-thread-id' ; -> thread-id
        _ current_thread_raw_thread_id
        _ normalize
        next
endcode

; ### current_thread_raw_sp0
code current_thread_raw_sp0, 'current_thread_raw_sp0', SYMBOL_INTERNAL
        _ current_thread
        _ check_thread
        _slot THREAD_RAW_SP0_SLOT#
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
        mov     rax, qword [rax + THREAD_RAW_SP0_OFFSET]
        _return

.too_soon:
        mov     rax, [primordial_sp0_]
        next
endcode

; ### current_thread_raw_rp0
code current_thread_raw_rp0, 'current_thread_raw_rp0', SYMBOL_INTERNAL
        _ current_thread
        _ check_thread
        _slot THREAD_RAW_RP0_SLOT#
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
        mov     rax, qword [rax + THREAD_RAW_RP0_OFFSET]
        _return

.too_soon:
        mov     rax, [primordial_rp0_]
        next
endcode

; ### current_thread_save_registers
code current_thread_save_registers, 'current_thread_save_registers', SYMBOL_INTERNAL    ; --
        pushrbx                         ; -- rbx
        _ current_thread
        _ check_thread                  ; -> rbx ^thread
        _tuck
        _set_slot THREAD_SAVED_RBX_SLOT# ; -> thread
        pushrbx
        mov     rbx, rsp
        _over
        _set_slot THREAD_SAVED_RSP_SLOT#
        pushrbx
        mov     rbx, rbp
        _swap
        _set_slot THREAD_SAVED_RBP_SLOT#
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
        _lit 14
        _ raw_allocate_cells

        mov     qword [rbx], TYPECODE_THREAD

        _lit 8
        _ new_hashtable_untagged
        _over
        _set_slot THREAD_THREAD_LOCALS_SLOT#

        _f
        _over
        _set_slot THREAD_QUOTATION_SLOT#

        _ THREAD_NEW
        _over
        _set_slot THREAD_STATE_SLOT#

        _f
        _over
        _set_slot THREAD_DEBUG_NAME_SLOT#

        _ new_handle

        next
endcode

; ### make-thread
code make_thread, 'make-thread'         ; quotation -- thread

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
        _set_slot THREAD_DEBUG_NAME_SLOT#

        _f
        _over
        _set_slot THREAD_RESULT_SLOT#

        _tuck
        _set_slot THREAD_QUOTATION_SLOT# ; -> thread

        _lit 16
        _ new_vector_untagged
        _over
        _set_slot THREAD_CATCHSTACK_SLOT#

        xcall   os_thread_initialize_datastack ; returns raw sp0 in rax
        _dup
        mov     rbx, rax
        _swap
        _set_slot THREAD_RAW_SP0_SLOT#

        _rfrom

        next
endcode

; ### destroy_thread
code destroy_thread, 'destroy_thread', SYMBOL_INTERNAL  ; thread --

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
code primordial_thread, 'primordial-thread' ; -> thread
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
        _ new_thread                    ; -> thread

        mov     [primordial_thread_], rbx ; -> thread
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

        _lit 16
        _ new_vector_untagged
        _over
        _ thread_set_catchstack

        mov     arg0_register, rbx
        xcall   os_initialize_primordial_thread

        ; no lock needed
        _ all_threads
        _ vector_push

        next
endcode

; ### thread-create
code thread_create, 'thread-create'     ; thread -> void
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
        mov     THREAD_RAW_THREAD_HANDLE, rax
%else
        mov     THREAD_RAW_THREAD_ID, rax
%endif
        poprbx
        next
endcode

; ### thread-join
code thread_join, 'thread-join'         ; thread -> void
        _ check_thread

        _ THREAD_STOPPED
        _ current_thread
        _ thread_set_state

        _ current_thread_save_registers

%ifdef WIN64
        _slot THREAD_RAW_THREAD_HANDLE_SLOT#
%else
        _slot THREAD_RAW_THREAD_ID_SLOT#
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
code thread_suspend, 'thread-suspend'   ; thread -> void
        _ check_thread
        _slot THREAD_RAW_THREAD_HANDLE_SLOT#
        mov     arg0_register, rbx
        poprbx
        extern  SuspendThread
        xcall   SuspendThread
        next
endcode

; ### thread-resume
code thread_resume, 'thread-resume'     ; thread -> void
        _ check_thread
        _slot THREAD_RAW_THREAD_HANDLE_SLOT#
        mov     arg0_register, rbx
        poprbx
        extern  ResumeThread
        xcall   ResumeThread
        next
endcode
%endif

; ### sleep
code sleep, 'sleep'                     ; millis -> void
        _check_fixnum
        mov     arg0_register, rbx
        poprbx
        xcall   os_sleep
        next
endcode

; ### current-thread-locals
code current_thread_locals, 'current-thread-locals' ; -> hashtable
        _ current_thread
        _ check_thread
        _slot THREAD_THREAD_LOCALS_SLOT#
        next
endcode

; ### thread-local-set
code thread_local_set, 'thread-local-set' ; value symbol thread -> void
        _ check_thread
        _slot THREAD_THREAD_LOCALS_SLOT#
        _ hashtable_set_at
        next
endcode

; ### thread-local-get
code thread_local_get, 'thread-local-get' ; symbol thread -> value
        _ check_thread
        _slot THREAD_THREAD_LOCALS_SLOT#
        _ hashtable_at
        next
endcode

; ### current-thread-local-set
code current_thread_local_set, 'current-thread-local-set' ; value symbol -> void
        _ current_thread
        _ thread_local_set
        next
endcode

; ### current-thread-local-get
code current_thread_local_get, 'current-thread-local-get' ; symbol -> value
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
        mov     rbp, THREAD_RAW_SP0

        ; make stack depth = 1
        _dup                            ; -> raw-object-address

        ; rp0
        mov     THREAD_RAW_RP0, rsp

        mov     THREAD_STATE, S_THREAD_RUNNING

        _slot THREAD_QUOTATION_SLOT#    ; -> quotation

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

; ### thread->string
code thread_to_string, 'thread->string' ; thread -> string
        _ verify_thread
        _ object_address                ; -> tagged-fixnum
        _ fixnum_to_hex
        _quote "<thread 0x%s>"
        _ format
        next
endcode
