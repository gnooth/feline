; Copyright (C) 2015-2017 Peter Graves <gnooth@gmail.com>

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
        _ iallocate
        next
endcode

; ### allocate_cells
subroutine allocate_cells               ; n -- address
; Argument and return value are untagged.
        _cells
        _dup
        _ feline_allocate_untagged      ; -- bytes address
        _swap                           ; -- address bytes
        _dupd                           ; -- address address bytes
        _ erase                         ; -- address
        ret
endsub

; ### object?
code object?, 'object?'                 ; x -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe
        _zne
        _tag_boolean
        _return
        _then .1

        ; Not allocated. Must be a string or not an object.
        _ string?
        next
endcode

; ### object-address
code object_address, 'object-address'   ; handle -- tagged-address
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe
        _tag_fixnum
        _return
        _then .1

        ; not allocated
        _dup
        _ string?
        _tagged_if .2
        _tag_fixnum
        _return
        _then .2

        _dup
        _ symbol?
        _tagged_if .3
        _tag_fixnum
        _return
        _then .3

        ; apparently not an object
        mov     ebx, f_value

        next
endcode

; ### error-empty-handle
code error_empty_handle, 'error-empty-handle'
        _error "empty handle"
        next
endcode

; ### object-type
code object_type, 'object-type'         ; handle-or-object -- n/f
; Return value is tagged.
        _dup
        _fixnum?
        _if .1
        mov     ebx, OBJECT_TYPE_FIXNUM
        _tag_fixnum
        _return
        _then .1

        _dup
        _f
        _eq?
        _tagged_if .2
        mov     ebx, OBJECT_TYPE_F
        _tag_fixnum
        _return
        _then .2

        _dup
        _ handle?
        _tagged_if .3
        _handle_to_object_unsafe
        test    rbx, rbx
        jz error_empty_handle
        _object_type
        _tag_fixnum
        _return
        _then .3

        ; Not allocated. Is it a static string or symbol?
        _dup
        _ string?
        _tagged_if .4
        mov     ebx, OBJECT_TYPE_STRING
        _tag_fixnum
        _return
        _then .4

        _dup
        _ symbol?
        _tagged_if .5
        mov     ebx, OBJECT_TYPE_SYMBOL
        _tag_fixnum
        _return
        _then .5

        ; Apparently not an object.
        mov     ebx, f_value

        next
endcode

; ### type?
code type?, 'type?'                     ; x type-number -- ?
        _swap
        _ deref                         ; -- type-number object-address/0
        _?dup_if .1
        _object_type
        _eq?
        _return
        _then .1

        mov     ebx, f_value
        next
endcode

; ### destroy_object_unchecked
subroutine destroy_object_unchecked     ; object --
; The argument is known to be the address of a valid heap object, not a
; handle or null. Called only by maybe-collect-handle during gc.
        _dup

        ; Macro is OK here since we have a valid object address.
        _string?

        _if .1
        _ destroy_string_unchecked
        _return
        _then .1

        _dup
        _sbuf?
        _if .2
        _ destroy_sbuf_unchecked
        _return
        _then .2

        _dup
        _vector?
        _if .3
        _ destroy_vector_unchecked
        _return
        _then .3

        _dup
        _array?
        _if .4
        _ destroy_array_unchecked
        _return
        _then .4

        _dup
        _hashtable?
        _if .5
        _ destroy_hashtable_unchecked
        _return
        _then .5

        _dup
        _quotation?
        _if .6
        _ destroy_quotation_unchecked
        _return
        _then .6

        _dup
        _curry?
        _if .7
        _ destroy_curry_unchecked
        _return
        _then .7

        _dup
        _bignum?
        _if .8
        _ destroy_bignum_unchecked
        _return
        _then .8

        ; Default behavior for objects with only one allocation.

        ; Zero out the object header so it won't look like a valid object
        ; after it has been freed.
        xor     eax, eax
        mov     [rbx], rax

        _ ifree

        ret
endsub

; ### slot
code slot, 'slot'                       ; obj tagged-fixnum -- value
        _untag_fixnum
        _cells
        _swap
        _handle_to_object_unsafe
        _plus
        _fetch
        next
endcode

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

; ### .
code dot_object, '.'                    ; handle-or-object --
        _dup
        _f
        _equal
        _if .1a
        _drop
        _write_char 'f'
        _return
        _then .1a

        _dup
        _t
        _equal
        _if .1b
        _drop
        _write_char 't'
        _return
        _then .1b

        _dup
        _ string?
        _tagged_if .2
        _tagged_char '"'
        _ write_char
        _ write_string
        _tagged_char '"'
        _ write_char
        _return
        _then .2

        _dup
        _ sbuf?
        _tagged_if .3
        _write 'SBUF" '
        _ write_sbuf
        _write '" '
        _return
        _then .3

        _dup
        _ vector?
        _tagged_if .4
        _ dot_vector
        _return
        _then .4

        _dup
        _ array?
        _tagged_if .5
        _ dot_array
        _return
        _then .5

        _dup
        _fixnum?
        _if .6
        _ fixnum_to_string
        _ write_string
        _return
        _then .6

        _dup
        _ hashtable?
        _tagged_if .7
        _ dot_hashtable
        _return
        _then .7

        _dup
        _ bignum?
        _tagged_if .8
        _ bignum_to_string
        _ write_string
        _return
        _then .8

        _dup
        _ symbol?
        _tagged_if .9
        _ symbol_name
        _ write_string
        _return
        _then .9

        _dup
        _ vocab?
        _tagged_if .10
        _drop
        _write "~vocab~"
        _return
        _then .10

        _dup
        _ quotation?
        _tagged_if .11
        _ dot_quotation
        _return
        _then .11

        _dup
        _ wrapper?
        _tagged_if .12
        _write "' "
        _ wrapped
        _ dot_object
        _return
        _then .12

        _dup
        _ tuple?
        _tagged_if .13
        _ dot_tuple
        _return
        _then .13

        _dup
        _ curry?
        _tagged_if .14
        _ dot_curry
        _return
        _then .14

        _dup
        _ slice?
        _tagged_if .15
        _ dot_slice
        _return
        _then .15

        _dup
        _ range?
        _tagged_if .16
        _ dot_range
        _return
        _then .16

        _dup
        _ lexer?
        _tagged_if .17
        _ dot_lexer
        _return
        _then .17

        ; give up
        _tag_fixnum
        _ hexdot

        next
endcode

; ### tag-bits
code tag_bits, 'tag-bits'
        _lit TAG_BITS
        _tag_fixnum
        next
endcode

; ### tag-fixnum
code tag_fixnum, 'tag-fixnum'           ; n -- tagged
        _tag_fixnum
        next
endcode

; ### untag-fixnum
code untag_fixnum, 'untag-fixnum'       ; tagged -- n
        _untag_fixnum
        next
endcode

; ### tag-char
code tag_char, 'tag-char'               ; char -- tagged
        _tag_char
        next
endcode

; ### untag-char
code untag_char, 'untag-char'           ; tagged -- char
        _untag_char
        next
endcode

; ### tag-boolean
code tag_boolean, 'tag-boolean'         ; -1|0 -- t|f
        _tag_boolean
        next
endcode

; ### untag-boolean
code untag_boolean, 'untag-boolean'     ; t|f -- 1|0
        _untag_boolean
        next
endcode

; ### tag
code tag, 'tag'                         ; object -- tag
        _tag
        _tag_fixnum
        next
endcode
