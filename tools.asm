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

code int3, 'int3'                       ; --
        int 3
        next
endcode

code findcode, 'find-code'              ; code-addr -- name-addr
        _ tor                           ; --                            r: code-addr
        _ latest                        ; -- addr1
        _ dup                           ; -- addr1 addr1
        _ namefrom                      ; -- addr1 addr2
        _ tocode                        ; -- addr1 addr3
        _ rfetch                        ; -- addr1 addr3 code-addr      r: code-addr
        _ equal                         ; -- addr1 flag
        _if find_code1                  ; -- addr1
        _ rfrom                         ; -- addr1 code-addr            r: --
        _ drop                          ; -- addr1
        next
        _then find_code1
        _ ntolink                       ; lfa
        _begin find_code2
        _ fetch                         ; link
        _ dup
        _ zero?
        _if find_code_3
        _ false                         ; not found
        _ exit_
        _then find_code_3
        _ dup
        _ namefrom
        _ tocode
        _ rfetch
        _ equal
        _if find_code_4
        _ rfrom
        _ drop
        next
        _then find_code_4
        _ ntolink
        _again find_code2
        next
endcode

code read_time_stamp_counter, 'rdtsc'
        rdtsc
        pushd   rax
        pushd   rdx
        next
endcode

extern c_ticks

code ticks, 'ticks'
%ifdef WIN64
        push    rbp
        mov     rbp, [saved_rbp_data]
        sub     rsp, 32
%endif
        call    c_ticks
%ifdef WIN64
        add     rsp, 32
        pop     rbp
%endif
        pushd   rax
        next
endcode
