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
        _namefrom
        _ store
        _lit dovalue
        _lit dovalue_end - dovalue
        _ paren_copy_code
        _ here                          ; -- addr
        _ here_c
        _lit dovalue_end - dovalue_patch
        _ minus
        _ store
        _ccommac $0c3
        _ comma

        _ tvalue
        _ latest
        _namefrom
        _totype
        _ cstore

        _ inline_latest

        next
endcode

; ### to
code storeto, 'to', IMMEDIATE           ; n "<spaces>name" --
        _ blword                        ; -- n $addr

        _ statefetch
        _if .1
        _ find_local                    ; -- n $addr-or-index flag
        _if .2                          ; -- n index
        _ flush_compilation_queue
        _ compile_to_local
        _return
        _then .2
        _then .1                        ; -- n $addr

        ; not a local
        _ find
        _zeq_if .3                      ; not found
        _ missing                       ; -13 THROW
        _then .3                        ; -- n xt

        ; FIXME verify that what we're storing to is a VALUE or VARIABLE
        _tobody                         ; -- n pfa
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
        _ compile_poprbx
        _else .4
        _ store
        _then .4
        next
endcode

; ### +to
code plusstoreto, '+to', IMMEDIATE      ; n "<spaces>name" --
        _ blword                        ; -- n $addr

        _ statefetch
        _if .1
        _ find_local                    ; -- n $addr-or-index flag
        _if .2                          ; -- n index
        _ flush_compilation_queue
        _ compile_plusto_local
        _return
        _then .2
        _then .1                        ; -- n $addr

        ; not a local
        _ find
        _zeq_if .3                      ; not found
        _ missing                       ; -13 THROW
        _then .3                        ; -- n xt

        _tobody
        _ statefetch
        _if .4
        _ flush_compilation_queue
        _ iliteral
        _lit plusstore
        _ commacall
        _else .4                        ; -- n addr
        _ plusstore
        _then .4
        next
endcode
