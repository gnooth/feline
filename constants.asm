; Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

inline zero, '0'
        pushrbx
        xor     ebx, ebx
endinline

inline one, '1'
        pushrbx
        mov     ebx, 1
endinline

inline two, '2'
        pushrbx
        mov     ebx, 2
endinline

inline three, '3'
        pushrbx
        mov     ebx, 3
endinline

code four, '4'
        pushrbx
        mov     ebx, 4
        next
endcode

code five, '5'
        pushrbx
        mov     ebx, 5
        next
endcode

code minusone, '-1'
        pushrbx
        mov     rbx, -1
        next
endcode

code false, 'false'
; CORE EXT
        pushrbx
        xor     ebx, ebx
        next
endcode

code true, 'true'
; CORE EXT
        pushrbx
        mov     rbx, -1
        next
endcode

code blchar, 'bl'
        pushrbx
        mov     ebx, ' '
        next
endcode

code cell, 'cell'
        pushrbx
        mov     rbx, BYTES_PER_CELL
        next
endcode
