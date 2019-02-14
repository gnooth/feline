; Copyright (C) 2012-2019 Peter Graves <gnooth@gmail.com>

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
code get_saved_backtrace, 'get-saved-backtrace' ; -- vector
        xcall   c_get_saved_backtrace_array
        pushd   rax
        xcall   c_get_saved_backtrace_size
        pushd   rax

        _dup
        _ new_vector_untagged
        _ rrot
        _zero
        _?do .1
        _dup
        _i
        _cells
        _plus
        _fetch
        _pick
        _ vector_push
        _loop .1

        _drop

        next
endcode

%ifdef WIN64

; These values are set by the Windows exception handler (in main.c).
value saved_exception_code, 'saved-exception-code', 0 ; untagged
value saved_exception_address, 'saved-exception-address', 0 ; untagged

%else

; These values are set by the signal handler in main.c.
value saved_signal, 'saved-signal', 0 ; untagged
value saved_signal_address, 'saved-signal-address', 0 ; untagged

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

; ### maybe-print-saved-registers
code maybe_print_saved_registers, 'maybe-print-saved-registers' ; --
        _quote "print-saved-registers"
        _quote "feline"
        _ ?lookup_symbol                ; -- symbol/f
        _dup
        _tagged_if .1                   ; -- symbol
        _ call_symbol                   ; --
        _then .1
        next
endcode

; ### maybe-print-backtrace
code maybe_print_backtrace, 'maybe-print-backtrace' ; --
        _quote "print-backtrace"
        _quote "feline"
        _ ?lookup_symbol                ; -- symbol/f
        _dup
        _tagged_if .1                   ; -- symbol
        _ call_symbol                   ; --
        _then .1
        next
endcode

; ### print-saved-registers-and-backtrace
code print_saved_registers_and_backtrace, 'print-saved-registers-and-backtrace' ; --
        _ maybe_print_saved_registers
        _ maybe_print_backtrace
        next
endcode

%ifdef WIN64

; ### exception-text
code exception_text, 'exception-text'   ; n -- string/f
        _dup
        _lit $0C0000005
        _equal
        _if .1
        _drop
        _quote "memory access exception"
        _return
        _then .1

        _dup
        _lit $0C0000094
        _equal
        _if .2
        _drop
        _quote "division by zero exception"
        _return
        _then .2

        _dup
        _lit $080000003
        _equal
        _if .3
        _drop
        _quote "breakpoint exception"
        _return
        _then .3

        ; default
        _drop
        _f
        next
endcode

%endif

; ### print-exception
code print_exception, 'print-exception'

%ifdef WIN64
        _ saved_exception_code
        _ exception_text
        _dup
        _tagged_if .1
        _write "Caught "
        _ write_string
        _else .1
        ; no text for this exception code
        _drop
        _write "Caught exception "
        _ saved_exception_code
        _tag_fixnum
        _ hexdot
        _then .1
        _write " at address "
        _ saved_exception_address
        _tag_fixnum
        _ hexdot
%else
        _write "Caught signal "
        _ saved_signal
        _tag_fixnum
        _ decimal_dot
        _write " at address "
        _ saved_signal_address
        _ untagged_dot
        _ nl
%endif

        next
endcode

; ### handle-signal
code handle_signal, 'handle-signal'
        mov     rbp, [primordial_sp0_]
        mov     rsp, [primordial_rp0_]

        _lp0
        _?dup
        _if .1
        _lpstore
        _then .1

        _ ?nl
        _ print_exception
        _ print_saved_registers_and_backtrace

        _ reset

        next
endcode
