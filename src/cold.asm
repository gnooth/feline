; Copyright (C) 2012-2017 Peter Graves <gnooth@gmail.com>

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

asm_global rp0_, 0

asm_global sp0_, 0                      ; initialized in main()

; ### stack-cells                       ; environment query
value stack_cells, 'stack-cells', 0     ; initialized in main()

asm_global cold_rbp_, 0

asm_global main_argc ; untagged
asm_global main_argv ; untagged

feline_global args, 'args'

; ### process-command-line
code process_command_line, 'process-command-line'

; sudo sh -c 'echo 1 > /proc/sys/kernel/perf_event_paranoid'
; perf record feline -e '"stress.feline" load bye'

        pushrbx
        mov     rbx, [main_argc]        ; -- argc

        _dup
        _ new_vector_untagged   ; -- argc vector
        _to_global args         ; -- argc

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
        _ args
        _ vector_push
        _loop .1

        _ args
        _ vector_length
        _tagged_fixnum 3
        _ eq?
        _tagged_if .2
        _ args
        _ second
        _quote "-e"
        _ equal?
        _tagged_if .3
        _ args
        _ third
        _ verify_string
        _ evaluate
        _return
        _then .3
        _then .2

        _ args
        _ vector_length
        _tagged_fixnum 2
        _ fixnum_fixnum_ge
        _tagged_if .4
        _ args
        _ second
        _ load
        _then .4

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

; ### load-verbose?
special load_verbose?, 'load-verbose?'

; ### cold
code cold, 'cold'                       ; --
        mov     [rp0_], rsp
        mov     [cold_rbp_], rbp
        mov     rbp, [sp0_]

        _ initialize_locals_stack
        _ forth_standard_output

        _ seed_random

        _ initialize_handle_space

        _lit 256
        _ new_vector_untagged
        _to gc_roots
        _lit gc_roots_data
        _ gc_add_root

        _ initialize_gc_dispatch_table

        _ initialize_types

        _ initialize_globals

        _ initialize_vocabs

        _ initialize_generic_functions

        _ hash_vocabs

        _ initialize_type_symbols

        _quote "boot.feline"
        _lit S_load_system_file
        _ catch
        _ ?dup
        _if .1
        _ do_error
        _then .1

;         _ report_startup_time

        _ user_vocab
        _to_global current_vocab

        _lit S_process_command_line
        _ catch
        _ ?dup
        _if .2
        _ do_error
        _then .2

        _ dot_version
        _ ?nl

        _lit S_process_init_file
        _ catch
        _ ?dup
        _if .3
        _ do_error
        _then .3

        _t
        _ interactive?
        _ set_global

        _t
        _ load_verbose?
        _ set_global

        _quote "Meow!"
        _ write_string
        _ nl

        jmp     quit

        next
endcode
