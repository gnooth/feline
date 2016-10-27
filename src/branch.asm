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

section .text
?branch:
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jz      0
?branch_end:

; ### 0branch
inline zerobranch, '0branch'
        test    rbx, rbx
        mov     rbx, [rbp]
        lea     rbp, [rbp + BYTES_PER_CELL]
        jz      0
endinline

; ### dup-0branch
inline dup_zerobranch, 'dup-0branch'
        test    rbx, rbx
        jz      0
endinline

; ### ?dup-0branch
inline ?dup_zerobranch, '?dup-0branch'
        test    rbx, rbx
        jnz     .1
        poprbx
        jmp     0
.1:
endinline

value last_branch_target, 'last-branch-target', 0
