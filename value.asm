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

section .text
dovalue:
        pushrbx
        db      $48                     ; mov rbx, 0
        db      $0bb
dovalue_patch:
        dq      0                       ; 64-bit immediate value (to be patched)
        mov     rbx, [rbx]
dovalue_end:

code value, 'value'                     ; x "<spaces>name" --
; CORE EXT
        _ header
        _ align_data
        _ here_c
        _ latest
        _ namefrom
        _ store
        _lit dovalue
        _lit dovalue_end - dovalue
        _ paren_copy_code
        _ here                          ; -- addr
        _ here_c
        _lit dovalue_end - dovalue_patch
        _ minus
        _ store
        _lit $0c3
        _ ccommac
        _ comma
        next
endcode

code storeto, 'to', IMMEDIATE
        _ tick
        _ tobody
        _ state
        _ fetch
        _if storeto1
        _lit lit
        _ commacall
        _ commac
        _lit store
        _ commacall
        _else storeto1
        _ store
        _then storeto1
        next
endcode

code plusstoreto, '+to', IMMEDIATE      ; n "<spaces>name" --
        _ tick
        _ tobody
        _ state
        _ fetch
        _if plusstoreto1
        _lit lit
        _ commacall
        _ commac
        _lit plusstore
        _ commacall
        _else plusstoreto1                  ; -- n addr
        _ plusstore
        _then plusstoreto1
        next
endcode
