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

; ### handle-space
value handle_space, 'handle-space', 0

; ### handle-space-free
value handle_space_free, 'handle-space-free', 0

; ### handle-space-limit
value handle_space_limit, 'handle-space-limit', 0

%define HANDLE_SPACE_SIZE 1024*1024*8   ; 8 mb

; ### max-handles
constant max_handles, 'max-handles', HANDLE_SPACE_SIZE / BYTES_PER_CELL

; ### initialize-handle-space
code initialize_handle_space, 'initialize-handle-space' ; --
        _lit HANDLE_SPACE_SIZE
        _dup
        _ iallocate
        _dup
        _to handle_space
        _dup
        _to handle_space_free
        _plus
        _to handle_space_limit

        _lit 256
        _ new_vector
        _to free_handles

        next
endcode

; ### free-handles
value free_handles, 'free-handles', 0

; ### new-handle
code new_handle, 'new-handle'           ; object -- handle
        _from free_handles
        _?dup_if .1
        _handle_to_object_unsafe
        _vector_length
        _zgt
        _if .2
        _from free_handles
        _handle_to_object_unsafe
        _ vector_pop_unchecked          ; -- object handle
        _tuck
        _store
        _return
        _then .2
        _then .1

        _from handle_space_free
        _from handle_space_limit
        _ult
        _zeq_if .3
        _ gc
        _from handle_space_free
        _from handle_space_limit
        _ult
        _abortq "out of handle space"
        _then .3

        _from handle_space_free
        _store
        _from handle_space_free
        _dup
        _cellplus
        _to handle_space_free
        next
endcode

; ### handle?
code handle?, 'handle?'                 ; x -- flag
        ; must point into handle space
        cmp     rbx, [handle_space_data]
        jb .1
        cmp     rbx, [handle_space_free_data]
        jae .1

        ; must be aligned
        and     ebx, 7
        setz    bl
        _return
.1:
        xor     ebx, ebx
        next
endcode

; ### check-handle
code check_handle, 'check-handle'       ; handle -- handle
        _dup
        _ handle?
        _if .1
        _return
        _then .1
        _drop
        _true
        _abortq "not a handle"
        next
endcode

; ### to-object
code to_object, 'to-object'             ; handle -- object
        _ check_handle
        _fetch
        next
endcode

; ### find-handle
code find_handle, 'find-handle'         ; object -- handle | 0
        _ handle_space                  ; -- object addr
        _begin .2
        _dup
        _ handle_space_free
        _ult
        _while .2                       ; -- object addr
        _twodup                         ; -- object addr object handle
        _fetch                          ; -- object addr object object2
        _equal
        _if .3
        ; found it!
        _nip
        _return
        _then .3                        ; -- object addr

        _cellplus
        _repeat .2
        _drop                           ; -- object
        ; not found
        _ ?cr
        _dotq "can't find handle for object at "
        _ hdot
        ; return false
        _zero
        next
endcode

; ### release-handle-unsafe
code release_handle_unsafe, 'release-handle-unsafe' ; handle --
        ; Zero out the stored address.
        mov     qword [rbx], 0

        ; Add handle to free-handles vector.
        _from free_handles
        _ vector_push

        next
endcode

; ### #objects
value nobjects, '#objects',  0

; ### #free
value nfree, '#free', 0

; ### check-handle-space
code check_handle_space, 'check-handle-space'
        _zeroto nobjects
        _zeroto nfree

        _ handle_space
        _begin .1
        _dup
        _ handle_space_free
        _ult
        _while .1

;         _ ?cr
;         _dup
;         _ hdot

        _dup
        _fetch

;         _dup
;         _ hdot

        _?dup_if .2
        _lit 1
        _plusto nobjects

;         _ dot_object
        _drop

        _else .2
        _lit 1
        _plusto nfree
        _then .2
        _cellplus
        _repeat .1
        _drop

        _ ?cr
        _ handle_space_free
        _ handle_space
        _minus
        _ cell
        _ slash
        _ dot
        _dotq "handles "

        _ nobjects
        _ dot
        _dotq "objects "

        _ nfree
        _ dot
        _dotq "free"

        next
endcode

; ### .handles
code dot_handles, '.handles'
        _ ?cr
        _ handle_space_free
        _ handle_space
        _minus
        _ cell
        _ slash
        _ dot
        _dotq "handles"

        _ handle_space
        _begin .1
        _dup
        _ handle_space_free
        _ult
        _while .1
        _ ?cr
        _dup
        _ hdot
        _dup
        _fetch
        _dup
        _ hdot
        _if .2
        _dup
        _ dot_object
        _then .2
        _cellplus
        _repeat .1
        _drop
        next
endcode

; ### each-handle
code each_handle, 'each-handle'         ; xt --
        _tor
        _from handle_space              ; -- addr
        _begin .1
        _dup
        _from handle_space_free
        _ult
        _while .1                       ; -- addr
        _dup
        _rfetch
        _execute
        _cellplus
        _repeat .1
        _drop
        _rdrop
        next
endcode
