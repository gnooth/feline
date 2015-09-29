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

; variable handler   0 handler !

; : catch
;    sp@ >r
;    handler @ >r
;    rp@ handler !
;    execute
;    r> handler !
;    r> drop
;    0 ;

; : throw
;    ?dup if
;       handler @ rp!
;       r> handler !
;       r> swap >r
;       sp! drop r>
;    then ;

; ### handler
variable handler, 'handler', 0

; ### catch
code catch, 'catch'
        _ spfetch
        _ tor
        _ handler
        _ fetch
        _ tor
        _ rpfetch
        _ handler
        _ store
        _ execute
        _ rfrom
        _ handler
        _ store
        _ rfrom
        _ drop
        _zero
        next
endcode

; ### throw
code throw, 'throw'
        _ ?dup
        _if throw1
        _ handler
        _ fetch
        _ rpstore
        _ rfrom
        _ handler
        _ store
        _ rfrom
        _ swap
        _ tor
        _ spstore
        _ drop
        _ rfrom
        _then throw1
        next
endcode

; ### ?throw
code ?throw, '?throw'                   ; flag n --
; Win32Forth
; throw n if flag is nonzero
        _ swap
        _if .1
        _ throw
        _else .1
        _drop
        _then .1
        next
endcode
