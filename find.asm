; Copyright (C) 2012 Peter Graves <gnooth@gmail.com>

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

code match?, 'match?'                   ; c-addr1 c-addr2 -- flag
        _ count
        _ rot
        _ count
        _ istrequal
        next
endcode

code find, 'find'                       ; c-addr -- c-addr 0  |  xt 1  |  xt -1
        _ latest
        _ over                          ; c-addr latest c-addr
        _ match?                        ; c-addr flag
        test    ebx, ebx
        jz     .continue
        _ twodrop
        _ latest
        _ namefrom
        pushd   -1
        next
.continue:
        _ drop                          ; c-addr
        _ tor                           ; --                    r: c-addr
        _ latest
        _ ntolink                       ; lfa
.loop:
        _ fetch                         ; link
        test    rbx, rbx
        jz      .notfound
        _ dup                           ; -- name name
        _ rfetch                        ; -- name name c-addr
        _ match?
        test    rbx, rbx
        jnz     .found
        _ drop                          ; drop flag left by MATCH?
        _ ntolink
        jmp     .loop
.notfound:
        _ drop
        _ rfrom
        pushd   0
        next
.found:
        _ drop                          ; drop flag left by MATCH?
        _ rfrom
        _ drop
        _ namefrom                      ; -- xt
        _ dup
        _ immediate?
        _if find1
        pushd   1
        _else find1
        pushd   -1
        _then find1
        next
endcode

code tick, "'"
        _ blchar
        _ word_
        _ find
        _ zero?
        _if tick1
        _ count
        _ type
        _dotq ' ?'
        _ cr
        _ abort
        _then tick1
        next
endcode

code bracket_tick, "[']", IMMEDIATE
        _ tick
        pushd   lit
        _ commacall
        _ comma
        next
endcode
