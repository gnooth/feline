; Copyright (C) 2017-2020 Peter Graves <gnooth@gmail.com>

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

; ### boolean?
code boolean?, 'boolean?'               ; x -> ?
        cmp     rbx, NIL
        je      .yes
        cmp     rbx, TRUE
        je      .yes
        mov     ebx, NIL
        next
.yes:
        mov     ebx, TRUE
        next
endcode

; ### boolean-equal?
code boolean_equal?, 'boolean-equal?'   ; x y -> ?
        cmp     rbx, NIL
        je      .1
        cmp     rbx, TRUE
        jne     .no
.1:
        cmp     rbx, [rbp]
        jne     .no
        _nip
        mov     ebx, TRUE
        next
.no:
        _nip
        mov     ebx, NIL
        next
endcode

; ### >boolean
code to_boolean, '>boolean'             ; x -> ?
        mov     eax, TRUE
        cmp     rbx, NIL
        cmovne  ebx, eax
        next
endcode

; ### boolean->string
code boolean_to_string, 'boolean->string'       ; boolean -> string
        cmp     rbx, NIL
        jne     .1
        _drop
        _quote "nil"
        next
.1:
        cmp     rbx, TRUE
        jne     error_not_boolean
        _drop
        _quote "true"
        next
endcode
