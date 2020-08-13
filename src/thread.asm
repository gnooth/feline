; Copyright (C) 2017-2020 Peter Graves <gnooth@gmail.com>

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

%define THREAD_RAW_THREAD_ID_OFFSET             BYTES_PER_CELL * 1

%macro _thread_raw_thread_id 0
        _slot 1
%endmacro

%macro _thread_set_raw_thread_id 0
        _set_slot 1
%endmacro

%define THREAD_RAW_THREAD_HANDLE_OFFSET         BYTES_PER_CELL * 2

%macro _thread_raw_thread_handle 0
        _slot 2
%endmacro

%macro _thread_set_raw_thread_handle 0
        _set_slot 2
%endmacro

%define THREAD_RAW_SP0_OFFSET                   BYTES_PER_CELL * 3

%macro _thread_raw_sp0 0
        _slot 3
%endmacro

%macro _thread_set_raw_sp0 0
        _set_slot 3
%endmacro

%define THREAD_RAW_RP0_OFFSET                   BYTES_PER_CELL * 4

%macro _thread_raw_rp0 0
        _slot 4
%endmacro

%macro _thread_set_raw_rp0 0
        _set_slot 4
%endmacro

; %define THREAD_QUOTATION_OFFSET                 BYTES_PER_CELL * 5

%macro _thread_quotation 0
        _slot 5
%endmacro

%macro _thread_set_quotation 0
        _set_slot 5
%endmacro

; %define THREAD_RESULT_OFFSET                    BYTES_PER_CELL * 6

%macro _thread_result 0
        _slot 6
%endmacro

%macro _thread_set_result 0
        _set_slot 6
%endmacro

%macro _thread_locals 0
        _slot 7
%endmacro

%macro _thread_set_locals 0
        _set_slot 7
%endmacro

%macro _thread_saved_rbx 0
        _slot 8
%endmacro

%macro _thread_set_saved_rbx 0
        _set_slot 8
%endmacro

%macro _thread_saved_rsp 0
        _slot 9
%endmacro

%macro _thread_set_saved_rsp 0
        _set_slot 9
%endmacro

%macro _thread_saved_rbp 0
        _slot 10
%endmacro

%macro _thread_set_saved_rbp 0
        _set_slot 10
%endmacro

%define THREAD_STATE_OFFSET                     BYTES_PER_CELL * 11

%macro _thread_state 0
        _slot 11
%endmacro

%macro _thread_set_state 0
        _set_slot 11
%endmacro

%macro _thread_debug_name 0
        _slot 12
%endmacro

%macro _thread_set_debug_name 0
        _set_slot 12
%endmacro

%macro _thread_catchstack 0
        _slot 12
%endmacro

%macro _thread_set_catchstack 0
        _set_slot 12
%endmacro

code thread?, 'thread?'                 ; x -> x/nil
; If x is a thread, returns x unchanged. If x is not a thread, returns nil.
        cmp     bl, HANDLE_TAG
        jne     .not_a_thread
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_THREAD
        jne     .not_a_thread
        next
.not_a_thread:
        mov     ebx, NIL
        next
endcode

; ### check_thread
code check_thread, 'check_thread', SYMBOL_INTERNAL ; thread -> ^thread
        cmp     bl, HANDLE_TAG
        jne     .error2
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]              ; rbx: ^thread
        cmp     word [rbx], TYPECODE_THREAD
        jne     .error1
        next
.error1:
        mov     rbx, rax
.error2:
        jmp     error_not_thread
endcode

; ### verify-thread
code verify_thread, 'verify-thread'     ; thread -> thread
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     .error
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_THREAD
        jne     .error
        next
.error:
        jmp     error_not_thread
endcode

; ### error-not-thread
code error_not_thread, 'error-not-thread'       ; x -> void
        _quote "a thread"
        _ format_type_error
        next
endcode

; ### thread_set_raw_thread_id
code thread_set_raw_thread_id, 'thread_set_raw_thread_id', SYMBOL_INTERNAL
; raw-thread-id thread -> void
        _ check_thread
        _thread_set_raw_thread_id
        next
endcode

; ### thread-id
code thread_id, 'thread-id'             ; thread -> thread-id
        _ check_thread
        _thread_raw_thread_id
        _ normalize
        next
endcode

%ifdef WIN64
; ### thread_set_raw_thread_handle
code thread_set_raw_thread_handle, 'thread_set_raw_thread_handle', SYMBOL_INTERNAL
; raw-thread-handle thread -> void
        _ check_thread
        _thread_set_raw_thread_handle
        next
endcode
%endif

; ### thread_raw_sp0
code thread_raw_sp0, 'thread_raw_sp0', SYMBOL_INTERNAL ; -> raw-sp0
        _ check_thread
        _thread_raw_sp0
        next
endcode

; ### thread_set_raw_sp0
code thread_set_raw_sp0, 'thread_set_raw_sp0', SYMBOL_INTERNAL  ; raw-sp0 thread -> void
        _ check_thread
        _thread_set_raw_sp0
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
        _thread_raw_rp0
        next
endcode

; ### thread_set_raw_rp0
code thread_set_raw_rp0, 'thread_set_raw_rp0', SYMBOL_INTERNAL  ; raw-rp0 thread -> void
        _ check_thread
        _thread_set_raw_rp0
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
        _thread_catchstack
        next
endcode

; ### thread-set-catchstack
code thread_set_catchstack, 'thread-set-catchstack' ; vector thread -> void
        _ check_thread
        _thread_set_catchstack
        next
endcode

; ### thread-quotation
code thread_quotation, 'thread-quotation' ; thread -> quotation
        _ check_thread
        _thread_quotation
        next
endcode

; ### thread-result
code thread_result, 'thread-result'     ; thread -> result
        _ check_thread
        _thread_result
        next
endcode

; ### thread_set_result
code thread_set_result, 'thread_set_result', SYMBOL_INTERNAL ; result thread -> void
        _ check_thread
        _thread_set_result
        next
endcode

; ### thread_saved_rbx
code thread_saved_rbx, 'thread_saved_rbx', SYMBOL_INTERNAL ; thread -> saved-rbx
        _ check_thread
        _thread_saved_rbx
        next
endcode

; ### thread_saved_rsp
code thread_saved_rsp, 'thread_saved_rsp', SYMBOL_INTERNAL ; thread -> saved-rsp
        _ check_thread
        _thread_saved_rsp
        next
endcode

; ### thread_saved_rbp
code thread_saved_rbp, 'thread_saved_rbp', SYMBOL_INTERNAL ; thread -> saved-rbp
        _ check_thread
        _thread_saved_rbp
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
        _thread_state
        next
endcode

; ### thread_set_state
code thread_set_state, 'thread_set_state', SYMBOL_INTERNAL ; state thread -> void
        _ check_thread
        _thread_set_state
        next
endcode

; ### thread-stopped?
code thread_stopped?, 'thread-stopped?' ; thread -> ?
        _ check_thread
        _thread_state
        _ THREAD_STOPPED
        _eq?
        next
endcode

; ### thread-debug-name
code thread_debug_name, 'thread-debug-name' ; thread -> name
        _ check_thread
        _thread_debug_name
        next
endcode

; ### thread-set-debug-name
code thread_set_debug_name, 'thread-set-debug-name' ; name thread -> void
        _ check_thread
        _thread_set_debug_name
        next
endcode

; ### current-thread
code current_thread, 'current-thread'   ; -> thread
        xcall   os_current_thread
        _dup
        mov     rbx, rax
        next
endcode

; ### current-thread-debug-name
code current_thread_debug_name, 'current-thread-debug-name' ; -> name
        _ current_thread
        _ check_thread
        _thread_debug_name
        next
endcode

; ### current_thread_raw_thread_id
code current_thread_raw_thread_id, 'current_thread_raw_thread_id', SYMBOL_INTERNAL ; -> raw-thread-id
        xcall   os_current_thread_raw_thread_id
        _dup
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
        _ thread?                       ; -> thread/nil
        cmp     rbx, NIL
        je      .too_soon
        ; -> thread
        _thread_raw_sp0
        next

.too_soon:
        ; -> nil
        mov     rbx, [primordial_sp0_]
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
        _thread_raw_rp0
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
code current_thread_save_registers, 'current_thread_save_registers', SYMBOL_INTERNAL
        _dup                            ; -> rbx
        _ current_thread
        _ check_thread                  ; -> rbx ^thread
        _tuck
        _thread_set_saved_rbx
        _dup
        mov     rbx, rsp
        _over
        _thread_set_saved_rsp
        _dup
        mov     rbx, rbp
        _swap
        _thread_set_saved_rbp
        next
endcode

; ### get_next_thread_debug_name
code get_next_thread_debug_name, 'get_next_thread_debug_name', SYMBOL_INTERNAL  ; -> name
        _ lock_all_threads
        mov     rax, [thread_number_]
        _dup
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
code new_thread, 'new_thread', SYMBOL_INTERNAL  ; -> thread
        _lit 14
        _ raw_allocate_cells

        mov     qword [rbx], TYPECODE_THREAD

        _lit 8
        _ new_hashtable_untagged
        _over
        _thread_set_locals

        _nil
        _over
        _thread_set_quotation

        _ THREAD_NEW
        _over
        _thread_set_state

        _nil
        _over
        _thread_set_debug_name

        _ new_handle

        next
endcode

; ### make-thread
code make_thread, 'make-thread'         ; quotation -> thread

        ; REVIEW locking
        _dup
        _ quotation_raw_code_address
        cmp     rbx, 0
        _drop
        jnz     .1
        _ compile_quotation

.1:
        _ new_thread
        _duptor

        _ check_thread

        _ get_next_thread_debug_name
        _over
        _thread_set_debug_name

        _nil
        _over
        _thread_set_result

        _tuck
        _thread_set_quotation

        _lit 16
        _ new_vector_untagged
        _over
        _thread_set_catchstack

        xcall   os_thread_initialize_datastack ; returns raw sp0 in rax
        _dup
        mov     rbx, rax
        _swap
        _thread_set_raw_sp0

        _rfrom

        next
endcode

; ### destroy_thread
code destroy_thread, 'destroy_thread', SYMBOL_INTERNAL  ; thread -> void

        ; zero out object header
        mov     qword [rbx], 0

        _ raw_free
        next
endcode

; 0 is reserved for the primordial thread
asm_global thread_number_, 1

asm_global all_threads_, NIL

; ### all-threads
code all_threads, 'all-threads'         ; -> vector
        _dup
        mov     rbx, [all_threads_]
        next
endcode

asm_global thread_count_, 1

%macro  _thread_count 0                 ; -> count
        _dup
        mov     rbx, [thread_count_]
%endmacro

%macro  _set_thread_count 0
        xchg    [thread_count_], rbx
        _drop
%endmacro

%macro  _update_thread_count 0
        _ all_threads
        _ vector_raw_length
        _set_thread_count
%endmacro

; ### update-thread-count
code update_thread_count, 'update-thread-count'
        _update_thread_count
        next
endcode

; ### thread-count
code thread_count, 'thread-count'       ; -> count
        _thread_count
        _tag_fixnum
        next
endcode

asm_global all_threads_lock_, 0

%macro  _all_threads_lock 0
        _dup
        mov     rbx, [all_threads_lock_]
%endmacro

; ### lock_all_threads
code lock_all_threads, 'lock_all_threads', SYMBOL_INTERNAL

        _debug_print "lock all threads"

        _all_threads_lock
        _ mutex_lock
        _tagged_if_not .2
        _error "mutex_lock failed"
        _then .2
        next
endcode

; ### unlock_all_threads
code unlock_all_threads, 'unlock_all_threads', SYMBOL_INTERNAL

        _debug_print "unlock all threads"

        _all_threads_lock
        _ mutex_unlock
        _tagged_if_not .2
        _error "mutex_unlock failed"
        _then .2
        next
endcode

asm_global primordial_thread_, NIL

; ### primordial-thread
code primordial_thread, 'primordial-thread' ; -> thread
        _dup
        mov     rbx, [primordial_thread_]
        next
endcode

; ### current-thread-is-primordial?
code current_thread_is_primordial?, 'current-thread-is-primordial?' ; -> ?
        _ current_thread
        _ primordial_thread
        _eq?
        next
endcode

; ### initialize_threads
code initialize_threads, 'initialize_threads', SYMBOL_INTERNAL

        ; all-threads vector
        _lit 8
        _ new_vector_untagged
        mov     [all_threads_], rbx
        _drop
        _lit all_threads_
        _ gc_add_root

        ; all-threads lock
        _ make_mutex
        mov     [all_threads_lock_], rbx
        _drop
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

        _dup
        mov     rbx, [primordial_sp0_]
        _over
        _ thread_set_raw_sp0            ; -> thread

        _dup
        mov     rbx, [primordial_rp0_]
        _over
        _ thread_set_raw_rp0            ; -> thread

        _ current_thread_raw_thread_id
        _over
        _ thread_set_raw_thread_id

%ifdef WIN64
        xcall   os_current_thread_raw_thread_handle
        _dup
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
        _handle_to_object_unsafe        ; address of thread object in rbx
%ifdef WIN64
        mov     [rbx + THREAD_RAW_THREAD_HANDLE_OFFSET], rax
%else
        mov     [rbx + THREAD_RAW_THREAD_ID_OFFSET], rax
%endif
        _drop
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
        _thread_raw_thread_handle
%else
        _thread_raw_thread_id
%endif

        mov     arg0_register, rbx
        _drop

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
        _thread_raw_thread_handle
        mov     arg0_register, rbx
        _drop
        extern  SuspendThread
        xcall   SuspendThread
        next
endcode

; ### thread-resume
code thread_resume, 'thread-resume'     ; thread -> void
        _ check_thread
        _thread_raw_thread_handle
        mov     arg0_register, rbx
        _drop
        extern  ResumeThread
        xcall   ResumeThread
        next
endcode
%endif

; ### sleep
code sleep, 'sleep'                     ; millis -> void
        _check_fixnum
        mov     arg0_register, rbx
        _drop
        xcall   os_sleep
        next
endcode

; ### current-thread-locals
code current_thread_locals, 'current-thread-locals' ; -> hashtable
        _ current_thread
        _ check_thread
        _thread_set_locals
        next
endcode

; ### thread-local-set
code thread_local_set, 'thread-local-set' ; value symbol thread -> void
        _ check_thread
        _thread_locals
        _ hashtable_set_at
        next
endcode

; ### thread-local-get
code thread_local_get, 'thread-local-get' ; symbol thread -> value
        _ check_thread
        _thread_locals
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
        _handle_to_object_unsafe        ; address of thread object in rbx
        mov     rbp, [rbx + THREAD_RAW_SP0_OFFSET]

        ; make stack depth = 1
        _dup                            ; -> raw-object-address

        ; rp0
        mov     [rbx + THREAD_RAW_RP0_OFFSET], rsp

        mov     rax, S_THREAD_RUNNING
        shl     rax, STATIC_OBJECT_TAG_BITS
        or      rax, STATIC_SYMBOL_TAG
        mov     qword [rbx + THREAD_STATE_OFFSET], rax

        _thread_quotation

        _ call_quotation                ; -> results

        _ get_datastack                 ; -> results array

        _dup
        pop     rbx                     ; -> results array handle
        _tuck
        _ thread_set_result             ; -> results handle

        _ THREAD_STOPPED
        _over
        _ thread_set_state

        _ lock_all_threads
        _ all_threads
        _ vector_remove_mutating        ; -> vector
        _drop                           ; ->
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
