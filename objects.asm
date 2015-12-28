; Copyright (C) 2015 Peter Graves <gnooth@gmail.com>

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

; ### slot 0
; returns contents of slot0
; slot 0 is the object header
inline slot0, 'slot0'                   ; object-addr -- x
        _fetch
endinline

; ### object-header
inline object_header, 'object-header'   ; object -- x
        _fetch
endinline

; ### object-header!
code set_object_header, 'object-header!' ; x object --
        _ store
        next
endcode

; ### slot1
; returns contents of slot1
inline slot1, 'slot1'                   ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL]
endinline

code set_slot1, 'slot1!'                ; x object --
        add     rbx, BYTES_PER_CELL
        _ store
        next
endcode

; ### slot2
; returns contents of slot1
inline slot2, 'slot2'                   ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 2]
endinline

; ### slot2!
code set_slot2, 'slot2!'                ; x object --
        add     rbx, BYTES_PER_CELL * 2
        _ store
        next
endcode

; ### slot3
; returns contents of slot1
inline slot3, 'slot3'                   ; object -- x
        mov     rbx, [rbx + BYTES_PER_CELL * 3]
endinline

; ### slot3!
code set_slot3, 'slot3!'                ; x object --
        add     rbx, BYTES_PER_CELL * 3
        _ store
        next
endcode

; Object types

VECTOR_TYPE     equ $7fa7
STRING_TYPE     equ $4d81

; Vectors

; ### vector-length
code vector_length, 'vector-length'     ; vector -- length
        _ slot1
        next
endcode

; ### vector-length!
code set_vector_length, 'vector-length!' ; length vector --
        _ set_slot1
        next
endcode

; ### vector-data
code vector_data, 'vector-data'         ; vector -- data-address
        _ slot2
        next
endcode

; ### vector-data!
code set_vector_data, 'vector-data!'    ; data-address vector --
        _ set_slot2
        next
endcode

; ### vector-capacity
code vector_capacity, 'vector-capacity' ; vector -- capacity
        _ slot3
        next
endcode

; ### vector-capacity!
code set_vector_capacity, 'vector-capacity!' ; capacity vector --
        _ set_slot3
        next
endcode

; ### <vector>
code construct_vector, '<vector>'       ; capacity -- vector
        _lit 4
        _cells
        _ iallocate
        _duptor                         ; -- capacity vector            r: -- vector
        _lit 4
        _cells
        _ erase
        _lit VECTOR_TYPE
        _rfetch                         ; -- capacity vector            r: -- vector
        _ set_object_header             ; -- capacity                   r: -- vector
        _dup                            ; -- capacity capacity          r: -- vector
        _cells
        _ iallocate                     ; -- capacity data-address              r: -- vector
        _rfetch                         ; -- capacity data-address vector       r: -- vector
        _ set_vector_data               ; -- capacity                   r: -- vector
        _rfrom                          ; -- capacity vector
        _ tuck                          ; -- vector capacity vector
        _ set_vector_capacity           ; -- vector
        next
endcode
