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
        _dup
        _lit 7
        _ and
        _if .1
        xor     ebx, ebx
        _return
        _then .1

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
