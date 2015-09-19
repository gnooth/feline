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

file __FILE__

; ### false
code false, 'false'
; CORE EXT
        pushrbx
        xor     ebx, ebx
        next
endcode

; ### true
code true, 'true'
; CORE EXT
        pushrbx
        mov     rbx, -1
        next
endcode

; ### bl
code blchar, 'bl'
; CORE
        pushrbx
        mov     ebx, ' '
        next
endcode

; ### cell
code cell, 'cell'
        pushrbx
        mov     rbx, BYTES_PER_CELL
        next
endcode

; ### /hold
code holdbufsize, '/hold'
; "size of the pictured numeric output string buffer, in characters"
        pushrbx
        mov     rbx, 128
        next
endcode

; ### /pad
code padsize, '/pad'
; "size of the scratch area pointed to by PAD, in characters"
        pushrbx
        mov     rbx, 1024
        next
endcode

; ### linux?
code linux?, 'linux?'
        pushrbx
%ifdef WIN64
        xor     ebx, ebx
%else
        mov     rbx, -1
%endif
        next
endcode

; ### windows?
code windows?, 'windows?'
        pushrbx
%ifdef WIN64
        mov     rbx, -1
%else
        xor     ebx, ebx
%endif
        next
endcode
