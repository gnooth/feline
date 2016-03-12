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
