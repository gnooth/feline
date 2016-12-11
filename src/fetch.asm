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

; ### @
inline fetch, '@'
        _fetch
endinline

; ### @+
code fetchplus, '@+'                    ; a-addr1 -- a-addr2 x
; iForth
; fetch x from a-addr1
; a-addr2 = a-addr1 + BYTES_PER_CELL
        pushrbx
        add     qword [rbp], BYTES_PER_CELL
        mov     rbx, [rbx]
        next
endcode

; ### c@+
code cfetchplus, 'c@+'                  ; c-addr1 -- c-addr2 char
; iForth
; fetch char from c-addr1
; c-addr2 = c-addr1 + 1
        pushrbx
        add     qword [rbp], 1
        movzx   rbx, byte [rbx]
        next
endcode

; ### w@
; 16-bit fetch
inline wfetch, 'w@'
        _wfetch
endinline

; ### w@s
inline wfetchs, 'w@s'                   ; c-addr -- n
        movsx   rbx, word [rbx]         ; n is the sign-extended 16-bit value stored at c-addr
endinline
