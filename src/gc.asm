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
code mark_symbol, 'mark-symbol'         ; symbol --
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
        ; REVIEW name vocab
        next
endcode

; ### mark-quotation
code mark_quotation, 'mark-quotation'   ; quotation --
        _quotation_array
        _ maybe_mark_handle
        ; REVIEW code
        next
endcode

; ### mark-curry
code mark_curry, 'mark-curry'           ; curry --
        _dup
        _curry_object
        _ maybe_mark_handle
        _curry_callable
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
        _untag_fixnum                   ; untagged size (number of defined slots) in rbx

        ; slot 0 is object header
        ; slot 1 is layout
        ; slot 2 is first defined slot
        ; so:
        add     rbx, 2                  ; loop limit is size + 2
        _lit 2                          ; loop start is 2

        ; -- limit start
        _?do .1
        _i
        _this_nth_slot
        _ maybe_mark_handle
        _loop .1

        pop     this_register
        next
endcode

; ### mark_tuple_class
code mark_tuple_class, 'mark_tuple_class'       ; tuple-class --
        _dup
        _tuple_class_name
        _ maybe_mark_handle
        _dup
        _tuple_class_slots
        _ maybe_mark_handle
        _tuple_class_layout
        _ maybe_mark_handle
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

asm_global gc_dispatch_table_

; ### initialize_gc_dispatch_table
code initialize_gc_dispatch_table, 'initialize_gc_dispatch_table', SYMBOL_INTERNAL
; --
        _lit 32
        _lit 0
        _ new_array_untagged
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

        _lit mark_curry
        _lit TYPECODE_CURRY
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

        _lit mark_tuple_class
        _lit TYPECODE_TUPLE_CLASS
        _this_array_set_nth_unsafe

        _lit mark_thread
        _lit TYPECODE_THREAD
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

; ### maybe_mark_handle
code maybe_mark_handle, 'maybe_mark_handle', SYMBOL_INTERNAL    ; handle --
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        _ mark_raw_object
        _return
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

; ### thread_mark_data_stack
code thread_mark_data_stack, 'thread_mark_data_stack'   ; thread --
        _dup
        _ thread_saved_rbp
        _swap
        _ thread_raw_sp0
        _ mark_cells_in_range
        next
endcode

; ### mark-data-stack
code mark_data_stack, 'mark-data-stack' ; --
        _ current_thread
        _ thread_mark_data_stack
        next
endcode

; ### mark_return_stack
code mark_return_stack, 'mark_return_stack', SYMBOL_INTERNAL    ; --

        push    r12
        _rdepth
        mov     r12, rbx                ; depth in r12
        test    r12, r12
        jz      .2
.1:
        mov     rax, [rsp + r12 * BYTES_PER_CELL]

%ifdef TAGGED_HANDLES
        cmp     al, HANDLE_TAG
        jne     .3

        ; tag byte is ok, but the return stack is a jungle
        ; see x_test_mark_return_stack below

        ; make a copy in rdx (maybe_mark_handle expects a tagged handle)
        mov     rdx, rax

        shr     rdx, HANDLE_TAG_BITS

        ; handles are 8-byte aligned
        test    dl, 7
        jnz     .3

        ; must be in handle space
        cmp     rdx, [handle_space_]
        jb      .3
        cmp     rdx, [handle_space_free_]
        jae     .3
%else
        test    eax, LOWTAG_MASK
        jnz     .3
%endif

        pushrbx
        mov     rbx, rax
        _ maybe_mark_handle
.3:
        dec     r12
        jnz     .1
.2:
        poprbx
        pop     r12
        next
endcode

; ### x_test_mark_return_stack
; A test to verify that mark_return_stack is not confused by some arbitrary
; return address with a low byte matching HANDLE_TAG.
code x_test_mark_return_stack, 'x_test_mark_return_stack', SYMBOL_INTERNAL      ; -- 0xf2
%ifdef HANDLE_TAG
        mov     eax, HANDLE_TAG
%else
        ; HANDLE_TAG is 0xf2
        mov     eax, 0xf2
%endif
        push    rax
        _ gc
        pop     rax
        pushrbx
        mov     rbx, rax
        _tag_fixnum
        next
endcode

; ### mark_cells_in_range
code mark_cells_in_range, 'mark_cells_in_range', SYMBOL_INTERNAL
; low-address high-address --
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

; ### mark-locals-stack
code mark_locals_stack, 'mark-locals-stack'     ; --
        _lpfetch
        _ current_thread_raw_lp0
        _ mark_cells_in_range
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

; ### stop-for-gc?
code stop_for_gc?, 'stop-for-gc?'       ; -- ?
        pushrbx
        mov     rbx, [stop_for_gc?_]
        next
endcode

; ### stop-for-gc
code stop_for_gc, 'stop-for-gc'         ; --
        _ current_thread
        mov     qword [stop_for_gc?_], rbx
        poprbx
        next
endcode

; ### restart-after-gc
code restart_after_gc, 'restart-after-gc'       ; --
        mov     qword [stop_for_gc?_], f_value
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

; ### gc
code gc, 'gc'                           ; --
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

        _ current_thread_save_registers

        ; data stack
        _ mark_data_stack

        ; return stack
        _ mark_return_stack

        ; locals stack
        _ mark_locals_stack

        ; static symbols
        _ mark_static_symbols

        ; explicit roots
        _ gc_roots
        _lit S_maybe_mark_from_root
        _ vector_each

        ; sweep
        _lit S_maybe_collect_handle
        _ each_handle

        inc     qword [gc_count_value]

        mov     qword [in_gc?_], f_value

        mov     qword [S_gc_pending_symbol_value], f_value

        cmp     qword [S_gc_verbose_symbol_value], f_value
        je .3
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

.3:
        _reset_recent_allocations

        next
endcode
