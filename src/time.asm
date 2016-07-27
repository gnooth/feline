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

%macro _rdtsc 0                         ; -- u
; "The high-order 32 bits are loaded into EDX, and the low-order 32 bits are
; loaded into the EAX register. This instruction ignores operand size."
        rdtsc
        pushrbx
        mov     ebx, eax
        shl     rdx, 32
        add     rbx, rdx
%endmacro

; ### rdtsc
inline read_time_stamp_counter, 'rdtsc' ; -- u
        _rdtsc
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

; ### start-ticks
value start_ticks, 'start-ticks', 0

; ### end-ticks
value end_ticks, 'end-ticks', 0

; ### elapsed-ms
code elapsed_ms, 'elapsed-ms'           ; -- ms
        _ end_ticks
        _ start_ticks
        _minus
        next
endcode

; ### start-cycles
value start_cycles, 'start-cycles', 0

; ### end-cycles
value end_cycles, 'end-cycles', 0

; ### elapsed-cycles
code elapsed_cycles, 'elapsed-cycles'   ; -- cycles
        _ end_cycles
        _ start_cycles
        _minus
        next
endcode

; ### start-timer
code start_timer, 'start-timer'         ; --
        _clear end_ticks
        _clear end_cycles
        _ ticks
        _to start_ticks
        _rdtsc
        _to start_cycles
        next
endcode

; ### stop-timer
code stop_timer, 'stop-timer'           ; --
        _rdtsc
        _to end_cycles
        _ ticks
        _to end_ticks
        next
endcode

; ### .elapsed
code dot_elapsed, '.elapsed'            ; --
        _ ?cr
        _ elapsed_ms
        _ decdot
        _dotq "ms "
        _ cr
        _ elapsed_cycles
        _ decdot
        _dotq "cycles"
        next
endcode

; ### time
code time, 'time'                       ; quotation-or-xt --
        _ callable_code_address
        push    r12
        mov     r12, rbx
        poprbx
        _ start_timer
        call    r12
        _ stop_timer
        pop     r12
        _ dot_elapsed
        next
endcode
