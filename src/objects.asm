; Copyright (C) 2015-2020 Peter Graves <gnooth@gmail.com>

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

; ### allocate-object
code allocate_object, 'allocate-object' ; size -- object
        _ raw_allocate
        next
endcode

; ### raw_allocate_cells
code raw_allocate_cells, 'raw_allocate_cells', SYMBOL_INTERNAL
; n -- address
; argument and return value are untagged
        _dup
        _cells                          ; -- cells bytes
        _ raw_allocate
        _swap                           ; -- address cells
        _dupd                           ; -- address address cells
        _ raw_erase_cells
        next
endcode

; ### object-address
code object_address, 'object-address'   ; x -> tagged-address
        cmp     bl, HANDLE_TAG
        jne     .1
        _handle_to_object_unsafe
        _tag_fixnum
        next

.1:
        ; not a handle
        _dup
        _ string?
        _tagged_if .2
;         _tag_fixnum
        _ string_address
        _return
        _then .2

        _dup
        _ symbol?
        _tagged_if .3
;         _tag_fixnum
        _ symbol_address
        _return
        _then .3

        ; apparently not an object
        mov     ebx, NIL

        next
endcode

; ### error-empty-handle
code error_empty_handle, 'error-empty-handle'
        _error "empty handle"
        next
endcode

; ### object_raw_typecode
code object_raw_typecode, 'object_raw_typecode', SYMBOL_INTERNAL ; x -> raw-typecode

        cmp     bl, HANDLE_TAG
        je      .3

        ; not a handle
        cmp     bl, STATIC_STRING_TAG
        je      .static_string

        cmp     bl, STATIC_SYMBOL_TAG
        je      .static_symbol

        test    ebx, LOWTAG_MASK
        jz      .4

        test    ebx, FIXNUM_TAG
        jz      .1
        mov     ebx, TYPECODE_FIXNUM
        next

.1:
        cmp     bl, CHAR_TAG
        jne     .2
        mov     ebx, TYPECODE_CHAR
        next

.2:
        mov     eax, ebx
        and     eax, BOOLEAN_TAG_MASK
        cmp     eax, BOOLEAN_TAG
        jne     .5
        mov     ebx, TYPECODE_BOOLEAN
        next

.3:
        _handle_to_object_unsafe
%ifdef DEBUG
        test    rbx, rbx
        jz      error_empty_handle
%endif
        _object_raw_typecode
        next

.static_string:
        mov     ebx, TYPECODE_STRING
        next

.static_symbol:
        mov     ebx, TYPECODE_SYMBOL
        next

.4:
        cmp     rbx, static_data_area
        jb      .5
        cmp     rbx, static_data_area_limit
        jae     .5
        _object_raw_typecode
        next

.5:
        ; not an object
        mov     ebx, TYPECODE_UNKNOWN
        next
endcode

; ### object-typecode
code object_typecode, 'object-typecode' ; x -> typecode
; return value is tagged
; error if x is not an object
        _ object_raw_typecode
        _tag_fixnum
        next
endcode

; ### type-of
code type_of, 'type-of'                 ; x -> type
        _ object_raw_typecode
        _ types
        _ vector_nth_untagged
        next
endcode

; ### object-layout
code object_layout, 'object-layout'     ; object -> layout
        _ type_of
        _ type_layout
        next
endcode

; ### .t
code dot_t, '.t'                        ; object -- object
        _lit tagged_fixnum(1)
        _ ?enough
        _dup
        _ type_of
        _ dot_object
        next
endcode

; ### destroy_heap_object
code destroy_heap_object, 'destroy_heap_object', SYMBOL_INTERNAL ; ^object -> void

; The argument is known to be the raw address of a valid heap object, not a
; handle or null. Called only by gc2_maybe_collect_handle during gc.

        _object_raw_typecode_eax

        cmp     eax, TYPECODE_SBUF
        je      destroy_sbuf
        cmp     eax, TYPECODE_VECTOR
        je      destroy_vector_unchecked
        cmp     eax, TYPECODE_HASHTABLE
        je      destroy_hashtable_unchecked
        cmp     eax, TYPECODE_FIXNUM_HASHTABLE
        je      destroy_fixnum_hashtable
        cmp     eax, TYPECODE_QUOTATION
        je      destroy_quotation_unchecked
        cmp     eax, TYPECODE_THREAD
        je      destroy_thread
        cmp     eax, TYPECODE_MUTEX
        je      destroy_mutex

        ; Default behavior for objects with only one allocation.

        ; Zero out the object header so it won't look like a valid object
        ; after it has been freed.
        mov     qword [rbx], 0

        _feline_free

        next
endcode

; ### slot@
code slot@, 'slot@'                     ; obj tagged-fixnum -> value
;         _check_fixnum
;         mov     rax, rbx
;         _drop
;         cmp     bl, HANDLE_TAG
;         jne     .1
;         shr     rbx, HANDLE_TAG_BITS
;         mov     rbx, [rbx]
; .1:
;         mov     rbx, [rbx + rax * BYTES_PER_CELL]
        _swap
        _ object_address
        _check_fixnum
        push    rbx
        _drop
        _check_fixnum
        pop     rax
        mov     rbx, [rax + rbx * BYTES_PER_CELL]
        next
endcode

; ### tuple-slot1@
inline tuple_slot1@, 'tuple-slot1@'     ; obj -- value
        _handle_to_object_unsafe
        mov     rbx, [rbx + BYTES_PER_CELL]
endinline

; ### tuple-slot2@
inline tuple_slot2@, 'tuple-slot2@'     ; obj -- value
        _handle_to_object_unsafe
        mov     rbx, [rbx + BYTES_PER_CELL * 2]
endinline

; ### tuple-slot3@
inline tuple_slot3@, 'tuple-slot3@'     ; obj -- value
        _handle_to_object_unsafe
        mov     rbx, [rbx + BYTES_PER_CELL * 3]
endinline

; ### slot!
code set_slot, 'slot!'                  ; value obj tagged-fixnum --
        _untag_fixnum
        _cells
        _swap
        _handle_to_object_unsafe
        _plus
        _store
        next
endcode

; ### verify-typecode
code verify_typecode, 'verify-typecode' ; object typecode -- object

        _twodup

        _over
        _ object_typecode
        cmp     rbx, [rbp]
        jne     .1
        _4drop
        _return
.1:
        _2drop
        _ type_of
        _ type_name
        _swap
        _ typecode_to_type
        _ type_name
        _swap
        _quote "TYPE ERROR: expected a %s, got a %s."
        _ format
        _ error
        next
endcode

; ### object->string/default
code object_to_string_default, 'object->string/default' ; object -> string
        _dup
        _ tuple_instance?
        _tagged_if .1
        _ tuple_to_string
        _else .1
        _ raw_uint64_to_hex
        _quote "0x"
        _swap
        _ string_append
        _then .1
        next
endcode

; ### .
code dot_object, '.'                    ; handle-or-object --
        _ object_to_string
        _ write_string
        _ nl
        next
endcode

; ### object>short-string
code object_to_short_string, 'object>short-string' ; x -> string
        _ object_to_string
        _dup
        _ string_length
        _lit tagged_fixnum(40)
        _ fixnum_fixnum_gt
        _tagged_if .1
        _lit tagged_fixnum(40)
        _swap
        _ string_head
        _quote '...'
        _ string_append
        _then .1
        next
endcode

; ### short.
code short_dot, 'short.'                ; handle-or-object --
        _ object_to_short_string
        _ write_string
        _ nl
        next
endcode

; ### fixnum-tag-bits
code fixnum_tag_bits, 'fixnum-tag-bits'
        _lit FIXNUM_TAG_BITS
        _tag_fixnum
        next
endcode

; ### tag-fixnum
code tag_fixnum, 'tag-fixnum'           ; untagged -> fixnum
        _tag_fixnum
        next
endcode

; ### untag-fixnum
code untag_fixnum, 'untag-fixnum'       ; fixnum -> untagged
        _untag_fixnum
        next
endcode

; ### object>uint64
code object_to_uint64, 'object>uint64'  ; object -- uint64
        _ new_uint64
        next
endcode
