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

; ### int3
code int3, 'int3'                       ; --
        int3
        next
endcode

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

; %ifndef WIN64

extern c_get_saved_backtrace_array
extern c_get_saved_backtrace_size

extern c_save_backtrace

; ### save-backtrace
code save_backtrace, 'save-backtrace'   ; --
%ifdef WIN64
        mov     rcx, $
        mov     rdx, rsp
%else
        mov     rdi, $
        mov     rsi, rsp
%endif
        xcall   c_save_backtrace
        next
endcode


; ### get-saved-backtrace
code get_saved_backtrace, 'get-saved-backtrace' ; -- addr u
        xcall   c_get_saved_backtrace_array
        pushd   rax
        xcall   c_get_saved_backtrace_size
        pushd   rax
        next
endcode

; %endif

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

%ifdef WIN64
value saved_exception_code, 'saved-exception-code', 0
value saved_exception_address, 'saved-exception-address', 0
%else
value saved_signal, 'saved-signal', 0
value saved_signal_address, 'saved-signal-address', 0
%endif

value saved_rax, 'saved-rax', 0
value saved_rbx, 'saved-rbx', 0
value saved_rcx, 'saved-rcx', 0
value saved_rdx, 'saved-rdx', 0
value saved_rsi, 'saved-rsi', 0
value saved_rdi, 'saved-rdi', 0
value saved_rbp, 'saved-rbp', 0
value saved_rsp, 'saved-rsp', 0
value saved_r8,  'saved-r8',  0
value saved_r9,  'saved-r9',  0
value saved_r10, 'saved-r10', 0
value saved_r11, 'saved-r11', 0
value saved_r12, 'saved-r12', 0
value saved_r13, 'saved-r13', 0
value saved_r14, 'saved-r14', 0
value saved_r15, 'saved-r15', 0
value saved_rip, 'saved-rip', 0
value saved_efl, 'saved-efl', 0

; ### print-saved-registers-and-backtrace
deferred print_saved_registers_and_backtrace, 'print-saved-registers-and-backtrace', noop

%ifdef WIN64
; ### exception-text
code exception_text, 'exception-text'   ; n -- $addr
; The exception text should end with a space for compatibility with
; the string printed by h. when there is no exception text.
        _dup
        _lit $0C0000005
        _equal
        _if .1
        _drop
        _cquote "memory access exception "
        _return
        _then .1
        _dup
        _lit $0C0000094
        _equal
        _if .2
        _drop
        _cquote "division by zero exception "
        _return
        _then .2
        _dup
        _lit $080000003
        _equal
        _if .3
        _drop
        _cquote "breakpoint exception "
        _return
        _then .3
        ; default
        _drop
        _zero
        next
endcode
%endif

; ### print-exception
code print_exception, 'print-exception'
%ifdef WIN64
        _ saved_exception_code
        _ exception_text
        _?dup
        _if .1
        _dotq "Caught "
        _ counttype
        _else .1
        ; no text for this exception code
        _dotq "Caught exception "
        _ saved_exception_code
        _ hdot
        _then .1
        _dotq "at address "
        _ saved_exception_address
        _ hdot
%else
        _dotq "Caught signal "
        _ saved_signal
        _ decdot
        _dotq "at address "
        _ saved_signal_address
        _ hdot
%endif
        next
endcode

; ### handle-signal
code handle_signal, 'handle-signal'
        mov     rbp, [sp0_data]
        mov     rsp, [rp0_data]

        _ lp0
        _fetch
        _ ?dup
        _if .1
        _ lpstore
        _then .1

        _ ?cr
        _ print_exception
        _ print_saved_registers_and_backtrace
        _ reset
        next
endcode

; ### break?
variable break?, 'break?', 0

; ### continue?
variable continue?, 'continue?', 0

; ### continue
code continue, 'continue'
        _ continue?
        _ on
        next
endcode

; ### break
code break, 'break'                     ; --
        _ break?
        _fetch
        _if .1
        _ break?
        _ off
        _ continue?
        _ off
        _ cr
        _dotq "stack: "
        _ dots
        _ cr
        _begin .2
        _dotq "break: "
        _ query
        _ tib
        _ ntib
        _fetch
        _zero
        _ set_input
        _zero
        _to source_filename
        _lit interpret_xt
        _ catch
        _ ?dup
        _if .3
        ; THROW occurred
        _ do_error
        _else .3
        _ ok
        _ white
        _ foreground
        _ cr
        _then .3
        _ continue?
        _fetch
        _until .2
        _ break?
        _ on
        _then .1
        next
endcode
