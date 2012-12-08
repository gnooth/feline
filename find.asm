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

code found, 'found'                     ; nfa -- xt 1  | xt -1
        _ namefrom                      ; -- xt
        _ dup                           ; -- xt xt
        _ immediate?                    ; -- xt flag
        _if found1
        _ one                           ; -- xt 1
        _else found1
        _ minusone                      ; -- xt -1
        _then found1
        next
endcode

code find, 'find'                       ; c-addr -- c-addr 0  |  xt 1  |  xt -1
        _ tor                           ; --                    r: -- c-addr
        _ latest                        ; -- nfa
        _begin find1
        _ dup                           ; -- nfa nfa
        _ rfetch                        ; -- nfa nfa c-addr
        _ match?
        _if find2                       ; -- nfa
        _ rfrom
        _ drop
        _ found
        next
        _then find2                     ; -- nfa
        _ ntolink                       ; -- lfa
        _fetch                          ; -- nfa
        _ dup                           ; -- nfa nfa
        _ zero?
        _until find1
        _ drop
        _ rfrom
        _ zero
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

code have, 'have'
        _ blchar
        _ word_
        _ find
        _nip
        _ zne
        next
endcode
