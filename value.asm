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

section .text
dovalue:
        pushrbx
        db      $48                     ; mov rbx, 0
        db      $0bb
dovalue_patch:
        dq      0                       ; 64-bit immediate value (to be patched)
        mov     rbx, [rbx]
dovalue_end:

; ### value
code val, 'value'                       ; x "<spaces>name" --
; CORE EXT
        _ header
        _ align_data
        _ align_code
        _ here_c
        _ latest
        _ namefrom
        _ store
        _lit dovalue
        _lit dovalue_end - dovalue
        _ paren_copy_code
        _ here                          ; -- addr
        _ here_c
        _lit dovalue_end - dovalue_patch
        _ minus
        _ store
        _lit $0c3
        _ ccommac
        _ comma
        next
endcode

; ### to
code storeto, 'to', IMMEDIATE           ; n "<spaces>name" --
        _ blchar
        _ word_                         ; -- n $addr

        _ statefetch
        _if .1
        _ dup
        _ find_local                    ; -- $addr index flag
        _if .2
        _ nip
        _ compile_tolocal
        _return
        _else .2
        _ drop
        _then .2
        _then .1

        _ find
        _zeq_if .3
        _ missing
        _then .3

        _ tobody                        ; -- n pfa
        _ statefetch
        _if .4
        _ flush_compilation_queue
        _lit $48
        _ ccommac
        _lit $0b8
        _ ccommac
        _ commac                        ; mov rax, pfa
        _lit $48
        _ ccommac
        _lit $89
        _ ccommac
        _lit $18
        _ ccommac                       ; mov [rax], rbx
        _ pop_tos_comma
        _else .4
        _ store
        _then .4
        next
endcode

; ### +to
code plusstoreto, '+to', IMMEDIATE      ; n "<spaces>name" --
        _ tick
        _ tobody
        _ statefetch
        _if .1
        _ flush_compilation_queue
        _ iliteral
        _lit plusstore
        _ commacall
        _else .1                        ; -- n addr
        _ plusstore
        _then .1
        next
endcode
