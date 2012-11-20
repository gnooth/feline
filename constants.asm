; Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

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

code zero, '0'
        pushrbx
        xor     ebx, ebx
        next
endcode

code one, '1'
        pushrbx
        mov     ebx, 1
        next
endcode

code two, '2'
        pushrbx
        mov     ebx, 2
        next
endcode

code three, '3'
        pushrbx
        mov     ebx, 3
        next
endcode

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
        pushrbx
        xor     ebx, ebx
        next
endcode

code true, 'true'
        pushrbx
        mov     rbx, -1
        next
endcode

code blchar, 'bl'
        pushrbx
        mov     ebx, ' '
        next
endcode
