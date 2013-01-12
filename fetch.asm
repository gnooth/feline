; Copyright (C) 2012-2013 Peter Graves <gnooth@gmail.com>

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

inline fetch, '@'
        mov     rbx, [rbx]
endinline

; code cfetch, 'c@', 0, cfetch_ret - cfetch
;         movzx   rbx, byte [rbx]
; cfetch_ret:
;         next
; endcode
inline cfetch, 'c@'
        movzx   rbx, byte [rbx]
endinline

code cfetchs, 'c@s'                     ; c-addr -- n
        movsx   rbx, byte [rbx]         ; n is the sign-extended 8-bit value stored at c_addr
        next
endcode

code lfetch, 'l@'                       ; 32-bit fetch
        mov     ebx, dword [rbx]
        next
endcode

code lfetchs, 'l@s'                     ; c-addr -- n
        movsx   rbx, dword [rbx]        ; n is the sign-extended 32-bit value stored at c_addr
        next
endcode

code twofetch, '2@'                     ; a-addr -- x1 x2
; CORE
; "x2 is stored at a-addr and x1 at the next consecutive cell."
        mov     rax, [rbx + BYTES_PER_CELL]
        sub     rbp, BYTES_PER_CELL
        mov     [rbp], rax
        mov     rbx, [rbx]
        next
endcode
