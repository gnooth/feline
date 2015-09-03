; Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

; ### rp0
variable rp0, 'rp0', 0

; ### sp0
variable sp0, 'sp0', 0                  ; initialized in main()

; ### saved-rbp
variable saved_rbp, 'saved-rbp', 0

; ### origin
variable origin, 'origin', 0

; ### origin-c
variable origin_c, 'origin-c', 0

; ### dp
variable dp, 'dp', 0                    ; initialized in main()

; ### cp
variable cp, 'cp', 0                    ; initialized in main()

; ### limit
variable limit, 'limit', 0              ; initialized in main()

; ### limit-c
variable limit_c, 'limit-c', 0          ; initialized in main()

; ### argc
variable argc, 'argc', 0

; ### argv
variable argv, 'argv', 0

; ### process-command-line
deferred process_command_line, 'process-command-line', noop

; ### 'pad
variable tickpad, "'pad", 0

; ### pad
code pad, 'pad'                         ; -- c-addr
; CORE EXT
        _ tickpad
        _fetch
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

; ### cold
code cold, 'cold'                       ; --
        mov     [rp0_data], rsp
        mov     [saved_rbp_data], rbp
        mov     rbp, [sp0_data]
        _ here
        _ origin
        _ store
        _ here_c
        _ origin_c
        _ store
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
        _ process_command_line
        jmp quit
        next
endcode
