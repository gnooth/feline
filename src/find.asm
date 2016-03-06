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
; SEARCH
        mov     [current_data], rbx
        poprbx
        next
endcode

; ### definitions
code definitions, 'definitions'         ; --
; SEARCH
        mov     rax, [context_data]
        mov     [current_data], rax
        next
endcode

; ### voclink
variable voclink, 'voclink', files_wid

; ### wordlist
code wordlist, 'wordlist'               ; -- wid
; SEARCH
; "Create a new empty word list, returning its word list identifier wid."
        _from voclink
        _ comma                         ; link
        _zero
        _ comma                         ; pointer to vocabulary name
        _ here                          ; this address will be the wid
        _dup
        _to voclink
        _zero
        _ comma                         ; pointer to name field of last word in this wordlist
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
        _?dup
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
        _from voclink
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

        dq      forth_wid               ; link
        dq      feline_nfa
feline_wid:
        dq      0

        dq      feline_wid              ; link
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

; ### feline-wordlist
code feline_wordlist, 'feline-wordlist' ; -- wid
; SEARCH
        pushrbx
        mov     rbx, feline_wid
        next
endcode

; ### feline
code feline, 'feline'                   ; --
; SEARCH EXT
        mov     rax, feline_wid
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
        _plus
        _fetch                          ; -- wid
        _?dup
        _if .2
        _ dotwid
        _else .2
        _leave
        _then .2
        _loop .1
        _ cr
        _dotq "Current: "
        _ current
        _fetch
        _ dotwid
        next
endcode

; ### get-order
code get_order, 'get-order'             ; -- widn ... wid1 n
; SEARCH
; "wid1 identifies the word list that is searched first, and widn the word list
; that is searched last."
        _from norder
        _zero
        _?do .1
        _from norder
        _i
        _minus
        _oneminus
        _cells
        _ context
        _plus
        _fetch
        _loop .1
        _from norder
        next
endcode

; ### set-order
code set_order, 'set-order'             ; widn ... wid1 n --
; SEARCH
; "Set the search order to the word lists identified by widn ... wid1.
; Subsequently, word list wid1 will be searched first, and word list widn
; searched last."
        _dup
        _zeq_if .1
        ; "If n is zero, empty the search order."
        _drop
        _ context
        _ nvocs
        _cells
        _ erase
        _zeroto norder
        _return
        _then .1

        _dup
        _lit -1
        _equal
        _if .2
        ; "If n is minus one, set the search order to the implementation-
        ; defined minimum search order."
        _drop
        _ only
        _return
        _then .2

        _dup
        _ nvocs
        _ ugt
        _if .0
        _cquote "Search-order overflow"
        _to msg
        _lit -49
        _ throw
        _then .0

        _ context
        _ nvocs
        _cells
        _ erase
        _dup
        _to norder
        _zero
        _?do .3
        _ context
        _i
        _cells
        _plus
        _ store
        _loop .3
        next
endcode

; ### also
code also, 'also'
        _ get_order
        _overswap
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
        _twodup
        _ store
        _cellplus
        _ store

        _lit 2
        _to norder
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
        _dup
        _lit 1
        _ gt
        _if .1
        _nip
        _oneminus
        _ set_order
        _else .1
        _cquote "Search order underflow"
        _to msg
        _lit -50	                ; "search-order underflow"
        _ throw
        _then .1
        next
endcode

; ### forth!
code forth_order, 'forth!'
        _ only
        _ feline
        _ also
        _ forth
        _ also
        _ definitions
        next
endcode

; ### feline!
code feline_order, 'feline!'
        _ only
        _ forth
        _ also
        _ feline
        _ also
        _ definitions
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
        _fetch                          ; last link in wordlist
        _dup
        _if .1
        _begin .2                       ; -- c-addr u nfa
        _duptor                         ; -- c-addr u nfa                       r: -- nfa
        ; do lengths match?
        _cfetch                         ; -- c-addr u len                       r: -- nfa
        _over                           ; -- c-addr u len u                     r: -- nfa
        _equal                          ; -- c-addr u flag                      r: -- nfa
        _if .3
        ; lengths match
        _twodup                         ; -- c-addr u c-addr u
        _rfetch                         ; -- c-addr u c-addr u nfa
        _oneplus                        ; -- c-addr u c-addr u nfa+1
        _swap                           ; -- c-addr u c-addr nfa+1 u
        _ isequal                       ; -- c-addr u flag                      r: -- nfa
        _if .4                          ; -- c-addr u                           r: -- nfa
        ; found it!
        _2drop                          ; --                                    r: -- nfa
        _rfrom                          ; -- nfa
        _ found                         ; -- xt 1 | xt -1
        _return
        _then .4                        ; -- c-addr u                           r: -- nfa
        _then .3
        _rfrom                          ; -- c-addr u nfa
        _name_to_link                   ; -- c-addr u lfa
        _fetch                          ; -- c-addr u nfa
        _dup                            ; -- c-addr u nfa nfa
        _zeq
        _until .2
        _then .1
        _3drop
        _false
        next
endcode

; ### find
code find, 'find'                       ; $addr -- $addr 0 | xt 1 | xt -1
; CORE, SEARCH
; "Find the definition named in the counted string at c-addr. If the
; definition is not found, return c-addr and 0. If the definition is
; found, return its execution token xt. If the definition is immediate,
; also return 1, otherwise also return -1."
        _ nvocs
        _zero
        _do .1
        _dup                            ; -- $addr $addr
        _count                          ; -- $addr c-addr u
        _ context
        _i
        _cells
        _plus
        _fetch                          ; -- $addr c-addr u wid
        _dup_if .2
        _ search_wordlist
        _dup_if .3                      ; -- $addr xt flag
        _ rot
        _drop
        _unloop
        _return
        _then .3
        _drop
        _else .2
        ; wid = 0, reached end of search order
        _3drop
        _leave
        _then .2
        _loop .1
        _false
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
