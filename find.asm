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

; ### current
variable current, 'current', forth_wid

; ### #vocs
code nvocs, '#vocs'
        pushrbx
        mov     rbx, NVOCS
        next
endcode

; ### #order
variable norder, '#order', 1

; ### context
variable context, 'context', forth_wid
section .data
        times NVOCS dq 0
        dq      0                       ; sentinel for FIND

; ### get-current
code get_current, 'get-current'         ; -- wid
        pushrbx
        mov     rbx, [current_data]
        next
endcode

; ### set-current
code set_current, 'set-current'         ; wid --
        mov     [current_data], rbx
        poprbx
        next
endcode

; ### definitions
code definitions, 'definitions'         ; --
; SEARCH
        mov     eax, [context_data]
        mov     [current_data], eax
        next
endcode

; ### voc-link
variable voclink, 'voc-link', forth_wid

; ### wordlist
code wordlist, 'wordlist'               ; -- wid
; SEARCH
        _ voclink
        _ fetch
        _ comma                         ; link
        _ zero
        _ comma                         ; pointer to vocabulary name
        _ here
        _ dup
        _ voclink
        _ store
        _ zero
        _ comma                         ; link
        next
endcode

; ### wid>link
code widtolink, 'wid>link'
        sub     rbx, BYTES_PER_CELL * 2
        next
endcode

; ### wid>name
code widtoname, 'wid>name'
        sub     rbx, BYTES_PER_CELL
        next
endcode

; ### vocs
code vocs, 'vocs'
        _ voclink
        _ fetch
        _begin vocs1
        _ dup
        _ dotwid
        _ widtolink
        _ fetch
        _ dup
        _zeq
        _until vocs1
        _ drop
        next
endcode

section .data
        dq      0                       ; link
        dq      forth_nfa
forth_wid:
        dq      0

; ### forth-wordlist
code forth_wordlist, 'forth-wordlist'   ; -- wid
; SEARCH
        pushrbx
        mov     rbx, forth_wid
        next
endcode

; ### forth
code forth, 'forth'                     ; --
; SEARCH EXT
        mov     rax, forth_wid
        mov     [context_data], rax
        next
endcode

; ### .wid
code dotwid, '.wid'                     ; wid --
        _ dup
        _if dotwid1
        _ dup                           ; -- wid wid
        _ widtoname                     ; -- wid wid-8
        _fetch                          ; -- wid nfa|0
        _ ?dup
        _if dotwid2
        _ nip
        _ dotid
        _else dotwid2
        _ udot
        _then dotwid2
        _else dotwid1
        _ udot
        _then dotwid1
        next
endcode

; ### order
code order, 'order'
; SEARCH EXT
; FIXME
        _ ?cr
        _dotq "Context: "
        _ nvocs
        _ zero
        _do order1
        _ context
        _i
        _cells
        _ plus
        _fetch                          ; -- wid
        _ ?dup
        _if order2
        _ dotwid
        _else order2
        _ leave
        _then order2
        _loop order1
        _ cr
        _dotq "Current: "
        _ current
        _ fetch
        _ dotwid
        next
endcode

; ### get-order
code get_order, 'get-order'             ; -- widn ... wid1 n
; SEARCH
; "wid1 identifies the word list that is searched first, and widn the word list
; that is searched last."
        _ norder
        _fetch
        _ zero
        _?do get_order1
        _ norder
        _fetch
        _i
        _ minus
        _oneminus
        _cells
        _ context
        _ plus
        _ fetch
        _loop get_order1
        _ norder
        _ fetch
        next
endcode

; ### set-order
code set_order, 'set-order'             ; widn ... wid1 n --
; SEARCH
; "Set the search order to the word lists identified by widn ... wid1.
; Subsequently, word list wid1 will be searched first, and word list widn
; searched last."
        mov     rax, rbx
        poprbx
        test    rax, rax
        jnz     .1
        ; "If n is zero, empty the search order."
        _ context
        _ nvocs
        _cells
        _ erase
        _ zero
        _ norder
        _ store
        _return
.1:
        cmp     rax, -1
        jnz     .2
        ; "If n is minus one, set the search order to the implementation-
        ; defined minimum search order."
        _ only
        _return
.2:
        pushrbx
        mov     rbx, rax
        _ context
        _ nvocs
        _cells
        _ erase
        _ dup
        _ norder
        _ store
        _ zero
        _?do set_order1
        _ context
        _i
        _cells
        _ plus
        _ store
        _loop set_order1
        next
endcode

; ### also
code also, 'also'
        _ get_order
        _ over
        _ swap
        _ oneplus
        _ set_order
        next
endcode

; ### only
code only, 'only'
        _ context
        _ nvocs
        _cells
        _ erase
        _ forth                         ; FIXME
        _ one
        _ norder
        _ store
        next
endcode

; ### previous
code previous, 'previous'
        _ get_order
        _ nip
        _ oneminus
        _ set_order
        next
endcode

; ### found
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

; ### search-wordlist
code search_wordlist, 'search-wordlist' ; c-addr u wid -- 0 | xt 1 | xt -1
; SEARCH
        _ fetch                         ; last link in wordlist
        _ dup
        _if sw1
        _begin sw2                      ; -- c-addr u nfa
        _duptor                         ; -- c-addr u nfa                       r: -- nfa
        _ count                         ; -- c-addr u c-addr' u'                r: -- nfa
        _ twoover                       ; -- c-addr u c-addr' u' c-addr-u       r: -- nfa
        _ istrequal                     ; -- c-addr u flag                      r: -- nfa
        _if sw3                         ; -- c-addr u                           r: -- nfa
        ; found it!
        _ twodrop                       ; --                                    r: -- nfa
        _ rfrom                         ; -- nfa
       _ found                         ; -- xt 1 | xt -1
        _return
        _then sw3                       ; -- c-addr u                           r: -- nfa
        _ rfrom                         ; -- c-addr u nfa
        _ ntolink                       ; -- c-addr u lfa
        _ fetch                         ; -- c-addr u nfa
        _ dup                           ; -- c-addr u nfa nfa
        _zeq
        _until sw2
        _then sw1
        _ threedrop
        _ false
        next
endcode

section .data
find_arg:       dq      0
find_addr:      dq      0
find_len:       dq      0

; ### find
code find, 'find'                       ; c-addr -- c-addr 0  |  xt 1  |  xt -1
; CORE, SEARCH
        mov     [find_arg], rbx
        _ count                         ; -- addr len
        mov     [find_len], rbx
        poprbx
        mov     [find_addr], rbx
        poprbx                          ; --
        _ nvocs
        _ zero
        _do find1
        _ context
        _i
        _cells
        _ plus
        _ fetch                         ; -- wid
        _ dup
        _zeq
        _if find2                       ; not found
        pushrbx
        mov     rbx, [find_arg]
        _ swap
        _unloop
        _return
        _then find2                     ; -- wid
        pushrbx
        mov     rbx, [find_addr]
        pushrbx
        mov     rbx, [find_len]         ; -- wid addr len
        _ rot
        _ search_wordlist
        _ ?dup
        _if find3                       ; -- xt n
        _unloop
        _return
        _then find3
        _loop find1
        next
endcode

; ### '
code tick, "'"
        _ blchar
        _ word_
        _ find
        _zeq
        _if tick1
        _ count
        _ type
        _dotq ' ?'
        _ cr
        _ abort
        _then tick1
        next
endcode

; ### [']
code bracket_tick, "[']", IMMEDIATE
        _ tick
        _ literal
        next
endcode

; ### have
code have, 'have'
        _ blchar
        _ word_
        _ find
        _nip
        _ zne
        next
endcode
