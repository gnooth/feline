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
code object?, 'object?'                 ; x -- flag
        _dup
        _ handle?
        _if .0
        _handle_to_object_unsafe
        _zne
        _return
        _then .0

        ; Not allocated. Must be a string or not an object.
        _ string?
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

        ; REVIEW
        _true
        _abortq "unknown object"
        next
endcode

; ### .object
code dot_object, '.object'              ; handle-or-object --
        _dup
        _ string?
        _if .1
        _lit '"'
        _ emit
        _ dot_string
        _lit '"'
        _ emit
        _ space
        _return
        _then .1

        _dup
        _ sbuf?
        _if .2
        _dotq 'SBUF" '
        _ sbuf_from
        _ type
        _dotq '" '
        _return
        _then .2

        _dup
        _ vector?
        _if .3
        _ dot_vector
        _ space
        _return
        _then .3

        ; give up
        _ hdot

        next
endcode

; ### most-positive-fixnum
code most_positive_fixnum, 'most-positive-fixnum'
        _lit 1
        _lit 63 - TAG_BITS
        _ lshift
        _oneminus
        next
endcode

; ### most-negative-fixnum
code most_negative_fixnum, 'most-negative-fixnum'
        _lit 1
        _lit 63 - TAG_BITS
        _ lshift
        next
endcode

; ### tag-bits
code tag_bits, 'tag-bits'
        _lit TAG_BITS
        _make_fixnum
        next
endcode

%ifdef USE_TAGS

; ### fixnum?
code fixnum?, 'fixnum?'                 ; x -- flag
        _fixnum?
        next
endcode

; ### print
code generic_dot, '.'                   ; x --
        _dup
        _fixnum?
        _if .1
        _fixnum_to_int
        _then .1
        _ dot
        next
endcode

code generic_add, '+'                   ; n1 n2 -- n1+n2
        _dup
        _fixnum?
        _if .1
        _fixnum_to_int
        _then .1
        _swap
        _dup
        _fixnum?
        _if .2
        _fixnum_to_int
        _then .2
        _plus
        _make_fixnum
        next
endcode

code generic_subtract, '-'              ; n1 n2 -- n1-n2
        _dup
        _fixnum?
        _if .1
        _fixnum_to_int
        _then .1
        _swap
        _dup
        _fixnum?
        _if .2
        _fixnum_to_int
        _then .2
        sub     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _make_fixnum
        next
endcode

code generic_multiply, '*'              ; n1 n2 -- n1*n2
        _dup
        _fixnum?
        _if .1
        _fixnum_to_int
        _then .1
        _swap
        _dup
        _fixnum?
        _if .2
        _fixnum_to_int
        _then .2
        imul     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        _make_fixnum
        next
endcode

%endif
