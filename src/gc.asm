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

; ### allocated-objects
value allocated_objects, 'allocated-objects', 0

; ### add-allocated-object
code add_allocated_object, 'add-allocated-object' ; object --
        _ allocated_objects
        _if .1
        _ allocated_objects
        _ vector_push
        _else .1
        _drop
        _then .1
        next
endcode

; ### remove-allocated-object
code remove_allocated_object, 'remove-allocated-object' ; object --
        _ allocated_objects
        _zeq_if .1
        _drop
        _return
        _then .1
                                        ; -- object
        _ allocated_objects
        _ vector_length
        _zero
        _?do .1
        _i
        _ allocated_objects
        _ vector_nth
        _over
        _equal
        _if .2
        _i
        _ allocated_objects
        _ vector_remove_nth
        _leave
        _then .2
        _loop .1

        _drop
        next
endcode

; ### explicit-roots
value explicit_roots, 'explicit-roots', 0 ; initialized in cold

; ### add-explicit-root
code add_explicit_root, 'add-explicit-root' ; address --
        _ explicit_roots
        _ check_vector
        _ vector_push
        next
endcode

; ### object-marked?
code object_marked?, 'object-marked?'   ; object -- flag
        _ check_object
        _ object_flags
        _lit MARKED
        _ and
        _zne                            ; REVIEW
        next
endcode

; ### mark-object
code mark_object, 'mark-object'         ; object --
        _ check_object
        _dup
        _object_flags                   ; -- object flags
        _lit MARKED
        _ or
        _object_set_flags
        next
endcode

; ### unmark-object
code unmark_object, 'unmark-object'     ; object --
        _ check_object
        _dup
        _object_flags                   ; -- object flags
        _lit MARKED
        _ invert
        _ and
        _object_set_flags
        next
endcode

; ### maybe-mark-object
code maybe_mark_object, 'maybe-mark-object' ; address --
        _dup
        _ object?
        _if .1
        _ mark_object
        _else .1
        _ drop
        _then .1
        next
endcode

; ### maybe-mark-from-root
code maybe_mark_from_root, 'maybe-mark-from-root' ; root --
        _fetch
        _ maybe_mark_object
        next
endcode

; ### gc-start-ticks
value gc_start_ticks, 'gc-start-ticks', 0

; ### gc
code gc, 'gc'                           ; --
        _ ticks
        _to gc_start_ticks

        ; unmark everything
        _ allocated_objects
        _ check_vector
        _lit unmark_object_xt
        _ vector_each

        ; data stack
        _ depth
        mov     rcx, rbx
        jrcxz   .2
.1:
        push    rcx
        pushd   rcx
        _pick
        _ maybe_mark_object
        pop     rcx
        loop    .1
.2:
        _drop

        ; TODO return stack

        ; TODO locals stack

        ; explicit roots
        _ explicit_roots
        _lit maybe_mark_from_root_xt
        _ vector_each

        ; sweep
        _ allocated_objects
        _ vector_length
        _begin .3
        _oneminus
        _dup
        _ zge
        _while .3
        _dup
        _ allocated_objects
        _ vector_nth                    ; -- index object
        _dup
        _ object_marked?
        _zeq_if .4                      ; -- index object
        _ destroy_object
        _else .4
        _drop
        _then .4
        _repeat .3
        _drop

        _ ticks
        _ gc_start_ticks
        _minus
        _ ?cr
        _ decdot
        _dotq "ms "

        next
endcode
