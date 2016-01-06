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

; ### start-time-ticks
value start_time_ticks, 'start-time-ticks', 0

; ### rp0
variable rp0, 'rp0', 0

; ### sp0
variable sp0, 'sp0', 0                  ; initialized in main()

; ### saved-rbp
variable saved_rbp, 'saved-rbp', 0

; ### origin
value origin, 'origin', 0

; ### origin-c
value origin_c, 'origin-c', 0

; ### limit
value limit, 'limit', 0                 ; initialized in main()

; ### limit-c
value limit_c, 'limit-c', 0             ; initialized in main()

; ### dp
variable dp, 'dp', 0                    ; initialized in main()

; ### cp
variable cp, 'cp', 0                    ; initialized in main()

; ### argc
variable argc, 'argc', 0

; ### argv
variable argv, 'argv', 0

; ### process-command-line
deferred process_command_line, 'process-command-line', noop

; ### process-init-file
deferred process_init_file, 'process-init-file', noop

; ### 'pad
variable tickpad, "'pad", 0

; ### pad
code pad, 'pad'                         ; -- c-addr
; CORE EXT
        _ tickpad
        _fetch
        next
endcode

value user_home_string, '$user-home', 0

; ### user-home
code user_home, 'user-home'             ; -- $addr
        _ user_home_string
        _zeq_if .1
%ifdef WIN64
        _squote "USERPROFILE"
%else
        _squote "HOME"
%endif
        _ getenv_                       ; -- c-addr u
        _dup
        _lit 255
        _ gt
        _abortq "user-home pathname too long"
        _ here
        _tor
        _ stringcomma
        _rfrom
        _to user_home_string
        _then .1
        _ user_home_string
        next
endcode

; ### initialize-task
code initialize_task, 'initialize-task' ; --
        _ holdbufsize
        _ allocate
        _ drop                          ; REVIEW
        _ holdbufptr
        _ store
        _ padsize
        _ allocate
        _ drop                          ; REVIEW
        _ tickpad
        _ store
        next
endcode

; ### report-startup-time
code report_startup_time, 'report-startup-time' ; --
        _dotq "Startup completed in "
        _ ticks
        _ start_time_ticks
        _ minus
        _ dot
        _dotq "milliseconds."
        _ cr
        next
endcode

; ### cold
code cold, 'cold'                       ; --
        mov     [rp0_data], rsp
        mov     [saved_rbp_data], rbp
        mov     rbp, [sp0_data]
        mov     rax, [dp_data]
        mov     [origin_data], rax
        mov     rax, [cp_data]
        mov     [origin_c_data], rax
        _ initialize_locals_stack
        _ standard_output
        _ forth_wordlist
        _fetch
        _zeq_if .1
        _ latest
        _ forth_wordlist
        _ store
        _then .1
        _ initialize_task
        _squote "boot.forth"
        _ system_file_pathname
        _lit included_xt
        _ catch
        _ ?dup
        _if .2
        _ do_error
        _then .2
        _ report_startup_time
        _ process_command_line
        _ process_init_file
        _dotq "Meow!"
        _ cr
        jmp quit
        next
endcode

; ### editor-line-vector
value editor_line_vector, 'editor-line-vector', 0

; ### editor-top-line
value editor_top_line, 'editor-top-line', 0
