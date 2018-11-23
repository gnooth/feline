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

asm_global gc_roots_                    ; initialized in cold

; ### gc_roots
code gc_roots, 'gc_roots', SYMBOL_INTERNAL      ; -- vector
        pushrbx
        mov     rbx, [gc_roots_]
        next
endcode

; ### gc_add_root
code gc_add_root, 'gc_add_root', SYMBOL_INTERNAL        ; raw-address --
        _ gc_roots
        _ vector_push
        next
endcode

%macro _set_marked_bit 0                ; object -- object
        or      OBJECT_FLAGS_BYTE, OBJECT_MARKED_BIT
%endmacro

%macro _test_marked_bit 0               ; object -- object
        test    OBJECT_FLAGS_BYTE, OBJECT_MARKED_BIT
%endmacro

%macro  _unmark_object 0                ; object --
        and     OBJECT_FLAGS_BYTE, ~OBJECT_MARKED_BIT
        poprbx
%endmacro

; ### mark-vector
code mark_vector, 'mark-vector'         ; vector --
        push    this_register
        mov     this_register, rbx
        _vector_raw_length
        _register_do_times .1
        _raw_loop_index
        _this_vector_nth_unsafe         ; -- element
        _ maybe_mark_handle
        _loop .1                        ; --
        pop     this_register
        next
endcode

; ### mark-array
code mark_array, 'mark-array'           ; array --
        push    this_register
        mov     this_register, rbx
        _array_raw_length
        _zero
        _?do .1
        _i
        _this_array_nth_unsafe          ; -- element
        _ maybe_mark_handle
        _loop .1                        ; --
        pop     this_register
        next
endcode

; ### mark-hashtable
code mark_hashtable, 'mark-hashtable'   ; hashtable --
        push    this_register
        mov     this_register, rbx      ; -- hashtable
        _hashtable_raw_capacity         ; -- capacity
        _register_do_times .1
        _raw_loop_index
        _dup
        _this_hashtable_nth_key
        _ maybe_mark_handle
        _this_hashtable_nth_value
        _ maybe_mark_handle
        _loop .1                        ; --
        pop     this_register
        next
endcode

; ### mark-vocab
code mark_vocab, 'mark-vocab'           ; vocab --
        _dup
        _vocab_name
        _ maybe_mark_handle
        _vocab_hashtable
        _ maybe_mark_handle
        next
endcode

; ### mark-symbol
code mark_symbol, 'mark-symbol'         ; symbol -> void
        _dup
        _symbol_name
        _ maybe_mark_handle
        _dup
        _symbol_def
        _ maybe_mark_handle
        _dup
        _symbol_props
        _ maybe_mark_handle
        _dup
        _symbol_value
        _ maybe_mark_handle
        _symbol_file
        _ maybe_mark_handle
        ; REVIEW vocab
        next
endcode

; ### mark-quotation
code mark_quotation, 'mark-quotation'   ; quotation --
        _quotation_array
        _ maybe_mark_handle
        ; REVIEW code
        next
endcode

; ### mark-slice
code mark_slice, 'mark-slice'           ; slice --
        _slice_seq
        _ maybe_mark_handle
        ; REVIEW code
        next
endcode

; ### mark-tuple
code mark_tuple, 'mark-tuple'           ; tuple --
        push    this_register
        mov     this_register, rbx      ; -- tuple

        _ tuple_size_unchecked          ; -- size
        _check_fixnum                   ; untagged size (number of defined slots) in rbx

        ; slot 0 is object header
        add     rbx, 1                  ; loop limit is size + 1
        _lit 1                          ; loop start is 1

        ; -- limit start
        _?do .1
        _i
        _this_nth_slot
        _ maybe_mark_handle
        _loop .1

        pop     this_register
        next
endcode

; ### mark-lexer
code mark_lexer, 'mark-lexer'           ; lexer --
        _dup
        _lexer_string
        _ maybe_mark_handle
        _lexer_file
        _ maybe_mark_handle
        next
endcode

; ### mark-iterator
code mark_iterator, 'mark-iterator'     ; iterator --
        _iterator_sequence
        _ maybe_mark_handle
        next
endcode

; ### mark-string-iterator
code mark_string_iterator, 'mark-string-iterator'       ; string-iterator -> void
        _string_iterator_string
        _ maybe_mark_handle
        next
endcode

; ### mark-slot
code mark_slot, 'mark-slot'             ; slot -> void
        _slot_name
        _ maybe_mark_handle
        next
endcode

; ### mark_string_output_stream
code mark_string_output_stream, 'mark_string_output_stream'     ; raw-stream -> void
        _string_output_stream_sbuf
        _ maybe_mark_handle
        next
endcode

; ### mark-type
code mark_type, 'mark-type'             ; type -> void
        _dup
        _type_symbol
        _ maybe_mark_handle
        _type_layout
        _ maybe_mark_handle
        next
endcode

; ### mark-generic-function             ; generic-function -> void
code mark_generic_function, 'mark-generic-function'
        _dup
        _gf_name
        _ maybe_mark_handle
        _dup
        _gf_methods
        _ maybe_mark_handle
        _gf_dispatch
        _ maybe_mark_handle
        next
endcode

; ### mark-method
code mark_method, 'mark-method'         ; method -> void
        _dup
        _method_generic_function
        _ maybe_mark_handle
        _method_callable
        _ maybe_mark_handle
        next
endcode

asm_global gc_dispatch_table_

; ### initialize_gc_dispatch_table
code initialize_gc_dispatch_table, 'initialize_gc_dispatch_table', SYMBOL_INTERNAL

        ; REVIEW
        _tagged_fixnum 64
        _lit 0
        _ make_array_2

        mov     [gc_dispatch_table_], rbx
        _lit gc_dispatch_table_
        _ gc_add_root

        _handle_to_object_unsafe

        push    this_register
        popd    this_register

        _lit mark_vector
        _lit TYPECODE_VECTOR
        _this_array_set_nth_unsafe

        _lit mark_array
        _lit TYPECODE_ARRAY
        _this_array_set_nth_unsafe

        _lit mark_hashtable
        _lit TYPECODE_HASHTABLE
        _this_array_set_nth_unsafe

        _lit mark_vocab
        _lit TYPECODE_VOCAB
        _this_array_set_nth_unsafe

        _lit mark_symbol
        _lit TYPECODE_SYMBOL
        _this_array_set_nth_unsafe

        _lit mark_quotation
        _lit TYPECODE_QUOTATION
        _this_array_set_nth_unsafe

        _lit mark_slice
        _lit TYPECODE_SLICE
        _this_array_set_nth_unsafe

        _lit mark_tuple
        _lit TYPECODE_TUPLE
        _this_array_set_nth_unsafe

        _lit mark_lexer
        _lit TYPECODE_LEXER
        _this_array_set_nth_unsafe

        _lit mark_iterator
        _lit TYPECODE_ITERATOR
        _this_array_set_nth_unsafe

        _lit mark_thread
        _lit TYPECODE_THREAD
        _this_array_set_nth_unsafe

        _lit mark_string_iterator
        _lit TYPECODE_STRING_ITERATOR
        _this_array_set_nth_unsafe

        _lit mark_slot
        _lit TYPECODE_SLOT
        _this_array_set_nth_unsafe

        _lit mark_type
        _lit TYPECODE_TYPE
        _this_array_set_nth_unsafe

        _lit mark_string_output_stream
        _lit TYPECODE_STRING_OUTPUT_STREAM
        _this_array_set_nth_unsafe

        _lit mark_generic_function
        _lit TYPECODE_GENERIC_FUNCTION
        _this_array_set_nth_unsafe

        _lit mark_method
        _lit TYPECODE_METHOD
        _this_array_set_nth_unsafe

        pop     this_register
        next
endcode

; ### mark-raw-object
code mark_raw_object, 'mark-raw-object' ; raw-object --
        _test_marked_bit
        jnz .1

        _set_marked_bit

        _dup
        _object_raw_typecode

        cmp     rbx, LAST_BUILTIN_TYPECODE
        ja      .2

        pushrbx
        mov     rbx, [gc_dispatch_table_]

        _handle_to_object_unsafe
        _array_nth_unsafe
        test    rbx, rbx
        jz .3
        mov     rax, rbx
        poprbx                          ; -- object
        call    rax
        _return

.3:
        _2drop
        _return

.2:
        _drop
        _ mark_tuple
        _return

.1:
        _drop
        next
endcode

; ### maybe-mark-handle
code maybe_mark_handle, 'maybe-mark-handle', SYMBOL_INTERNAL ; x -> void
        cmp     bl, HANDLE_TAG
        jne     .1
        _handle_to_object_unsafe
        test    rbx, rbx
        jz      .1
        _ mark_raw_object
        next
.1:
        _drop
        next
endcode

; ### maybe_mark_verified_handle
code maybe_mark_verified_handle, 'maybe_mark_verified_handle', SYMBOL_INTERNAL  ; handle --
        _dup
        _ verified_handle?
        cmp     rbx, f_value
        poprbx
        jz      .1                      ; -- handle
        _handle_to_object_unsafe
        test    rbx, rbx
        jz      .1
        _ mark_raw_object
        _return
.1:
        _drop
        next
endcode

; ### maybe_mark_from_root
code maybe_mark_from_root, 'maybe_mark_from_root', SYMBOL_INTERNAL      ; raw-address --
        _fetch
        _ maybe_mark_handle
        next
endcode

; ### mark_cells_in_range
code mark_cells_in_range, 'mark_cells_in_range', SYMBOL_INTERNAL        ; low-address high-address --
        sub     rbx, qword [rbp]        ; -- low-address number-of-bytes
        shr     rbx, 3                  ; -- low-address number-of-cells
        _register_do_times .1
        _raw_loop_index
        shl     rbx, 3
        add     rbx, qword [rbp]
        mov     rbx, [rbx]
        _ maybe_mark_verified_handle
        _loop .1
        _drop
        next
endcode

; ### thread_mark_datastack
code thread_mark_datastack, 'thread_mark_datastack', SYMBOL_INTERNAL    ; thread --
        _dup
        _ thread_saved_rbp
        _swap
        _ thread_raw_sp0
        _ mark_cells_in_range
        next
endcode

; ### mark_datastack
code mark_datastack, 'mark_datastack', SYMBOL_INTERNAL
        _ current_thread
        _ thread_mark_datastack
        next
endcode

; ### thread_mark_return_stack
code thread_mark_return_stack, 'thread_mark_return_stack', SYMBOL_INTERNAL      ; thread --
        _dup
        _ thread_saved_rsp
        _swap
        _ thread_raw_rp0
        _ mark_cells_in_range
        next
endcode

; ### mark_return_stack
code mark_return_stack, 'mark_return_stack', SYMBOL_INTERNAL    ; --
        _ current_thread
        _ thread_mark_return_stack
        next
endcode

; ### thread_mark_locals_stack
code thread_mark_locals_stack, 'thread_mark_locals_stack', SYMBOL_INTERNAL      ; thread --
        _dup
        _ thread_saved_r14
        _swap
        _ thread_raw_lp0
        _ mark_cells_in_range
        next
endcode

; ### mark_locals_stack
code mark_locals_stack, 'mark_locals_stack', SYMBOL_INTERNAL    ; --
        _ current_thread
        _ thread_mark_locals_stack
        next
endcode

; ### mark_thread_stacks
code mark_thread_stacks, 'mark_thread_stacks', SYMBOL_INTERNAL  ; thread -> void

        _debug_print "mark_thread_stacks"

        _lit S_thread_mark_datastack
        _lit S_thread_mark_return_stack
        _lit S_thread_mark_locals_stack
        _ tri
        next
endcode

; ### maybe_collect_handle
code maybe_collect_handle, 'maybe_collect_handle', SYMBOL_INTERNAL
; untagged-handle --

        _dup
        mov     rbx, [rbx]              ; -- untagged-handle raw-object/0

        ; check for null object address
        test    rbx, rbx
        jz      .1

        ; is object marked?
        _test_marked_bit
        jz .2

        ; object is marked
        _nip                            ; -- object
        _unmark_object
        _return

.2:                                     ; -- untagged-handle object
        ; object is not marked
        _ destroy_heap_object           ; -- untagged-handle
        _ release_handle_unsafe
        _return

.1:
        ; null object address, nothing to do
        _2drop
        next
endcode

; ### mark-static-symbols
code mark_static_symbols, 'mark-static-symbols'
        _ last_static_symbol
        _begin .1
        _dup
        _while .1                       ; -- symbol
        _dup
        _ mark_symbol
        _cellminus
        _fetch
        _repeat .1
        _drop
        next
endcode

asm_global stop_for_gc?_, f_value

; ### stop_for_gc?
code stop_for_gc?, 'stop_for_gc?', SYMBOL_INTERNAL      ; -- ?
        pushrbx
        mov     rbx, [stop_for_gc?_]
        next
endcode

asm_global collector_thread_, f_value

; ### collector_thread
code collector_thread, 'collector_thread', SYMBOL_INTERNAL      ; -- thread/f
        pushrbx
        mov     rbx, [collector_thread_]
        next
endcode

; ### stop_for_gc
code stop_for_gc, 'stop_for_gc', SYMBOL_INTERNAL         ; --
        ; store the Feline handle of the current thread in the asm global
        _ current_thread
        xchg    qword [stop_for_gc?_], rbx
        poprbx
        next
endcode

; ### stop_current_thread_for_gc
code stop_current_thread_for_gc, 'stop_current_thread_for_gc', SYMBOL_INTERNAL  ; --

        _debug_print "stop_current_thread_for_gc"

        _ THREAD_STOPPED
        _ current_thread
        _ thread_set_state

        _ current_thread_save_registers

.wait:
        _ stop_for_gc?
        _tagged_if .0
        _lit tagged_zero
        _ sleep
        jmp     .wait
        _then .0

        _debug_print "restarting current thread"

        _ THREAD_RUNNING
        _ current_thread
        _ thread_set_state

        next
endcode

; ### safepoint_stop
code safepoint_stop, 'safepoint_stop', SYMBOL_INTERNAL  ; --
        _ current_thread
        cmp     qword [stop_for_gc?_], rbx
        poprbx
        jne     .2
        _return
.2:
        _ stop_current_thread_for_gc
        next
endcode

; ### safepoint
code safepoint, 'safepoint', SYMBOL_INTERNAL    ; --
        cmp     qword [stop_for_gc?_], f_value
        jne     safepoint_stop
        next
endcode

asm_global in_gc?_, f_value

; ### in-gc?
code in_gc?, 'in-gc?'                   ; -- ?
        pushrbx
        mov     rbx, [in_gc?_]
        next
endcode

; ### gc-start-ticks
value gc_start_ticks, 'gc-start-ticks', 0

; ### gc-end-ticks
value gc_end_ticks, 'gc-end-ticks', 0

; ### gc-start-cycles
value gc_start_cycles, 'gc-start-cycles', 0

; ### gc-end-cycles
value gc_end_cycles, 'gc-end-cycles', 0

asm_global gc_count_value, 0

; ### gc-count
code gc_count, 'gc-count'       ; -- n
        pushrbx
        mov     rbx, [gc_count_value]
        _tag_fixnum
        next
endcode

; ### gc-verbose
feline_global gc_verbose, 'gc-verbose'

; ### gc-inhibit
feline_global gc_inhibit, 'gc-inhibit'

; ### gc-pending
feline_global gc_pending, 'gc-pending'

; ### gc-disable
code gc_disable, 'gc-disable'
        _ maybe_gc
        mov     qword [S_gc_inhibit_symbol_value], t_value
        next
endcode

; ### gc-enable
code gc_enable, 'gc-enable'
        mov     qword [S_gc_inhibit_symbol_value], f_value
        cmp     qword [S_gc_pending_symbol_value], f_value
        je     .1
        mov     qword [S_gc_pending_symbol_value], f_value
        _ gc
.1:
        next
endcode

; ### wait_for_thread_to_stop
code wait_for_thread_to_stop, 'wait_for_thread_to_stop', SYMBOL_INTERNAL        ; thread --

        ; don't stop the collector thread
        cmp     rbx, qword [stop_for_gc?_]
        je      .exit

.top:
        _dup
        _ thread_state
        cmp     rbx, S_THREAD_STOPPED
        poprbx
        je      .exit

        _lit tagged_zero
        _ sleep

        jmp     .top
.exit:
        _drop
        next
endcode

; ### stop_the_world
code stop_the_world, 'stop_the_world', SYMBOL_INTERNAL  ; --

        _debug_print "stop_the_world"

        _ stop_for_gc

        _ all_threads
        _lit S_wait_for_thread_to_stop
        _ vector_each

        next
endcode

; ### start_the_world
code start_the_world, 'start_the_world', SYMBOL_INTERNAL        ; --

        _debug_print "start_the_world"

        mov     eax, f_value
        xchg    qword [stop_for_gc?_], rax

        next
endcode

asm_global gc_lock_, f_value

%macro  _gc_lock 0
        pushrbx
        mov     rbx, [gc_lock_]
%endmacro

; ### gc-lock
code gc_lock, 'gc-lock'                 ; -- mutex
        _gc_lock
        next
endcode

; ### initialize_gc_lock
code initialize_gc_lock, 'initialize_gc_lock', SYMBOL_INTERNAL  ; --
        _ make_mutex
        mov     [gc_lock_], rbx
        poprbx
        _lit gc_lock_
        _ gc_add_root
        next
endcode

; ### gc_collect
code gc_collect, 'gc_collect', SYMBOL_INTERNAL  ; --

        _debug_print "entering gc_collect"

        cmp     qword [S_gc_inhibit_symbol_value], f_value
        je .1
        mov     qword [S_gc_pending_symbol_value], t_value
        _return
.1:
        cmp     qword [S_gc_verbose_symbol_value], f_value
        je .2
        _ ticks
        _to gc_start_ticks
        _rdtsc
        _to gc_start_cycles
.2:
        mov     qword [in_gc?_], t_value

        _thread_count
        cmp     rbx, 1
        poprbx
        jne     .3

        _ current_thread_save_registers

        _debug_print "marking single thread"

        ; data stack
        _ mark_datastack

        ; return stack
        _ mark_return_stack

        ; locals stack
        _ mark_locals_stack

        jmp     .4

.3:
        _ lock_all_threads

        _ stop_the_world

        _ current_thread_save_registers

        _debug_print "marking multiple threads"

        _ all_threads
        _lit S_mark_thread_stacks
        _ vector_each

        _ unlock_all_threads

.4:
        ; static symbols
        _ mark_static_symbols

        ; explicit roots
        _ gc_roots
        _lit S_maybe_mark_from_root
        _ vector_each

        ; sweep
        _lit S_maybe_collect_handle
        _ each_handle

        _ start_the_world

        inc     qword [gc_count_value]

        mov     qword [in_gc?_], f_value

        mov     qword [S_gc_pending_symbol_value], f_value

        cmp     qword [S_gc_verbose_symbol_value], f_value
        je .5

        _rdtsc
        _to gc_end_cycles
        _ ticks
        _to gc_end_ticks

        _ ?nl
        _write "gc "
        _ recent_allocations
        _ decimal_dot
        _write " allocations since last gc"
        _ nl

        _ ?nl
        _write "gc "
        _ gc_end_ticks
        _ gc_start_ticks
        _minus
        _tag_fixnum
        _ decimal_dot
        _write " ms "

        _ gc_end_cycles
        _ gc_start_cycles
        _minus
        _tag_fixnum
        _ decimal_dot
        _write " cycles"
        _ nl

.5:
        _reset_recent_allocations

        _debug_print "leaving gc_collect"

        next
endcode

; ### gc
code gc, 'gc'                           ; --

        _debug_print "entering gc"

        _ gc_lock
        _ mutex_trylock
        _tagged_if_not .1
        ; gc is already in progress
        _debug_print "gc already in progress, returning"
        jmp .exit
        _then .1

        _debug_print "gc obtained gc lock"

.wait:
        _ trylock_handles
        cmp     rbx, f_value
        poprbx
        je      .wait

        _ gc_collect

        _ unlock_handles

        _ gc_lock
        _ mutex_unlock
        _tagged_if_not .2
        _error "gc mutex_unlock failed"
        _then .2

.exit:
        _debug_print "leaving gc"

        next
endcode
