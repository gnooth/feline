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

variable current, 'current', forth_wordlist_data

variable context, 'context', forth_wordlist_data

section .data
forth_wordlist_data:
        dq      0

code forth_wordlist, 'forth-wordlist'   ; -- wid
; SEARCH
        pushrbx
        mov     rbx, forth_wordlist_data
        next
endcode

code search_wordlist, 'search-wordlist' ; c-addr u wid -- 0 | xt 1 | xt -1
; SEARCH
        _ fetch                         ; last link in wordlist
        _begin sw1                      ; -- c-addr u nfa
        _duptor                         ; -- c-addr u nfa                       r: -- nfa
        _ count                         ; -- c-addr u c-addr' u'                r: -- nfa
        _ twoover                       ; -- c-addr u c-addr' u' c-addr-u       r: -- nfa
        _ istrequal                     ; -- c-addr u flag                      r: -- nfa
        _if sw2                         ; -- c-addr u                           r: -- nfa
        ; found it!
        _ twodrop                       ; --                                    r: -- nfa
        _ rfrom                         ; -- nfa
       _ found                         ; -- xt 1 | xt -1
        _return
        _then sw2                       ; -- c-addr u                           r: -- nfa
        _ rfrom                         ; -- c-addr u nfa
        _ ntolink                       ; -- c-addr u lfa
        _ fetch                         ; -- c-addr u nfa
        _ dup                           ; -- c-addr u nfa nfa
        _ zero?
        _until sw1
        _ threedrop
        _ false
        next
endcode

code find, 'find'                       ; c-addr -- c-addr 0  |  xt 1  |  xt -1
; CORE, SEARCH
        _duptor
        _ count
        _ context
        _ fetch
        _ search_wordlist
        _ dup
        _if find1
        _rfromdrop
        _else find1
        _ rfrom
        _ swap
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
        _ literal
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
