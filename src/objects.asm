; Copyright (C) 2015-2016 Peter Graves <gnooth@gmail.com>

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

; ### object?
code object?, 'object?'                 ; x -- t|f
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe
        _zne
        _tag_boolean
        _return
        _then .1

        ; Not allocated. Must be a string or not an object.
        _ string?
        next
endcode

; ### vector
constant vector, 'vector', tagged_fixnum(OBJECT_TYPE_VECTOR)

; ### string
constant string, 'string', tagged_fixnum(OBJECT_TYPE_STRING)

; ### sbuf
constant sbuf, 'sbuf', tagged_fixnum(OBJECT_TYPE_SBUF)

; ### array
constant array, 'array', tagged_fixnum(OBJECT_TYPE_ARRAY)

; ### object-type
code object_type, 'object-type'         ; handle-or-object -- tagged-type-number
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe
        _object_type
        _tag_fixnum
        _return
        _then .1

        ; Not allocated. Must be a string or not an object.
        _ check_string                  ; -- string
        _object_type
        _tag_fixnum
        next
endcode

; ### ~object-unchecked
code destroy_object_unchecked, '~object-unchecked' ; object --
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

        ; REVIEW
        _true
        _abortq "unknown object"
        next
endcode

; ### .object
code dot_object, '.object'              ; handle-or-object --
        _dup
        _f
        _equal
        _if .1a
        _drop
        _lit 'f'
        _ emit
        _ space
        _return
        _then .1a

        _dup
        _t
        _equal
        _if .1b
        _drop
        _lit 't'
        _ emit
        _ space
        _return
        _then .1b

        _dup
        _ string?
        _tagged_if .2
        _lit '"'
        _ emit
        _ dot_string
        _lit '"'
        _ emit
        _ space
        _return
        _then .2

        _dup
        _ sbuf?
        _tagged_if .3
        _dotq 'SBUF" '
        _ sbuf_from
        _ type
        _dotq '" '
        _return
        _then .3

        _dup
        _ vector?
        _tagged_if .4
        _ dot_vector
        _ space
        _return
        _then .4

        _dup
        _ array?
        _tagged_if .5
        _ dot_array
        _ space
        _return
        _then .5

        _dup
        _fixnum?
        _if .6
        _untag_fixnum
        _ decdot
        _return
        _then .6

        _dup
        _ hashtable?
        _tagged_if .7
        _drop
        _dotq "H{ } "
        _return
        _then .7

        _dup
        _ bignum?
        _tagged_if .8
        _ bignum_to_string
        _ dot_string
        _return
        _then .8

        ; give up
        _ hdot

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

; ### .
code generic_dot, '.'                   ; x --
        _dup
        _f
        _equal
        _if .1
        _drop
        _lit 'f'
        _ emit
        _return
        _then .1

        _dup
        _t
        _equal
        _if .2
        _drop
        _lit 't'
        _ emit
        _return
        _then .2

        _dup
        _fixnum?
        _if .3
        _dotq "fixnum "
        _untag_fixnum
        _ dot
        _return
        _then .3

        _dup
        _ bignum?
        _tagged_if .4
        _dotq "bignum "
        _ bignum_to_string
        _ dot_string
        _return
        _then .4

        _dotq "untagged "
        _ hdot
        next
endcode
