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

asm_global main_argc ; untagged
asm_global main_argv ; untagged

feline_global args, 'args'

; ### process-command-line
code process_command_line, 'process-command-line'

; sudo sh -c 'echo 1 > /proc/sys/kernel/perf_event_paranoid'
; perf record feline -e '"stress.feline" load bye'

        pushrbx
        mov     rbx, [main_argc]
        _dup
        _ new_vector_untagged   ; -- argc vector

        _swap                   ; -- vector argc

        _zero
        _?do .1
        pushrbx
        mov     rbx, [main_argv]
        _i
        _cells
        _plus
        _fetch                  ; -- zstring
        _ zcount
        _ copy_to_string
        _over
        _ vector_push
        _loop .1

        _dup
        _to_global args

        _dup
        _ vector_length
        _tagged_fixnum 3
        _ eq?
        _tagged_if .2
        _dup
        _ second
        _quote "-e"
        _ equal?
        _tagged_if .3
        _dup
        _ third
        _ verify_string
        _ evaluate
        _then .3
        _then .2

        _drop

        next
endcode

; ### process-init-file
code process_init_file, 'process-init-file' ; --
        _ user_home
        _quote ".init.feline"
        _ path_append
        _dup
        _ path_file_exists?
        _tagged_if .1
        _ load
        _else .1
        _ drop
        _then .1
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

; ### report-startup-time
code report_startup_time, 'report-startup-time' ; --
        _write "Startup completed in "
        _ ticks
        _ start_time_ticks
        _minus
        _tag_fixnum
        _ decimal_dot
        _write "milliseconds."
        _ nl
        next
endcode

; ### .version
code dot_version, '.version'            ; --
        _quote "Feline "
        _quote VERSION
        _ concat
        _ write_string

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
special interactive?, 'interactive?'

; ### cold
code cold, 'cold'                       ; --
        mov     [rp0_data], rsp
        mov     [cold_rbp_data], rbp
        mov     rbp, [sp0_data]

        _ initialize_locals_stack
        _ forth_standard_output

        _ seed_random

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

        _ initialize_generic_functions

        _ hash_vocabs

        _quote "boot.feline"
        _lit S_load_system_file
        _ catch
        _ ?dup
        _if .5
        _ do_error
        _then .5

;         _ report_startup_time

        _ process_command_line

        _ dot_version
        _ ?nl

        _lit S_process_init_file
        _ catch
        _ ?dup
        _if .4
        _ do_error
        _then .4

        _t
        _ interactive?
        _ set_global

        _quote "Meow!"
        _ write_string
        _ nl

        jmp     quit

        next
endcode
