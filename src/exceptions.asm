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

; variable handler   0 handler !

; ### handler
variable handler, 'handler', 0

; : catch
;    sp@ >r
;    lp@ >r
;    handler @ >r
;    rp@ handler !
;    execute
;    r> handler !
;    r> drop
;    r> drop
;    0 ;

; ### catch
code catch, 'catch'
        _ spfetch
        _tor
        _ lpfetch
        _tor
        _ handler
        _fetch
        _tor
        _ rpfetch
        _ handler
        _store
        _ execute
        _rfrom
        _ handler
        _store
        lea     rsp, [rsp + BYTES_PER_CELL * 2] ; rdrop rdrop
        _zero
        next
endcode

; : throw
;    ?dup if
;       handler @ rp!
;       r> handler !
;       r> lp!
;       r> swap >r
;       sp! drop r>
;    then ;

; ### throw
code forth_throw, 'throw'
        test    rbx, rbx
        jnz .1
        poprbx
        _return
.1:
        _ save_backtrace
        _dup
        _ handler
        _fetch
        _ rpstore
        _rfrom
        _ handler
        _store
        _rfrom
        _ lpstore
        _rfrom
        _swap
        _tor
        _ spstore
        _drop
        _rfrom
        next
endcode

; ### ?throw
code ?throw, '?throw'                   ; flag n --
; Win32Forth
; throw n if flag is nonzero
        _swap
        _if .1
        _ forth_throw
        _else .1
        _drop
        _then .1
        next
endcode
