; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

; ### release-handle-for-object
code release_handle_for_object, 'release-handle-for-object' ; object --
        _ find_handle
        _?dup_if .1
        _ release_handle_unsafe
        _then .1
        next
endcode

; ### gc-roots
value gc_roots, 'gc-roots', 0           ; initialized in cold

; ### gc-add-root
code gc_add_root, 'gc-add-root'         ; address --
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
        _vector_length
        _zero
        _?do .1
        _i
        _this
        _vector_nth_unsafe              ; -- element
        _ maybe_mark_handle
        _loop .1                        ; --
        pop     this_register
        next
endcode

; ### mark-array
code mark_array, 'mark-array'           ; array --
        push    this_register
        mov     this_register, rbx
        _array_length
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
        _hashtable_capacity             ; -- capacity
        _zero
        _?do .1
        _i
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
        _symbol_value
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

; ### mark-lexer
code mark_lexer, 'mark-lexer'           ; lexer --
        _lexer_string
        _ maybe_mark_handle
        next
endcode

; ### mark-handle
code mark_handle, 'mark-handle'         ; handle --
        _handle_to_object_unsafe        ; -- object/0
        test    rbx, rbx
        jz .1

        _test_marked_bit
        jnz .1

        _set_marked_bit

        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_VECTOR
        _equal
        _if .2
        _ mark_vector
        _return
        _then .2

        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_ARRAY
        _equal
        _if .3
        _ mark_array
        _return
        _then .3

        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_HASHTABLE
        _equal
        _if .4
        _ mark_hashtable
        _return
        _then .4

        _dup
        _object_type
        _lit OBJECT_TYPE_VOCAB
        _equal
        _if .5
        _ mark_vocab
        _return
        _then .5

        _dup
        _object_type
        _lit OBJECT_TYPE_SYMBOL
        _equal
        _if .6
        _ mark_symbol
        _return
        _then .6

        _dup
        _object_type
        _lit OBJECT_TYPE_QUOTATION
        _equal
        _if .7
        _ mark_quotation
        _return
        _then .7

        _dup
        _object_type
        _lit OBJECT_TYPE_CURRY
        _equal
        _if .8
        _ mark_curry
        _return
        _then .8

        _dup
        _object_type
        _lit OBJECT_TYPE_SLICE
        _equal
        _if .9
        _ mark_slice
        _return
        _then .9

        _dup
        _object_type
        _lit OBJECT_TYPE_TUPLE
        _equal
        _if .10
        _ mark_tuple
        _return
        _then .10

        _dup
        _object_type
        _lit OBJECT_TYPE_LEXER
        _equal
        _if .11
        _ mark_lexer
        _return
        _then .11

.1:
        _drop
        next
endcode

; ### maybe-mark-handle
code maybe_mark_handle, 'maybe-mark-handle' ; handle --
        _dup
        _ handle?
        _if .1
        _ mark_handle
        _else .1
        _drop
        _then .1
        next
endcode

; ### maybe-mark-from-root
code maybe_mark_from_root, 'maybe-mark-from-root' ; root --
        _fetch
        _ maybe_mark_handle
        next
endcode

; ### mark-data-stack
code mark_data_stack, 'mark-data-stack' ; --
        _ depth
        mov     rcx, rbx
        jrcxz   .2
.1:
        push    rcx
        pushd   rcx
        _forth_pick
        _ maybe_mark_handle
        pop     rcx
        loop    .1
.2:
        _drop
        next
endcode

; ### mark-return-stack
code mark_return_stack, 'mark-return-stack' ; --
        _ rdepth
        mov     rcx, rbx                ; depth in rcx
        jrcxz   .2
.1:
        mov     rax, rcx
        shl     rax, 3
        add     rax, rsp
        pushrbx
        mov     rbx, [rax]
        push    rcx
        _ maybe_mark_handle
        pop     rcx
        dec     rcx
        jnz     .1
.2:
        poprbx
        next
endcode

; ### mark-locals-stack
code mark_locals_stack, 'mark-locals-stack' ; --
        _ lpfetch
        _begin .3
        _dup
        _ lp0
        _ult
        _while .3
        _dup
        _ maybe_mark_from_root
        _cellplus
        _repeat .3
        _drop
        next
endcode

; ### maybe-collect-handle
code maybe_collect_handle, 'maybe-collect-handle' ; handle --
        _dup                            ; -- handle handle
        _handle_to_object_unsafe        ; -- handle object|0
        ; Check for null object address.
        test    rbx, rbx
        jnz     .1
        ; Null object address, nothing to do.
        _2drop
        _return
.1:                                     ; -- handle object
        ; Is object marked?
        _test_marked_bit
        jz .2
        ; Object is marked.
        _nip                            ; -- object
        _unmark_object
        _return
.2:                                     ; -- handle object
        ; Object is not marked.
        _ destroy_object_unchecked      ; -- handle
        _ release_handle_unsafe
        next
endcode

; ### in-gc?
value in_gc?, 'in-gc?', 0

; ### gc-start-ticks
value gc_start_ticks, 'gc-start-ticks', 0

; ### gc-end-ticks
value gc_end_ticks, 'gc-end-ticks', 0

; ### gc-start-cycles
value gc_start_cycles, 'gc-start-cycles', 0

; ### gc-end-cycles
value gc_end_cycles, 'gc-end-cycles', 0

_global gc_verbose, f_value

; gc-verbose!
code set_gc_verbose, 'gc-verbose!'      ; ? --
        mov     [gc_verbose], rbx
        poprbx
        next
endcode

; ### gc
code gc, 'gc'                           ; --
        cmp     qword [gc_verbose], f_value
        je .1
        _ ticks
        _to gc_start_ticks
        _rdtsc
        _to gc_start_cycles
.1:
        _true
        _to in_gc?

        ; data stack
        _ mark_data_stack

        ; return stack
        _ mark_return_stack

        ; locals stack
        _ mark_locals_stack

        ; explicit roots
        _ gc_roots
        _lit maybe_mark_from_root_xt
        _ vector_each

        ; sweep
        _lit maybe_collect_handle_xt
        _ each_handle

        _zeroto in_gc?

        cmp     qword [gc_verbose], f_value
        je .2
        _rdtsc
        _to gc_end_cycles
        _ ticks
        _to gc_end_ticks

        _ ?nl
        _quote "gc "
        _ write_string
        _ gc_end_ticks
        _ gc_start_ticks
        _minus
        _tag_fixnum
        _ dot_object
        _quote "ms "
        _ write_string

        _ gc_end_cycles
        _ gc_start_cycles
        _minus
        _tag_fixnum
        _ dot_object
        _quote "cycles"
        _ write_string
        _ nl

.2:
        next
endcode
