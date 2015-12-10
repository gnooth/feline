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

; ### @
inline fetch, '@'
        _fetch
endinline

; ### @+
; iForth
;
code fetchplus, '@+'                    ; a-addr1 -- a-addr2 x
; iForth
; fetch x from a-addr1
; a-addr2 = a-addr1 + BYTES_PER_CELL
        pushrbx
        add     qword [rbp], BYTES_PER_CELL
        mov     rbx, [rbx]
        next
endcode

; ### c@
inline cfetch, 'c@'
        _cfetch
endinline

; ### c@s
inline cfetchs, 'c@s'                   ; c-addr -- n
        movsx   rbx, byte [rbx]         ; n is the sign-extended 8-bit value stored at c_addr
endinline

; ### l@
inline lfetch, 'l@'                     ; 32-bit fetch
        _lfetch
endinline

; ### l@s
inline lfetchs, 'l@s'                   ; c-addr -- n
        movsx   rbx, dword [rbx]        ; n is the sign-extended 32-bit value stored at c_addr
endinline

; ### 2@
code twofetch, '2@'                     ; a-addr -- x1 x2
; CORE
; "x2 is stored at a-addr and x1 at the next consecutive cell."
        mov     rax, [rbx + BYTES_PER_CELL]
        mov     [rbp - BYTES_PER_CELL], rax
        lea     rbp, [rbp - BYTES_PER_CELL]
        mov     rbx, [rbx]
        next
endcode
