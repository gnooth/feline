; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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

; ### base
; CORE
variable base, 'base', 10

; ### base@
code basefetch, 'base@'                 ; -- n
        pushrbx
        mov     rbx, [base_data]
        next
endcode

; ### base!
code basestore, 'base!'                 ; n --
        mov     [base_data], rbx
        poprbx
        next
endcode

; ### binary
code binary, 'binary'
        mov     qword [base_data], 2
        next
endcode

; ### decimal
code decimal, 'decimal'
; CORE
        mov     qword [base_data], 10
        next
endcode

; ### hex
code hex, 'hex'
; CORE EXT
        mov     qword [base_data], 16
        next
endcode
