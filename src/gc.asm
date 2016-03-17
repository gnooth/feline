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

; ### remove-allocated-object
code remove_allocated_object, 'remove-allocated-object' ; object --
        _ find_handle
        _?dup_if .3
        _ release_handle
        _then .3
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
        _ check_allocated_object
        _dup
        _object_flags                   ; -- object flags
        _lit MARKED
        _ or
        _object_set_flags
        next
endcode

; ### mark-handle
code mark_handle, 'mark-handle'         ; handle --
        _ check_handle
        _ handle_to_object_unsafe
        _?dup_if .1
        _ mark_object
        _then .1
        next
endcode

; ### unmark-object
code unmark_object, 'unmark-object'     ; object --
        _ check_allocated_object
        _dup
        _object_flags                   ; -- object flags
        _lit MARKED
        _ invert
        _ and
        _object_set_flags
        next
endcode

; ### unmark-handle
code unmark_handle, 'unmark-handle'     ; handle --
        _ check_handle
        _ handle_to_object_unsafe
        _?dup_if .1
        _ unmark_object
        _then .1
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

; ### maybe-mark-object
code maybe_mark_object, 'maybe-mark-object' ; address --
        _dup
        _ allocated_object?
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
;         _ maybe_mark_object
        _ maybe_mark_handle
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
;         _ maybe_mark_object
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
        _ handle_to_object_unsafe       ; -- handle object|0
        _dup_if .1
        ; -- handle object
        _dup
        _ object_marked?
        _if .2
        _2drop
        _else .2
        _ destroy_object
        _zero
        _swap
        _store
        _then .2
        _else .1
        ; -- handle 0
        _2drop
        _then .1
        next
endcode

; ### in-gc?
value in_gc?, 'in-gc?', 0

; ### gc-start-ticks
value gc_start_ticks, 'gc-start-ticks', 0

; ### gc
code gc, 'gc'                           ; --
        _ ticks
        _to gc_start_ticks

        _true
        _to in_gc?

        ; unmark everything
;         _ allocated_objects
;         _ check_vector
;         _lit unmark_object_xt
;         _ vector_each
        _lit unmark_handle_xt
        _ each_handle

        ; data stack
        _ depth
        mov     rcx, rbx
        jrcxz   .2
.1:
        push    rcx
        pushd   rcx
        _pick
;         _ maybe_mark_object
        _ maybe_mark_handle
        pop     rcx
        loop    .1
.2:
        _drop

        ; return stack
        _ mark_return_stack

        ; locals stack
        _ mark_locals_stack

        ; explicit roots
        _ explicit_roots
        _lit maybe_mark_from_root_xt
        _ vector_each

        ; sweep
        _lit maybe_collect_handle_xt
        _ each_handle

        _zeroto in_gc?

        _ ticks
        _ gc_start_ticks
        _minus
        _ ?cr
        _ decdot
        _dotq "ms "

        next
endcode
