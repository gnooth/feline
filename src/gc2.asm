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

asm_global gc2_work_list_raw_vector_

%macro _gc2_work_list_raw_vector 0                 ; -> ^vector
        pushrbx
        mov     rbx, [gc2_work_list_raw_vector_]
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

        _lit 256
        _ new_vector_untagged                           ; -> handle

        _dup
        _handle_to_object_unsafe                        ; -> handle ^vector

        ; store address of raw vector in asm global
        mov     [gc2_work_list_raw_vector_], rbx        ; -> handle ^vector
        poprbx                                          ; -> handle

        ; and release its handle
        _untag_handle
        _ release_handle_unsafe                         ; -> empty

        mov     rax, gc2_work_list_raw_vector_
        mov     [gc2_work_list_fake_handle_], rax
        next
endcode

%define MARK_WHITE 0b00
%define MARK_GRAY  0b01
%define MARK_BLACK 0b10

%macro  _mark_bits 0                    ; ^object -> mark-bits
        _object_mark_byte
        and     rbx, 0xb11
%endmacro

%macro  _mark_white 0
        mov     OBJECT_MARK_BYTE, MARK_WHITE
%endmacro

%macro  _mark_gray 0
        mov     OBJECT_MARK_BYTE, MARK_GRAY
%endmacro

%macro  _mark_black 0
        mov      OBJECT_MARK_BYTE, MARK_BLACK
%endmacro

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
        _error "gc_verify_white error!"
        next
endcode

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
        _zero
        _?do .1
        _i
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
code gc2_scan_vocab, 'gc2_scan_vocab'   ; vocab -> void
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
code gc2_scan_quotation, 'gc2_scan_quotation' ; quotation -> void
;         _debug_print "gc2_scan_quotation"

        _quotation_array
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_slice
code gc2_scan_slice, 'gc2_scan_slice'   ; slice -> void
;         _debug_print "gc2_scan_slice"

        _slice_seq
        _ gc2_maybe_push_handle

        next
endcode

; ### gc2_scan_tuple
code gc2_scan_tuple, 'gc2_scan_tuple'   ; ^tuple -> void
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
code gc2_scan_lexer, 'gc2_scan_lexer'   ; lexer -> void
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

;         ; FIXME
;         _drop
        _debug_?enough 1

;         _test_marked_bit
;         jnz .1

;         _set_marked_bit

        test    rbx, rbx
        jz      error_empty_handle

        ; REVIEW this is probably redundant
        mov     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_BLACK

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

; ### gc2_scan_handle
code gc2_scan_handle, 'gc2_scan_handle' ; handle -> void
        cmp     bl, HANDLE_TAG
        jne     .1
        _handle_to_object_unsafe        ; -> ^object
        test    rbx, rbx
        jz      .1
        _ gc2_scan_object
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

; ; ### mark-vector
; code mark_vector, 'mark-vector'         ; vector --
;         push    this_register
;         mov     this_register, rbx
;         _vector_raw_length
;         _register_do_times .1
;         _raw_loop_index
;         _this_vector_nth_unsafe         ; -- element
;         _ maybe_mark_handle
;         _loop .1                        ; --
;         pop     this_register
;         next
; endcode

; ; ### mark-array
; code mark_array, 'mark-array'           ; array --
;         push    this_register
;         mov     this_register, rbx
;         _array_raw_length
;         _zero
;         _?do .1
;         _i
;         _this_array_nth_unsafe          ; -- element
;         _ maybe_mark_handle
;         _loop .1                        ; --
;         pop     this_register
;         next
; endcode

; ; ### mark-hashtable
; code mark_hashtable, 'mark-hashtable'   ; hashtable --
;         push    this_register
;         mov     this_register, rbx      ; -- hashtable
;         _hashtable_raw_capacity         ; -- capacity
;         _register_do_times .1
;         _raw_loop_index
;         _dup
;         _this_hashtable_nth_key
;         _ maybe_mark_handle
;         _this_hashtable_nth_value
;         _ maybe_mark_handle
;         _loop .1                        ; --
;         pop     this_register
;         next
; endcode

; ; ### mark-vocab
; code mark_vocab, 'mark-vocab'           ; vocab --
;         _dup
;         _vocab_name
;         _ maybe_mark_handle
;         _vocab_hashtable
;         _ maybe_mark_handle
;         next
; endcode

; ; ### mark-symbol
; code mark_symbol, 'mark-symbol'         ; symbol -> void
;         _dup
;         _symbol_name
;         _ maybe_mark_handle
;         _dup
;         _symbol_vocab_name
;         _ maybe_mark_handle
;         _dup
;         _symbol_def
;         _ maybe_mark_handle
;         _dup
;         _symbol_props
;         _ maybe_mark_handle
;         _dup
;         _symbol_value
;         _ maybe_mark_handle
;         _symbol_file
;         _ maybe_mark_handle
;         next
; endcode

; ; ### mark-quotation
; code mark_quotation, 'mark-quotation'   ; quotation --
;         _quotation_array
;         _ maybe_mark_handle
;         ; REVIEW code
;         next
; endcode

; ; ### mark-slice
; code mark_slice, 'mark-slice'           ; slice --
;         _slice_seq
;         _ maybe_mark_handle
;         ; REVIEW code
;         next
; endcode

; ; ### mark-tuple
; code mark_tuple, 'mark-tuple'           ; tuple --
;         push    this_register
;         mov     this_register, rbx      ; -- tuple

;         _ tuple_size_unchecked          ; -- size
;         _check_fixnum                   ; untagged size (number of defined slots) in rbx

;         ; slot 0 is object header
;         add     rbx, 1                  ; loop limit is size + 1
;         _lit 1                          ; loop start is 1

;         ; -- limit start
;         _?do .1
;         _i
;         _this_nth_slot
;         _ maybe_mark_handle
;         _loop .1

;         pop     this_register
;         next
; endcode

; ; ### mark-lexer
; code mark_lexer, 'mark-lexer'           ; lexer --
;         _dup
;         _lexer_string
;         _ maybe_mark_handle
;         _lexer_file
;         _ maybe_mark_handle
;         next
; endcode

; ; ### mark-iterator
; code mark_iterator, 'mark-iterator'     ; iterator --
;         _iterator_sequence
;         _ maybe_mark_handle
;         next
; endcode

; ; ### mark-string-iterator
; code mark_string_iterator, 'mark-string-iterator'       ; string-iterator -> void
;         _string_iterator_string
;         _ maybe_mark_handle
;         next
; endcode

; ; ### mark-slot
; code mark_slot, 'mark-slot'             ; slot -> void
;         _slot_name
;         _ maybe_mark_handle
;         next
; endcode

; ; ### mark_string_output_stream
; code mark_string_output_stream, 'mark_string_output_stream'     ; raw-stream -> void
;         _string_output_stream_sbuf
;         _ maybe_mark_handle
;         next
; endcode

; ; ### mark-type
; code mark_type, 'mark-type'             ; type -> void
;         _dup
;         _type_symbol
;         _ maybe_mark_handle
;         _type_layout
;         _ maybe_mark_handle
;         next
; endcode

; ; ### mark-generic-function             ; generic-function -> void
; code mark_generic_function, 'mark-generic-function'
;         _dup
;         _gf_name
;         _ maybe_mark_handle
;         _dup
;         _gf_methods
;         _ maybe_mark_handle
;         _gf_dispatch
;         _ maybe_mark_handle
;         next
; endcode

; ; ### mark-method
; code mark_method, 'mark-method'         ; method -> void
;         _dup
;         _method_generic_function
;         _ maybe_mark_handle
;         _method_callable
;         _ maybe_mark_handle
;         next
; endcode

asm_global gc_dispatch_table_

; ; ### initialize_gc_dispatch_table
; code initialize_gc_dispatch_table, 'initialize_gc_dispatch_table', SYMBOL_INTERNAL
;
;         ; REVIEW
;         _tagged_fixnum 64
;         _lit 0
;         _ make_array_2
;
;         mov     [gc_dispatch_table_], rbx
;         _lit gc_dispatch_table_
;         _ gc_add_root
;
;         _handle_to_object_unsafe
;
;         push    this_register
;         popd    this_register
;
;         _lit mark_vector
;         _lit TYPECODE_VECTOR
;         _this_array_set_nth_unsafe
;
;         _lit mark_array
;         _lit TYPECODE_ARRAY
;         _this_array_set_nth_unsafe
;
;         _lit mark_hashtable
;         _lit TYPECODE_HASHTABLE
;         _this_array_set_nth_unsafe
;
;         _lit mark_vocab
;         _lit TYPECODE_VOCAB
;         _this_array_set_nth_unsafe
;
;         _lit mark_symbol
;         _lit TYPECODE_SYMBOL
;         _this_array_set_nth_unsafe
;
;         _lit mark_quotation
;         _lit TYPECODE_QUOTATION
;         _this_array_set_nth_unsafe
;
;         _lit mark_slice
;         _lit TYPECODE_SLICE
;         _this_array_set_nth_unsafe
;
;         _lit mark_tuple
;         _lit TYPECODE_TUPLE
;         _this_array_set_nth_unsafe
;
;         _lit mark_lexer
;         _lit TYPECODE_LEXER
;         _this_array_set_nth_unsafe
;
;         _lit mark_iterator
;         _lit TYPECODE_ITERATOR
;         _this_array_set_nth_unsafe
;
;         _lit mark_thread
;         _lit TYPECODE_THREAD
;         _this_array_set_nth_unsafe
;
;         _lit mark_string_iterator
;         _lit TYPECODE_STRING_ITERATOR
;         _this_array_set_nth_unsafe
;
;         _lit mark_slot
;         _lit TYPECODE_SLOT
;         _this_array_set_nth_unsafe
;
;         _lit mark_type
;         _lit TYPECODE_TYPE
;         _this_array_set_nth_unsafe
;
;         _lit mark_string_output_stream
;         _lit TYPECODE_STRING_OUTPUT_STREAM
;         _this_array_set_nth_unsafe
;
;         _lit mark_generic_function
;         _lit TYPECODE_GENERIC_FUNCTION
;         _this_array_set_nth_unsafe
;
;         _lit mark_method
;         _lit TYPECODE_METHOD
;         _this_array_set_nth_unsafe
;
;         pop     this_register
;         next
; endcode

; ; ### mark-raw-object
; code mark_raw_object, 'mark-raw-object' ; raw-object --
;         _test_marked_bit
;         jnz .1
;
;         _set_marked_bit
;
;         _dup
;         _object_raw_typecode
;
;         cmp     rbx, LAST_BUILTIN_TYPECODE
;         ja      .2
;
;         pushrbx
;         mov     rbx, [gc_dispatch_table_]
;
;         _handle_to_object_unsafe
;         _array_nth_unsafe
;         test    rbx, rbx
;         jz .3
;         mov     rax, rbx
;         poprbx                          ; -- object
;         call    rax
;         _return
;
; .3:
;         _2drop
;         _return
;
; .2:
;         _drop
;         _ mark_tuple
;         _return
;
; .1:
;         _drop
;         next
; endcode

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
        mov     rbx, f_value
        next
endcode

; ### gc2_maybe_push_handle
code gc2_maybe_push_handle, 'gc2_maybe_push_handle' ; x -> void
        cmp     bl, HANDLE_TAG
        jne     .1

;         _dup
;         _ object_raw_typecode
;         cmp     rbx, TYPECODE_STRING
;         poprbx
;         jne     .0
;         _debug_print "gc2_maybe_push_handle string"
; .0:

;         _handle_to_object_unsafe
;         test    rbx, rbx
;         jz      .1
;         _ mark_raw_object
        mov     rax, rbx                ; use rax as work register
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]              ; ^object in rax
        test    rax, rax                ; check for empty handle
        jz      .1
        cmp     byte [rax + OBJECT_MARK_BYTE_OFFSET], MARK_WHITE
        jne     .1
        mov     byte [rax + OBJECT_MARK_BYTE_OFFSET], MARK_GRAY

;         _dup
;         _ mark_byte
;         _ hexdot
;         _ nl

        _ gc2_work_list
        _ vector_push
        next
.1:
;         mov     rbx, rax
;         _write "skipping "
;         _ mark_byte
;         _ dot_object
        _drop

        next
endcode

; ### gc2_add_handle_to_work_list
code gc2_add_handle_to_work_list, 'gc2_add_handle_to_work_list' ; handle -> void
        _debug_print "gc2_add_handle_to_work_list called"
        _drop ; FIXME
        next
endcode

; ### gc2_add_raw_object
code gc2_add_raw_object, 'gc2_add_raw_object' ; ^object -> void
        _debug_print "gc2_add_raw_object called"
        _drop ; FIXME
        next
endcode

; ; ### maybe-mark-handle
; code maybe_mark_handle, 'maybe-mark-handle', SYMBOL_INTERNAL ; x -> void
;         cmp     bl, HANDLE_TAG
;         jne     .1
;         _handle_to_object_unsafe
;         test    rbx, rbx
;         jz      .1
;         _ mark_raw_object
;         next
; .1:
;         _drop
;         next
; endcode

; ; ### add-object-address-to-gray-list
; code maybe_add_object_address_to_gray_list, 'maybe-add-object-address-to-gray-list'
;         cmp     bl, HANDLE_TAG
;         jne     .1
;         _handle_to_object_unsafe
;         test    rbx, rbx
;         jz      .1
; ;         _ mark_raw_object
;         _mark_gray
;         next
; .1:
;         _drop
;         next
; endcode

; ; ### maybe_mark_verified_handle
; code maybe_mark_verified_handle, 'maybe_mark_verified_handle', SYMBOL_INTERNAL  ; handle --
;         _dup
;         _ verified_handle?
;         cmp     rbx, f_value
;         poprbx
;         jz      .1                      ; -- handle
;         _handle_to_object_unsafe
;         test    rbx, rbx
;         jz      .1
;         _ mark_raw_object
;         _return
; .1:
;         _drop
;         next
; endcode

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

; ; ### maybe_mark_from_root
; code maybe_mark_from_root, 'maybe_mark_from_root', SYMBOL_INTERNAL      ; raw-address --
;         _fetch
;         _ maybe_mark_handle
;         next
; endcode

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

; ; ### mark_cells_in_range
; code mark_cells_in_range, 'mark_cells_in_range', SYMBOL_INTERNAL        ; low-address high-address --
;         sub     rbx, qword [rbp]        ; -- low-address number-of-bytes
;         shr     rbx, 3                  ; -- low-address number-of-cells
;         _register_do_times .1
;         _raw_loop_index
;         shl     rbx, 3
;         add     rbx, qword [rbp]
;         mov     rbx, [rbx]
;         _ maybe_mark_verified_handle
;         _loop .1
;         _drop
;         next
; endcode

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

; ; ### thread_mark_datastack
; code thread_mark_datastack, 'thread_mark_datastack', SYMBOL_INTERNAL    ; thread --
;         _dup
;         _ thread_saved_rbp
;         _swap
;         _ thread_raw_sp0
;         _ mark_cells_in_range
;         next
; endcode

; ; ### mark_datastack
; code mark_datastack, 'mark_datastack', SYMBOL_INTERNAL
;         _ current_thread
;         _ thread_mark_datastack
;         next
; endcode

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

; ; ### thread_mark_return_stack
; code thread_mark_return_stack, 'thread_mark_return_stack', SYMBOL_INTERNAL      ; thread --
;         _dup
;         _ thread_saved_rsp
;         _swap
;         _ thread_raw_rp0
;         _ mark_cells_in_range
;         next
; endcode

; ; ### mark_return_stack
; code mark_return_stack, 'mark_return_stack', SYMBOL_INTERNAL    ; --
;         _ current_thread
;         _ thread_mark_return_stack
;         next
; endcode

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

; ; ### mark_thread_stacks
; code mark_thread_stacks, 'mark_thread_stacks', SYMBOL_INTERNAL ; thread -> void

;         _debug_print "mark_thread_stacks called"

;         _lit S_thread_mark_datastack
;         _lit S_thread_mark_return_stack
;         _ bi

;         next
; endcode

; ### gc2_scan_thread_stacks
code gc2_scan_thread_stacks, 'gc2_scan_thread_stacks' ; thread -> void
        _debug_print "gc2_scan_thread_stacks called"

        _lit S_gc2_thread_scan_data_stack
        _lit S_gc2_thread_scan_return_stack
        _ bi

        next
endcode

; ; ### maybe_collect_handle
; code maybe_collect_handle, 'maybe_collect_handle', SYMBOL_INTERNAL
; ; untagged-handle --

;         _dup
;         mov     rbx, [rbx]              ; -- untagged-handle raw-object/0

;         ; check for null object address
;         test    rbx, rbx
;         jz      .1

;         ; is object marked?
;         _test_marked_bit
;         jz .2

;         ; object is marked
;         _nip                            ; -- object
;         _unmark_object
;         _return

; .2:                                     ; -- untagged-handle object
;         ; object is not marked
;         _ destroy_heap_object           ; -- untagged-handle
;         _ release_handle_unsafe
;         _return

; .1:
;         ; null object address, nothing to do
;         _2drop
;         next
; endcode

; ### gc2_maybe_collect_handle
code gc2_maybe_collect_handle, 'gc2_maybe_collect_handle' ; untagged-handle --

        _dup
        mov     rbx, [rbx]              ; -- untagged-handle ^object/0

        ; check for null object address
        test    rbx, rbx
        jz      .1

        ; is object unmarked?
;         _test_marked_bit
;         jz .2
        cmp     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_WHITE
        je      .2

        ; object is not white
        _nip                            ; -- object
        mov     byte [rbx + OBJECT_MARK_BYTE_OFFSET], MARK_WHITE
        _drop
        _return

.2:                                     ; -> untagged-handle object
        ; object is white
        _ destroy_heap_object           ; -> untagged-handle
        _ release_handle_unsafe
        _return

.1:
        ; null object address, nothing to do
        _2drop
        next
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

; asm_global collector_thread_, f_value

; ; ### collector_thread
; code collector_thread, 'collector_thread', SYMBOL_INTERNAL ; -- thread/f
;         pushrbx
;         mov     rbx, [collector_thread_]
;         next
; endcode

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

        _ gc2_collect
        _return

;         _debug_print "entering gc_collect"

;         cmp     qword [S_gc_inhibit_symbol_value], f_value
;         je .1
;         mov     qword [S_gc_pending_symbol_value], t_value
;         _return
; .1:
;         cmp     qword [S_gc_verbose_symbol_value], f_value
;         je .2
;         _ ticks
;         _to gc_start_ticks
;         _rdtsc
;         _to gc_start_cycles
; .2:
;         mov     qword [in_gc?_], t_value

;         _thread_count
;         cmp     rbx, 1
;         poprbx
;         jne     .3

;         _ current_thread_save_registers

;         _debug_print "marking single thread"

;         ; data stack
;         _ mark_datastack

;         ; return stack
;         _ mark_return_stack

;         jmp     .4

; .3:
;         _ lock_all_threads

;         _ stop_the_world

;         _ current_thread_save_registers

;         _debug_print "marking multiple threads"

;         _ all_threads
;         _lit S_mark_thread_stacks
;         _ vector_each

;         _ unlock_all_threads

; .4:
;         ; static symbols
;         _ mark_static_symbols

;         ; explicit roots
;         _ gc_roots
;         _lit S_maybe_mark_from_root
;         _ vector_each

;         ; sweep
;         _lit maybe_collect_handle
;         _ each_handle

;         _ start_the_world

;         inc     qword [gc_count_value]

;         mov     qword [in_gc?_], f_value

;         mov     qword [S_gc_pending_symbol_value], f_value

;         cmp     qword [S_gc_verbose_symbol_value], f_value
;         je .5

;         _rdtsc
;         _to gc_end_cycles
;         _ ticks
;         _to gc_end_ticks

;         _ ?nl
;         _write "gc "
;         _ recent_allocations
;         _ decimal_dot
;         _write " allocations since last gc"
;         _ nl

;         _ ?nl
;         _write "gc "
;         _ gc_end_ticks
;         _ gc_start_ticks
;         _minus
;         _tag_fixnum
;         _ decimal_dot
;         _write " ms "

;         _ gc_end_cycles
;         _ gc_start_cycles
;         _minus
;         _tag_fixnum
;         _ decimal_dot
;         _write " cycles"
;         _ nl

; .5:
;         _reset_recent_allocations

;         _debug_print "leaving gc_collect"

;         next
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

        _ gc2_work_list
        _ vector_raw_length
        mov     [gc2_work_list_max_], rbx
        _drop

.top:
        _ gc2_work_list

        _dup
        _ vector_raw_length
        cmp     [gc2_work_list_max_], rbx
        jge     .1
        mov     [gc2_work_list_max_], rbx
.1:
        _drop

        _ vector_?pop                   ; -> handle/nil
        cmp     rbx, f_value
        je      .normal_exit

        ; -> handle
        cmp     bl, HANDLE_TAG
        jne     .not_a_handle

;         _dup
;         _ object_raw_typecode
;         cmp     rbx, TYPECODE_STRING
;         poprbx
;         jne     .0
;         _debug_print "gc2_process_work_list string"
;         int3
; .0:

;         _handle_to_object_unsafe
;         test    rbx, rbx
;         jz      .1
;         _ mark_raw_object
        mov     rax, rbx                ; use rax as work register
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]              ; ^object in rax
        test    rax, rax                ; check for empty handle
        jz      .empty_handle
        cmp     byte [rax + OBJECT_MARK_BYTE_OFFSET], MARK_GRAY
        jne     .not_gray
        mov     byte [rax + OBJECT_MARK_BYTE_OFFSET], MARK_BLACK

;         _dup
;         _ mark_byte
;         _ hexdot
;         _ ?nl

        _ gc2_scan_handle               ; uses dispatch table

        jmp     .top

.normal_exit:
        _drop
        next

.not_a_handle:
        _error "not a handle"
        next

.empty_handle:
        _print "empty handle on work list"
        _drop
        next

.not_gray:
        movzx   rbx, byte [rax + OBJECT_MARK_BYTE_OFFSET]
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

        ; verify that all handles are white
        _lit gc2_assert_white
        _ each_handle

        ; data stack
        _ gc2_scan_data_stack

        ; return stack
        _ gc2_scan_return_stack

        jmp     .4

.3:
;         _debug_print "gc2 multiple threads, exiting..."
;         xcall   os_bye

        _ lock_all_threads

        _ stop_the_world

        _ current_thread_save_registers

        _debug_print "marking multiple threads"

        _ all_threads
;         _lit S_mark_thread_stacks
        _lit S_gc2_scan_thread_stacks
        _ vector_each

        _ unlock_all_threads

.4:
        ; static symbols
;         _ mark_static_symbols
        _ gc2_scan_static_symbols

        ; explicit roots
        _ gc_roots
;         _lit S_maybe_mark_from_root
;         _lit S_gc2_maybe_add_root
;         _ vector_each
        _lit gc2_visit_root
        _ unsafe_raw_code_address_vector_each

        ; work list is ready to go
        _ gc2_process_work_list

;         _debug_print "returning from gc2_collect"
;         _return

        ; sweep
        _debug_print "collecting handles"
        _lit gc2_maybe_collect_handle
        _ each_handle

;         _debug_print "returning from gc2_collect"
;         _return

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

; ### gc2
code gc2, 'gc2'

        _debug_print "entering gc2"

; %if 1
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
; %else
;         _ gc2_collect
; %endif
        _debug_print "leaving gc2"

        _write "gc2_work_list_max = "
        _ gc2_work_list_max
        _ dot_object

        next
endcode
