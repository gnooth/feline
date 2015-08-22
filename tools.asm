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

; ### int3
code int3, 'int3'                       ; --
        int 3
        next
endcode

; ### rdtsc
code read_time_stamp_counter, 'rdtsc'
        rdtsc
; "The high-order 32 bits are loaded into EDX, and the low-order 32 bits are
; loaded into the EAX register. This instruction ignores operand size."
        pushrbx
        mov     ebx, eax
        shl     rdx, 32
        add     rbx, rdx
        next
endcode

extern os_ticks

; ### ticks
code ticks, 'ticks'                     ; -- u
%ifdef WIN64
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%endif
        xcall   os_ticks
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushd   rax
        next
endcode
