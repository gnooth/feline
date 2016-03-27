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

; ### compile-global-ref
code compile_global_ref, 'compile-global-ref' ; xt --
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
        _ult
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

; ### global
code global_var, 'global'               ; x "<spaces>name" --
        _ header
        _ align_data
        _ align_code
        _ here_c
        _ latest
        _namefrom
        _ store

        _ latestxt
        _ compile_global_ref

        _ccommac $0c3                   ; -- x

        _ here
        _ add_explicit_root

        _ comma                         ; --

        _lit TYPE_GLOBAL
        _ latest
        _namefrom
        _totype
        _ cstore

        ; inline by default
        _ inline_latest

        ; set compiler
        _lit compile_global_ref_xt
        _ latestxt
        _ tocompstore

        next
endcode

; ### check-global
code check_global, 'check-global' ; xt -- xt
        _dup
        _totype
        _cfetch
        cmp     ebx, TYPE_GLOBAL
        je      .1
        ; REVIEW
        _cquote "Invalid name argument"
        _to msg
        _lit -32                        ; "invalid name argument" Forth 2012 Table 9.1
        _ throw
.1:
        _drop
        next
endcode

; ### !>
code store_to, '!>', IMMEDIATE          ; n "<spaces>name" --
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

        ; verify that what we're storing to is a global
        _ check_global

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
