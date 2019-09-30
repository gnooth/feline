; Copyright (C) 2016-2019 Peter Graves <gnooth@gmail.com>

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
code gc_roots, 'gc_roots', SYMBOL_INTERNAL ; -- vector
        pushrbx
        mov     rbx, [gc_roots_]
        next
endcode

; ### gc_add_root
code gc_add_root, 'gc_add_root', SYMBOL_INTERNAL  ; raw-address --
        _ gc_roots
        _ vector_push
        next
endcode

asm_global gc2_work_list_

%macro _gc2_work_list 0                 ; -> ^vector
        pushrbx
        mov     rbx, [gc2_work_list_]
%endmacro

asm_global gc2_work_list_fake_handle_

; ### gc2_work_list
code gc2_work_list, 'gc2_work_list'     ; -> handle
        pushrbx
        mov     rbx, [gc2_work_list_fake_handle_]
        _tag_handle
        next
endcode

; ### gc2_initialize_work_list
code gc2_initialize_work_list, 'gc2_initialize_work_list'
        _debug_print "gc2_initialize_work_list called"

        _lit 1024
        _ new_vector_untagged                           ; -> handle

        _dup
        _handle_to_object_unsafe                        ; -> handle ^vector

        ; store address of vector in asm global
        mov     [gc2_work_list_], rbx                   ; -> handle ^vector
        poprbx                                          ; -> handle

        ; and release its handle
        _untag_handle
        _ release_handle_unsafe                         ; -> empty

        ; set up fake handle
        mov     rax, gc2_work_list_
        mov     [gc2_work_list_fake_handle_], rax
        next
endcode

%define MARK_WHITE 0b00
%define MARK_GRAY  0b01
%define MARK_BLACK 0b10

; ### gc2_maybe_push_handle
code gc2_maybe_push_handle, 'gc2_maybe_push_handle' ; x -> void

        cmp     bl, HANDLE_TAG
        jne     drop                    ; do nothing if x is not a handle

        shr     rbx, HANDLE_TAG_BITS    ; untagged handle in rbx
        mov     rbx, [rbx]              ; ^object in rbx
        test    rbx, rbx                ; check for empty handle
        jz      drop
        cmp     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_WHITE
        jne     drop


        _object_raw_typecode_eax
        cmp     eax, TYPECODE_STRING
        je      .1
        cmp     eax, TYPECODE_SBUF
        je      .1

        mov     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_GRAY

        _gc2_work_list
        _ vector_push_internal
        next

.1:
        mov     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_BLACK
        jmp     drop
endcode

%ifdef DEBUG

; ### gc2_assert_white
code gc2_assert_white, 'gc2_assert_white' ; ^object -> void
;         _print "gc2_assert_white"
        mov     rbx, [rbx]
        ; check for null object address
        test    rbx, rbx
        jnz      .ok
        _drop
        next

.ok:
        cmp     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_WHITE
        jne     .error
        poprbx
        next

.error:
        _error "gc_assert_white error!"
        next
endcode

%endif

; scanners

; ### gc2_scan_vector
code gc2_scan_vector, 'gc2_scan_vector' ; ^vector -> void
;         _debug_print "gc2_scan_vector"

        push    this_register
        mov     this_register, rbx
        _vector_raw_length
        _register_do_times .1
        _raw_loop_index
        _this_vector_nth_unsafe         ; -> element
        _ gc2_maybe_push_handle
        _loop .1
        pop     this_register

        next
endcode

; ### gc2_scan_array
code gc2_scan_array, 'gc2_scan_array'   ; ^array -> void
;         _debug_print "gc2_scan_array"

        push    this_register
        mov     this_register, rbx
        _array_raw_length
        _register_do_times .1
        _raw_loop_index
        _this_array_nth_unsafe
        _ gc2_maybe_push_handle
        _loop .1
        pop     this_register

        next
endcode

; ### gc2_scan_hashtable
code gc2_scan_hashtable, 'gc2_scan_hashtable' ; ^hashtable -> void
;         _debug_print "gc2_scan_hashtable"

        push    this_register
        mov     this_register, rbx      ; -> ^hashtable
        _hashtable_raw_capacity         ; -> capacity
        _register_do_times .1
        _raw_loop_index
        _dup
        _this_hashtable_nth_key
        _ gc2_maybe_push_handle
        _this_hashtable_nth_value
        _ gc2_maybe_push_handle
        _loop .1                        ; -> empty
        pop     this_register

        next
endcode

; ### gc2_scan_vocab
code gc2_scan_vocab, 'gc2_scan_vocab' ; ^vocab -> void
;         _debug_print "gc2_scan_vocab"

        _dup
        _vocab_name
        _ gc2_maybe_push_handle
        _vocab_hashtable
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_static_symbol
code gc2_scan_static_symbol, 'gc2_scan_static_symbol' ; ^symbol -> void
;         _debug_print "gc2_scan_symbol"

        _ verify_static_symbol

        _dup
        _symbol_name
        _ gc2_maybe_push_handle
        _dup
        _symbol_vocab_name
        _ gc2_maybe_push_handle
        _dup
        _symbol_def
        _ gc2_maybe_push_handle
        _dup
        _symbol_props
        _ gc2_maybe_push_handle
        _dup
        _symbol_value
        _ gc2_maybe_push_handle
        _symbol_file
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_symbol
code gc2_scan_symbol, 'gc2_scan_symbol' ; ^symbol -> void
;         _debug_print "gc2_scan_symbol"

        _dup
        _symbol_name
        _ gc2_maybe_push_handle
        _dup
        _symbol_vocab_name
        _ gc2_maybe_push_handle
        _dup
        _symbol_def
        _ gc2_maybe_push_handle
        _dup
        _symbol_props
        _ gc2_maybe_push_handle
        _dup
        _symbol_value
        _ gc2_maybe_push_handle
        _symbol_file
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_quotation
code gc2_scan_quotation, 'gc2_scan_quotation' ; ^quotation -> void
;         _debug_print "gc2_scan_quotation"

        _quotation_array
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_slice
code gc2_scan_slice, 'gc2_scan_slice' ; ^slice -> void
;         _debug_print "gc2_scan_slice"

        _slice_seq
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_tuple
code gc2_scan_tuple, 'gc2_scan_tuple' ; ^tuple -> void
        _debug_?enough 1
;         _debug_print "gc2_scan_tuple"

        push    this_register
        mov     this_register, rbx      ; -> ^tuple

        _ tuple_size_unchecked          ; -> size
        _check_fixnum                   ; untagged size (number of defined slots) in rbx

        ; slot 0 is object header
        add     rbx, 1                  ; loop limit is size + 1
        _lit 1                          ; loop start is 1

        ; -> limit start
        _?do .1
        _i
        _this_nth_slot
        _ gc2_maybe_push_handle
        _loop .1

        pop     this_register

        next
endcode

; ### gc2_scan_lexer
code gc2_scan_lexer, 'gc2_scan_lexer' ; ^lexer -> void
;         _debug_print "gc2_scan_lexer"

        _dup
        _lexer_string
        _ gc2_maybe_push_handle
        _lexer_file
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_iterator
code gc2_scan_iterator, 'gc2_scan_iterator' ; iterator -> void
;         _debug_print "gc2_scan_iterator"
        _iterator_sequence
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_thread
code gc2_scan_thread, 'gc2_scan_thread' ; ^thread -> void
;         _debug_print "gc2_scan_thread"

        _dup
        _slot THREAD_QUOTATION_SLOT#
        _ gc2_maybe_push_handle

        _dup
        _slot THREAD_THREAD_LOCALS_SLOT#
        _ gc2_maybe_push_handle

        _dup
        _slot THREAD_RESULT_SLOT#
        _ gc2_maybe_push_handle

        _dup
        _slot THREAD_DEBUG_NAME_SLOT#
        _ gc2_maybe_push_handle

        _slot THREAD_CATCHSTACK_SLOT#
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_string_iterator
code gc2_scan_string_iterator, 'gc2_scan_string_iterator'       ; string-iterator -> void
;         _debug_print "gc2_scan_string_iterator"

        _string_iterator_string
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_slot
code gc2_scan_slot, 'gc2_scan_slot' ; slot -> void
;         _debug_print "gc2_scan_slot"

        _slot_name
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_string_output_stream
code gc2_scan_string_output_stream, 'gc2_scan_string_output_stream' ; ^stream -> void
;         _debug_print "gc2_scan_string_output_stream"

        _string_output_stream_sbuf
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_type
code gc2_scan_type, 'gc2_scan_type' ; ^type -> void
;         _debug_print "gc2_scan_type"

        _dup
        _type_symbol
        _ gc2_maybe_push_handle
        _type_layout
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_generic_function
code gc2_scan_generic_function, 'gc2_scan_generic_function' ; ^generic-function -> void
;         _debug_print "gc2_scan_generic_function"

        _dup
        _gf_name
        _ gc2_maybe_push_handle
        _dup
        _gf_methods
        _ gc2_maybe_push_handle
        _gf_dispatch
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_method
code gc2_scan_method, 'gc2_scan_method' ; ^method -> void
;         _debug_print "gc2_scan_method"

        _dup
        _method_generic_function
        _ gc2_maybe_push_handle
        _method_callable
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_object
code gc2_scan_object, 'gc2_scan_object' ; ^object -> void
;         _debug_print "gc2_scan_object"

        _dup
        _object_raw_typecode

        cmp     rbx, LAST_BUILTIN_TYPECODE
        jg      .2

        pushrbx
        mov     rbx, [gc2_dispatch_table_]

        _handle_to_object_unsafe

        test    rbx, rbx
        jnz     .ok
        _error "no dispatch table"

.ok:
        _array_nth_unsafe
        test    rbx, rbx
        jz .3
        mov     rax, rbx
        poprbx                          ; -- object
        call    rax
        next

.3:
        _2drop
        next

.2:
        _drop
        _ gc2_scan_tuple
        next

.1:
        _drop
        next
endcode

asm_global gc2_dispatch_table_

; ### initialize_gc2_dispatch_table
code initialize_gc2_dispatch_table, 'initialize_gc2_dispatch_table'

        ; REVIEW
        _tagged_fixnum 64
        _lit 0
        _ make_array_2

        mov     [gc2_dispatch_table_], rbx
        _lit gc2_dispatch_table_
        _ gc_add_root

        _handle_to_object_unsafe

        push    this_register
        popd    this_register

        _lit gc2_scan_vector
        _lit TYPECODE_VECTOR
        _this_array_set_nth_unsafe

        _lit gc2_scan_array
        _lit TYPECODE_ARRAY
        _this_array_set_nth_unsafe

        _lit gc2_scan_hashtable
        _lit TYPECODE_HASHTABLE
        _this_array_set_nth_unsafe

        _lit gc2_scan_vocab
        _lit TYPECODE_VOCAB
        _this_array_set_nth_unsafe

        _lit gc2_scan_symbol
        _lit TYPECODE_SYMBOL
        _this_array_set_nth_unsafe

        _lit gc2_scan_quotation
        _lit TYPECODE_QUOTATION
        _this_array_set_nth_unsafe

        _lit gc2_scan_slice
        _lit TYPECODE_SLICE
        _this_array_set_nth_unsafe

        _lit gc2_scan_tuple
        _lit TYPECODE_TUPLE
        _this_array_set_nth_unsafe

        _lit gc2_scan_lexer
        _lit TYPECODE_LEXER
        _this_array_set_nth_unsafe

        _lit gc2_scan_iterator
        _lit TYPECODE_ITERATOR
        _this_array_set_nth_unsafe

        _lit gc2_scan_thread
        _lit TYPECODE_THREAD
        _this_array_set_nth_unsafe

        _lit gc2_scan_string_iterator
        _lit TYPECODE_STRING_ITERATOR
        _this_array_set_nth_unsafe

        _lit gc2_scan_slot
        _lit TYPECODE_SLOT
        _this_array_set_nth_unsafe

        _lit gc2_scan_type
        _lit TYPECODE_TYPE
        _this_array_set_nth_unsafe

        _lit gc2_scan_string_output_stream
        _lit TYPECODE_STRING_OUTPUT_STREAM
        _this_array_set_nth_unsafe

        _lit gc2_scan_generic_function
        _lit TYPECODE_GENERIC_FUNCTION
        _this_array_set_nth_unsafe

        _lit gc2_scan_method
        _lit TYPECODE_METHOD
        _this_array_set_nth_unsafe

        pop     this_register

        next
endcode

; begin old code from gc.asm

asm_global gc_dispatch_table_

; ### mark_byte
code mark_byte, 'mark_byte' ; handle -> fixnum/nil
        cmp     bl, HANDLE_TAG
        jne     .1
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]              ; ^object in rbx
        test    rbx, rbx
        jz      .1
        movzx   rbx, byte [rbx + OBJECT_MARK_BYTE_OFFSET]
        _tag_fixnum
        next
.1:
        mov     ebx, nil_value
        next
endcode

; ### gc2_scan_verified_handle
code gc2_scan_verified_handle, 'gc2_scan_verified_handle' ; handle -> empty
;        _debug_print "gc2_scan_verified_handle"
        _dup
        _ verified_handle?
        cmp     rbx, f_value
        poprbx
        jz      .1                      ; -> handle
;         _handle_to_object_unsafe
;         test    rbx, rbx
;         jz      .1
; ;         _ mark_raw_object
;         _ gc2_add_raw_object
        _ gc2_maybe_push_handle
        _return
.1:
        _drop
        next
endcode

; ### gc2_visit_root
code gc2_visit_root, 'gc2_visit_root' ; raw-address -> void
;         _debug_print "gc2_visit_root"
        _fetch
;         cmp     bl, HANDLE_TAG
;         jne     .1
; ;         _handle_to_object_unsafe
; ;         test    rbx, rbx
; ;         jz      .1
; ;         _ mark_raw_object
;         _ gc2_work_list
;         _ vector_push
;         next
; .1:
;         _debug_print "not a handle"
;         _drop

        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_cells_in_range
code gc2_scan_cells_in_range, 'gc2_scan_cells_in_range' ; low-address high-address -> void
        sub     rbx, qword [rbp]        ; -> low-address number-of-bytes
        shr     rbx, 3                  ; -> low-address number-of-cells
        _register_do_times .1
        _raw_loop_index
        shl     rbx, 3
        add     rbx, qword [rbp]
        mov     rbx, [rbx]
        _ gc2_scan_verified_handle
        _loop .1
        _drop
        next
endcode

; ### gc2_thread_scan_data_stack
code gc2_thread_scan_data_stack, 'gc2_thread_scan_data_stack' ; thread -> void
        _dup
        _ thread_saved_rbp
        _swap
        _ thread_raw_sp0
        _ gc2_scan_cells_in_range
        next
endcode

; ### gc2_scan_data_stack
code gc2_scan_data_stack, 'gc2_scan_data_stack'
        _debug_print "gc2_scan_data_stack called"
        _ current_thread
        _ gc2_thread_scan_data_stack
        next
endcode

; ### gc2_thread_scan_return_stack
code gc2_thread_scan_return_stack, 'gc2_thread_scan_return_stack' ; thread -> void
        _dup
        _ thread_saved_rsp
        _swap
        _ thread_raw_rp0
        _ gc2_scan_cells_in_range
        next
endcode

; ### gc2_scan_return_stack
code gc2_scan_return_stack, 'gc2_scan_return_stack'
        _debug_print "gc2_scan_return_stack called"
        _ current_thread
        _ gc2_thread_scan_return_stack
        next
endcode

; ### gc2_scan_thread_stacks
code gc2_scan_thread_stacks, 'gc2_scan_thread_stacks' ; thread -> void
        _debug_print "gc2_scan_thread_stacks called"

        _lit S_gc2_thread_scan_data_stack
        _lit S_gc2_thread_scan_return_stack
        _ bi

        next
endcode

; ### gc2_maybe_collect_handle
code gc2_maybe_collect_handle, 'gc2_maybe_collect_handle' ; untagged-handle -> void

        _dup
        mov     rbx, [rbx]              ; -> untagged-handle ^object/0

        ; check for null object address
        test    rbx, rbx
        jz      twodrop

        cmp     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_WHITE
        je      .2

        ; object is not white
        _nip                            ; -> ^object
        mov     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_WHITE
        jmp     drop

.2:                                     ; -> untagged-handle object
        ; object is white
        _ destroy_heap_object           ; -> untagged-handle
        _ release_handle_unsafe
        _return
endcode

; ### gc2_scan_static_symbols
code gc2_scan_static_symbols, 'gc2_scan_static_symbols'
;         _debug_print "entering gc2_scan_static_symbols"

        _ last_static_symbol
        _begin .1
        _dup
        _while .1                       ; -- symbol
        _dup
        _ gc2_scan_static_symbol
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
code gc_lock, 'gc_lock' ; -> mutex
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
code gc_collect, 'gc_collect', SYMBOL_INTERNAL

        _ gc2_collect
        _return

endcode

asm_global gc2_work_list_max_

; ### gc2_work_list_max
code gc2_work_list_max, 'gc2_work_list_max'
        pushrbx
        mov     rbx, [gc2_work_list_max_]
        _tag_fixnum
        next
endcode

; ### gc2_process_work_list
code gc2_process_work_list, 'gc2_process_work_list'

%ifdef DEBUG
        _ gc2_work_list
        _ vector_raw_length
        mov     [gc2_work_list_max_], rbx
        _drop
%endif

.top:

%ifdef DEBUG
        _ gc2_work_list
        _ vector_raw_length
        cmp     [gc2_work_list_max_], rbx
        jge     .1
        mov     [gc2_work_list_max_], rbx
.1:
        _drop
%endif

        _gc2_work_list                  ; -> ^vector
        _ vector_?pop_internal          ; -> ^object/nil
        cmp     rbx, nil_value
        je      drop                    ; normal exit

        ; -> ^object
        cmp     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_GRAY
        jne     .not_gray
        mov     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_BLACK

        _ gc2_scan_object

        jmp     .top

; .normal_exit:
;         _drop
;         next

; .not_a_handle:
;         _error "not a handle"
;         next
;
; .empty_handle:
;         _print "empty handle on work list"
;         _drop
;         next

.not_gray:
;         movzx   rbx, byte [rax + OBJECT_MARK_BYTE_OFFSET]
        movzx   rbx, byte [rbx + OBJECT_MARK_BYTE_OFFSET]
        _write "handle on work list is not gray: "
        _ hexdot
        _ nl
        next
endcode

; ### gc2_collect
code gc2_collect, 'gc2_collect'

;         _debug_print "entering gc2_collect"

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

%ifdef DEBUG
        ; verify that all handles are white
        _lit gc2_assert_white
        _ each_handle
%endif

        ; data stack
        _ gc2_scan_data_stack

        ; return stack
        _ gc2_scan_return_stack

        jmp     .4

.3:
        _ lock_all_threads

        _ stop_the_world

        _ current_thread_save_registers

        _debug_print "marking multiple threads"

        _ all_threads
        _lit S_gc2_scan_thread_stacks
        _ vector_each

        _ unlock_all_threads

.4:
        ; static symbols
        _ gc2_scan_static_symbols

        ; explicit roots
        _ gc_roots
        _lit gc2_visit_root
        _ vector_each_internal

        ; work list is ready to go
        _ gc2_process_work_list

        ; sweep
        _debug_print "collecting handles"
        _lit gc2_maybe_collect_handle
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

;         _debug_print "leaving gc2_collect"

        next
endcode

; ### gc
code gc, 'gc'

        _ gc2
        _return

endcode

; ### gc2
code gc2, 'gc2'

        _debug_print "entering gc2"

        _ gc_lock
        _ mutex_trylock
        _tagged_if_not .1
        ; gc is already in progress
        _debug_print "gc already in progress, returning"
        jmp .exit
        _then .1

        _debug_print "gc2 obtained gc lock"

.wait:
        _ trylock_handles
        cmp     rbx, f_value
        poprbx
        je      .wait

        _ gc2_collect

        _ unlock_handles

        _ gc_lock
        _ mutex_unlock
        _tagged_if_not .2
        _error "gc mutex_unlock failed"
        _then .2

.exit:
        _debug_print "leaving gc2"
%ifdef DEBUG
        _write "gc2_work_list_max = "
        _ gc2_work_list_max
        _ dot_object
%endif
        next
endcode
