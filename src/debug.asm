; Copyright (C) 2016-2018 Peter Graves <gnooth@gmail.com>

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

asm_global debug_enabled, t_value

; ### +debug
code debug_on, '+debug'
        mov     qword [debug_enabled], t_value
        next
endcode

; ### -debug
code debug_off, '-debug'
        mov     qword [debug_enabled], f_value
        next
endcode

; ### debug0
code debug0, 'debug0'                   ; string --
        cmp     qword [debug_enabled], f_value
        je      .1
        _ ?nl
        _ write_string
        _ nl
.1:
        next
endcode

%macro  _debug0 1
        _quote %1
        _ debug0
%endmacro

; ### debug1
code debug1, 'debug1'                   ; string --
        cmp     qword [debug_enabled], f_value
        je      .1
        _ ?nl
        _ write_string
        _write ": "
        _dup
        _ dot_object
        _return
.1:
        _drop
        next
endcode

%macro  _debug1 1
        _quote %1
        _ debug1
%endmacro

asm_global debug_print_lock_, 0

; ### debug-print
code debug_print, 'debug-print'         ; string --

        mov     eax, 1

.lock:
        cmp     byte [debug_print_lock_], 0
        jne     .lock

        xchg    eax, [debug_print_lock_]
        test    eax, eax
        jnz     .lock

        _ ?nl

        _ current_thread
        _ thread_debug_name
        _ write_string
        _quote ": "
        _ write_string

        _ write_string
        _ nl

        ; unlock
        mov     byte [debug_print_lock_], 0

        next
endcode
