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

; ### rdtsc
inline read_time_stamp_counter, 'rdtsc'
        rdtsc
; "The high-order 32 bits are loaded into EDX, and the low-order 32 bits are
; loaded into the EAX register. This instruction ignores operand size."
        pushrbx
        mov     ebx, eax
        shl     rdx, 32
        add     rbx, rdx
endinline

extern os_ticks

; ### ticks
code ticks, 'ticks'                     ; -- u
        xcall   os_ticks
        pushd   rax
        next
endcode

%ifndef WIN64
        global  user_microseconds
        global  system_microseconds
section .data
        align   DEFAULT_DATA_ALIGNMENT
user_microseconds:
        dq      0
system_microseconds:
        dq      0

extern os_cputime

; ### cputime
code cputime, 'cputime'
        xcall   os_cputime
        mov     rax, [user_microseconds]
        pushd   rax
        pushd   0
        mov     rax, [system_microseconds]
        pushd   rax
        pushd   0
        next
endcode
%endif
