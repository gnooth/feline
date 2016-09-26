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

; http://www.intel.com/content/www/us/en/embedded/training/ia-32-ia-64-benchmark-code-execution-paper.html

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
_global user_microseconds
_global system_microseconds

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

_global start_ticks
_global end_ticks

; ### elapsed-ms
code elapsed_ms, 'elapsed-ms'           ; -- ms
        pushrbx
        mov     rbx, [end_ticks]
        sub     rbx, [start_ticks]
        next
endcode

_global start_cycles
_global end_cycles

; ### elapsed-cycles
code elapsed_cycles, 'elapsed-cycles'   ; -- cycles
        pushrbx
        mov     rbx, [end_cycles]
        sub     rbx, [start_cycles]
        next
endcode

; ### start-timer
code start_timer, 'start-timer'         ; --
        xor     eax, eax
        mov     [end_ticks], rax
        mov     [end_cycles], rax
        _ ticks
        mov     [start_ticks], rbx
        poprbx
        _rdtsc
        mov     [start_cycles], rbx
        poprbx
        next
endcode

; ### stop-timer
code stop_timer, 'stop-timer'           ; --
        _rdtsc
        mov     [end_cycles], rbx
        poprbx
        _ ticks
        mov     [end_ticks], rbx
        poprbx
        next
endcode

; ### .elapsed
code dot_elapsed, '.elapsed'            ; --
        _ ?nl
        _ elapsed_ms
        _tag_fixnum
        _ fixnum_to_string
        _ write_string
        _quote " ms"
        _ write_string
        _ nl
        _ elapsed_cycles
        _tag_fixnum
        _ fixnum_to_string
        _ write_string
        _quote " cycles"
        _ write_string
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
