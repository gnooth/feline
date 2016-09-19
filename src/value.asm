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

; ### compile-value-ref
code compile_value_ref, 'compile-value-ref'     ; xt --
        ; REVIEW
        _ cq
        _if .1
        _ cq_flush_literals             ; -- xt
        _then .1

        _tobody                         ; -- pfa
        _tor                            ; --            r: -- pfa
        _ compile_pushrbx
        _rfetch
        _ max_int32
        _ ult
        _if .2
        _ccommac $48
        _ccommac $8b                    ; mov rbx, [disp32]
        _ccommac $1c
        _ccommac $25
        _rfrom
        _ lcommac
        _else .2
        _ccommac $48
        _ccommac $0bb                   ; mov rbx, imm64
        _rfrom
        _ commac
        _ccommac $48                    ; mov rbx, [rbx]
        _ccommac $8b
        _ccommac $1b
        _then .2

        _ cq
        _if .3
        _lit 1
        _plusto cq_index
        _then .3

        next
endcode

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

        _ latestxt
        _ compile_value_ref

        _ccommac $0c3                   ; -- x

        _ comma                         ; --

        _ tvalue
        _ latest
        _namefrom
        _totype
        _ cstore

        ; inline by default
        _ inline_latest

        ; set compiler
        _lit compile_value_ref_xt
        _ latestxt
        _ tocompstore

        next
endcode

; ### check-value-or-variable
code check_value_or_variable, 'check-value-or-variable' ; xt -- xt
        _dup
        _totype
        _cfetch
        cmp     rbx, TYPE_VALUE
        je      .1
        cmp     rbx, TYPE_VARIABLE
        je      .1
        _cquote "Invalid name argument"
        _to msg
        _lit -32                        ; "invalid name argument" Forth 2012 Table 9.1
        _ forth_throw
.1:
        _drop
        next
endcode

; ### to
code storeto, 'to', IMMEDIATE           ; n "<spaces>name" --
; CORE EXT
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

        ; verify that what we're storing to is a VALUE or VARIABLE
        _ check_value_or_variable

        _tobody                         ; -- n pfa
        _ statefetch
        _if .4
        _ flush_compilation_queue
        _dup
        _ max_int32
        _ ult
        _if .5
        _ccommac $48
        _ccommac $89
        _ccommac $1c
        _ccommac $25
        _ lcommac                       ; 32-bit address
        _else .5
        _ccommac $48
        _ccommac $0b8
        _ commac                        ; mov rax, pfa
        _ccommac $48
        _ccommac $89
        _ccommac $18                    ; mov [rax], rbx
        _then .5
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

        ; verify that what we're storing to is a VALUE or VARIABLE
        _ check_value_or_variable

        _tobody
        _ statefetch
        _if .4
        _ flush_compilation_queue
        _dup
        _ max_int32
        _ ult
        _if .5
        _ccommac $48
        _ccommac $01
        _ccommac $1c
        _ccommac $25
        _ lcommac                       ; 32-bit address
        _else .5
        _ccommac $48
        _ccommac $0b8
        _ commac                        ; mov rax, pfa
        _ccommac $48
        _ccommac $01
        _ccommac $18                    ; add [rax], rbx
        _then .5
        _ compile_poprbx
        _else .4                        ; -- n addr
        _ plusstore
        _then .4
        next
endcode
