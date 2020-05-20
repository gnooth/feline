; Copyright (C) 2012-2020 Peter Graves <gnooth@gmail.com>

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

asm_global start_time_raw_nano_count_, 0

; ### start_time_raw_nano_count
code start_time_raw_nano_count, 'start_time_raw_nano_count', SYMBOL_INTERNAL
        _dup
        mov     rbx, [start_time_raw_nano_count_]
        next
endcode

asm_global primordial_rp0_, 0

asm_global primordial_sp0_, 0           ; initialized in main()

; ### sp0
code sp0, 'sp0'                         ; -- tagged-address
        _ current_thread
        _ thread_sp0
        next
endcode

asm_global main_argc ; untagged
asm_global main_argv ; untagged

asm_global args_

code args, 'args'                       ; -- vector
        pushrbx
        mov     rbx, [args_]
        next
endcode

; ### process_command_line
code process_command_line, 'process_command_line', SYMBOL_INTERNAL

; sudo sh -c 'echo 1 > /proc/sys/kernel/perf_event_paranoid'
; perf record feline -e '"stress.feline" load bye'

        _dup
        mov     rbx, [main_argc]        ; -> argc

        _dup
        _ new_vector_untagged           ; -> argc vector
        mov     [args_], rbx
        _drop
        _lit args_
        _ gc_add_root

        _zero
        _?do .1
        _dup
        mov     rbx, [main_argv]
        _i
        _cells
        _plus
        _fetch                          ; -> zstring
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
        _ file_exists?
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
        _ raw_nano_count
        _ start_time_raw_nano_count
        _minus
        _lit 1000000
        _ raw_int64_divide_truncate
        _ decimal_dot
        _write " milliseconds."
        _ nl
        next
endcode

; version.c
extern version
extern build

; ### version-string
code version_string, 'version-string'   ; void -> string
        _lit tagged_fixnum(256)
        _ make_sbuf                     ; -> sbuf

        _quote "Feline "                ; -> sbuf string
        _over
        _ sbuf_append_string            ; -> sbuf

        xcall   version                 ; returns address of null-terminated string in rax
        _dup
        mov     rbx, rax                ; -> sbuf
        _ zcount
        _ copy_to_string                ; -> sbuf string

        _over
        _ sbuf_append_string            ; -> sbuf

%ifdef DEBUG
        _quote "-DEBUG"
        _over
        _ sbuf_append_string
%endif

        xcall   build                   ; returns address of null-terminated string in rax
        _dup
        mov     rbx, rax
        _ zcount                        ; -> sbuf raw-chars raw-count
        test    rbx, rbx                ; zero length string?
        jz      .1
        _ copy_to_string                ; -> sbuf string

        _quote " built "                ; -> sbuf string string'
        _pick                           ; -> sbuf string string' sbuf
        _ sbuf_append_string            ; -> sbuf string

        _over
        _ sbuf_append_string
        _ sbuf_to_string
        next
.1:
        _2drop                          ; -> sbuf
        _ sbuf_to_string
        next
endcode

; ### .version
code dot_version, '.version'
        _ version_string
        _ print
        next
endcode

; ### interactive?
special interactive?, 'interactive?'

; ### load-verbose?
special load_verbose?, 'load-verbose?'

; ### cold
code cold, 'cold', SYMBOL_INTERNAL      ; --
        mov     [primordial_rp0_], rsp
        mov     rbp, [primordial_sp0_]

        _ seed_random

        _ initialize_handle_space

        _lit 256
        _ new_vector_untagged
        mov     [gc_roots_], rbx
        poprbx
        _lit gc_roots_
        _ gc_add_root

        _ cold_initialize_locals

        _ initialize_dynamic_scope

        _ initialize_vocabs

        _ initialize_generic_functions

        _ hash_vocabs

        _ initialize_streams

        _lit 64
        _ new_hashtable_untagged
        mov     [keyword_hashtable_], rbx
        _drop
        _lit keyword_hashtable_
        _ gc_add_root

        _ initialize_types

        _ initialize_load_path

        _ initialize_threads

        _ initialize_handles_lock

        _ initialize_gc_lock

        _ gc2_initialize_dispatch_table
        _ gc2_initialize_work_list

        _quote "boot.feline"
        _lit S_load_system_file
        _ catch
        _dup
        _tagged_if .1
        _ do_error
        _else .1
        _drop
        _then .1

        _ report_startup_time

        _ user_vocab
        _ set_current_vocab

        _lit S_process_command_line
        _ catch
        _dup
        _tagged_if .2
        _ do_error
        _else .2
        _drop
        _then .2

        _ dot_version

        _lit S_process_init_file
        _ catch
        _dup
        _tagged_if .3
        _ do_error
        _else .3
        _drop
        _then .3

        _t
        _ interactive?
        _ set

        _t
        _ load_verbose?
        _ set

        _quote "Meow!"
        _ write_string

        jmp     quit

        next
endcode
