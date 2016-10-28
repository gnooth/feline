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

; ### stack-cells                       ; environment query
value stack_cells, 'stack-cells', 0     ; initialized in main()

; ### cold-rbp
variable cold_rbp, 'cold-rbp', 0

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

; ### user-home
code user_home, 'user-home'             ; -- string
%ifdef WIN64
        _quote "USERPROFILE"
%else
        _quote "HOME"
%endif
        _ get_environment_variable      ; -- string
        next
endcode

; ### initialize-task
code initialize_task, 'initialize-task' ; --
        _ holdbufsize
        _ forth_allocate
        _ drop                          ; REVIEW
        _ holdbufptr
        _ store
        _ padsize
        _ forth_allocate
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

; ### .version
code dot_version, '.version'            ; --
        _quote "Feline "
        _quote VERSION
        _ concat
        _ dot_string

        _ feline_home
        _quote "build"
        _ path_append
        _ safe_file_contents
        _dup
        _tagged_if .1
        _quote " built "
        _ write_string
        _ write_string
        _else .1
        _drop
        _then .1

        next
endcode

; ### interactive?
value interactive?, 'interactive?', 0

; ### cold
code cold, 'cold'                       ; --
        mov     [rp0_data], rsp
        mov     [cold_rbp_data], rbp
        mov     rbp, [sp0_data]
        mov     rax, [dp_data]
        mov     [origin_data], rax
        mov     rax, [cp_data]
        mov     [origin_c_data], rax
        _ initialize_locals_stack
        _ forth_standard_output

        _ forth_wordlist
        _fetch
        _zeq_if .1
        _ latest
        _ forth_wordlist
        _ store
        _then .1

        _ feline_wordlist
        _fetch
        _zeq_if .2
        _ feline_last
        _ fetch
        _ feline_wordlist
        _ store
        _then .2

        _ initialize_task

        _ initialize_handle_space

        _lit 256
        _ new_vector_untagged
        _to gc_roots
        _lit gc_roots_data
        _ gc_add_root

        _lit free_handles_data
        _ gc_add_root

        _ initialize_globals

        _ initialize_vocabs

        _lit 16
        _ new_vector_untagged
        _to context_vector
        _lit context_vector_data
        _ gc_add_root

        _ initialize_generic_functions

        _ initialize_source_files

        _ hash_vocabs

        _ initialize_symbols

;         _ report_startup_time

        ; start in Feline mode
        _ feline
        _ definitions

        _ process_command_line

        _true
        _to interactive?

        _ dot_version
        _ ?nl

        _lit process_init_file_xt
        _ feline_catch
        _ ?dup
        _if .4
        _ feline_do_error
        _then .4

        _quote "boot.feline"
        _lit load_system_file_xt
        _ feline_catch
        _ ?dup
        _if .5
        _ feline_do_error
        _then .5

        _quote "Meow!"
        _ write_string
        _ nl

        jmp     repl

        next
endcode
