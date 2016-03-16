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
        next
endcode

; ### new-handle
code new_handle, 'new-handle'           ; object -- handle
        _ handle_space_free
        _ handle_space_limit
        _ult
        _zeq
        _abortq "out of handle space"

        _ handle_space_free
        _store
        _ handle_space_free
        _dup
        _cellplus
        _to handle_space_free
        next
endcode

; ### handle?
code handle?, 'handle?'                 ; x -- flag
        ; must be aligned
        _dup
        _lit 7
        _ and
        _if .1
        xor     ebx, ebx
        _return
        _then .1

        ; must point into handle space
        _ handle_space
        _ handle_space_free
        _ within
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
        _dup
        _ allocated_object?
        _zeq_if .1
        xor     ebx, ebx
        _return
        _then .1                        ; -- object

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

; ### release-handle
code release_handle, 'release-handle'   ; -- handle
        _ check_handle
        _zero
        _swap
        _store
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
        _ dup
        _ hdot
        _?dup_if .2
        _ dot_object
        _then .2
        _cellplus
        _repeat .1
        _drop
        next
endcode
