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

; ### current
; not in standard
variable current, 'current', forth_wid

; ### #vocs
; not in standard
constant nvocs, '#vocs', NVOCS          ; maximum number of word lists in search order

; ### #order
variable norder, '#order', 1

; ### context
; not in standard
variable context, 'context', forth_wid
section .data
        times NVOCS dq 0
        dq      0                       ; sentinel for FIND

; ### get-current
code get_current, 'get-current'         ; -- wid
; SEARCH
; Return the identifier of the compilation word list.
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

; ### voclink
variable voclink, 'voclink', files_wid

; ### wordlist
code wordlist, 'wordlist'               ; -- wid
; SEARCH
; "Create a new empty word list, returning its word list identifier wid."
        _ voclink
        _ fetch
        _ comma                         ; link
        _zero
        _ comma                         ; pointer to vocabulary name
        _ here                          ; this address will be the wid
        _ dup
        _ voclink
        _ store
        _zero
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

; ### .wid
code dotwid, '.wid'                     ; wid --
        _dup
        _if .1
        _dup                            ; -- wid wid
        _ widtoname                     ; -- wid wid-8
        _fetch                          ; -- wid nfa|0
        _ ?dup
        _if .2
        _nip
        _ dotid
        _else .2
        _ udot
        _then .2
        _else .1
        _ udot
        _then .1
        next
endcode

; ### vocs
code vocs, 'vocs'
        _ voclink
        _fetch
        _begin .1
        _dup
        _ dotwid
        _ widtolink
        _fetch
        _dup
        _zeq
        _until .1
        _drop
        next
endcode

section .data
        dq      0                       ; link
        dq      root_nfa
root_wid:
        dq      0

        dq      root_wid                ; link
        dq      forth_nfa
forth_wid:
        dq      0

        dq      forth_wid
        dq      files_nfa
files_wid:
        dq      0

; ### root-wordlist
code root_wordlist, 'root-wordlist'     ; -- wid
        pushrbx
        mov     rbx, root_wid
        next
endcode

; ### root
code root, 'root'
        mov     rax, root_wid
        mov     [context_data], rax
        next
endcode

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

; ### files-wordlist
code files_wordlist, 'files-wordlist'   ; -- wid
        pushrbx
        mov     rbx, files_wid
        next
endcode

; ### files
code files, 'files'
        mov     rax, files_wid
        mov     [context_data], rax
        next
endcode

; ### order
code order, 'order'
; SEARCH EXT
; FIXME
        _ ?cr
        _dotq "Context: "
        _ nvocs
        _zero
        _do .1
        _ context
        _i
        _cells
        _ plus
        _fetch                          ; -- wid
        _ ?dup
        _if .2
        _ dotwid
        _else .2
        _leave
        _then .2
        _loop .1
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
        _zero
        _?do .1
        _ norder
        _fetch
        _i
        _ minus
        _oneminus
        _cells
        _ context
        _ plus
        _ fetch
        _loop .1
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
        _zero
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
        _zero
        _?do .3
        _ context
        _i
        _cells
        _ plus
        _ store
        _loop .3
        next
endcode

; ### also
code also, 'also'
        _ get_order
        _ over
        _ swap
        _oneplus
        _ set_order
        next
endcode

; ### only
code only, 'only'
; SEARCH EXT
; "Set the search order to the implementation-defined minimum search order. The
; minimum search order shall include the words FORTH-WORDLIST and SET-ORDER."
        _ context
        _ nvocs
        _cells
        _ erase

;         _ forth_wordlist
;         _ context
;         _ store

;         _ root_wordlist
;         _ context
;         _cellplus
;         _ store
        _ root_wordlist
        _ context
        _ twodup
        _ store
        _cellplus
        _ store

        _lit 2
        _ norder
        _ store
        next
endcode

; ### previous
code previous, 'previous'
; SEARCH EXT
; "Transform the search order consisting of widn, ... wid2, wid1
; (where wid1 is searched first) into widn, ... wid2. An ambiguous
; condition exists if the search order was empty before PREVIOUS
; was executed."
        _ get_order                     ; -- widn ... wid1 n
        _ dup
        _lit 1
        _ gt
        _if .1
        _nip
        _ oneminus
        _ set_order
        _else .1
        _cquote "Search order underflow"
        _ msg
        _ store
        _lit -50	                ; "search-order underflow"
        _ throw
        _then .1
        next
endcode

; ### found
code found, 'found'                     ; nfa -- xt 1  | xt -1
        _namefrom                       ; -- xt
        _dup                            ; -- xt xt
        _ immediate?                    ; -- xt flag
        _if .1
        _lit 1                          ; -- xt 1
        _else .1
        _lit -1                         ; -- xt -1
        _then .1
        next
endcode

; ### search-wordlist
code search_wordlist, 'search-wordlist' ; c-addr u wid -- 0 | xt 1 | xt -1
; SEARCH
; "If the definition is not found, return 0. If the definition is found,
; return its execution token xt and 1 if the definition is immediate, -1
; otherwise."
        _fetch            ; last link in wordlist
        _dup
        _if .1
        _begin .2         ; -- c-addr u nfa
        _duptor           ; -- c-addr u nfa                       r: -- nfa
        _ count           ; -- c-addr u c-addr' u'                r: -- nfa
        _ twoover         ; -- c-addr u c-addr' u' c-addr-u       r: -- nfa
        _ istrequal       ; -- c-addr u flag                      r: -- nfa
        _if .3            ; -- c-addr u                           r: -- nfa
        ; found it!
        _2drop            ; --                                    r: -- nfa
        _rfrom            ; -- nfa
        _ found           ; -- xt 1 | xt -1
        _return
        _then .3          ; -- c-addr u                           r: -- nfa
        _rfrom            ; -- c-addr u nfa
        _ntolink          ; -- c-addr u lfa
        _fetch            ; -- c-addr u nfa
        _dup              ; -- c-addr u nfa nfa
        _zeq
        _until .2
        _then .1
        _3drop
        _ false
        next
endcode

section .data
find_arg:       dq      0
find_addr:      dq      0
find_len:       dq      0

; ### find
code find, 'find'                       ; $addr -- $addr 0 | xt 1 | xt -1
; CORE, SEARCH
; "Find the definition named in the counted string at c-addr. If the
; definition is not found, return c-addr and 0. If the definition is
; found, return its execution token xt. If the definition is immediate,
; also return 1, otherwise also return -1."
        mov     [find_arg], rbx
        _ count                         ; -- addr len
        mov     [find_len], rbx
        poprbx
        mov     [find_addr], rbx
        poprbx                          ; --
        _ nvocs
        _zero
        _do .1
        _ context
        _i
        _cells
        _plus
        _fetch                          ; -- wid
        _dup
        _zeq_if .2                      ; not found
        pushrbx
        mov     rbx, [find_arg]
        _ swap
        _unloop
        _return
        _then .2                        ; -- wid
        pushrbx
        mov     rbx, [find_addr]
        pushrbx
        mov     rbx, [find_len]         ; -- wid addr len
        _ rot
        _ search_wordlist
        _ ?dup
        _if .3                          ; -- xt n
        _unloop
        _return
        _then .3
        _loop .1
        next
endcode

; ### '
code tick, "'"
; CORE
        _ blword
        _ find
        _zeq_if .1
        _ missing
        _then .1
        next
endcode

; ### [']
code bracket_tick, "[']", IMMEDIATE
; CORE
; "Interpretation semantics for this word are undefined."
        _ ?comp
        _ flush_compilation_queue
        _ tick
        _ iliteral
        next
endcode

; ### have
code have, 'have'
        _ blword
        _ find
        _nip
        _ zne
        next
endcode
