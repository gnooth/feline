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

; ### #vocs
; not in standard
constant nvocs, '#vocs', NVOCS          ; maximum number of word lists in search order

; ### get-current
code get_current, 'get-current'         ; -- wid
; SEARCH
; Return the identifier of the compilation word list.
        _ current_vocab
        _ vocab_wordlist
        next
endcode

; ### set-current
code set_current, 'set-current'         ; wid --
; SEARCH
        _ wid_to_name
        _ fetch
        _ count
        _ copy_to_string
        _ lookup_vocab
        _to current_vocab
        next
endcode

; ### definitions
code definitions, 'definitions'         ; --
; SEARCH
         _zero
         _ context_vector
         _ vector_nth_untagged
         _dup
         _ vocab?
         _tagged_if .1
         _ vocab_wordlist
         _then .1
         _ set_current
         next
endcode

; ### voclink
variable voclink, 'voclink', feline_wid

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
code wid_to_link, 'wid>link'
        sub     rbx, BYTES_PER_CELL * 2
        next
endcode

; ### wid>name
code wid_to_name, 'wid>name'
        sub     rbx, BYTES_PER_CELL
        next
endcode

; ### .wid
code dot_wid, '.wid'                    ; wid --
        _dup
        _if .1
        _dup                            ; -- wid wid
        _ wid_to_name                   ; -- wid wid-8
        _fetch                          ; -- wid nfa|0
        _?dup
        _if .2
        _nip
        _ dot_id
        _else .2
        _ udot
        _then .2
        _else .1
        _ udot
        _then .1
        next
endcode

; ### .voc
code dot_voc, '.voc'                    ; vocab-or-wid --
        _dup
        _ vocab?
        _tagged_if .1
        _ vocab_name
        _ dot_string
        _ forth_space
        _else .1
        _ dot_wid
        _then .1
        next
endcode

; ### vocs
code vocs, 'vocs'
        _from voclink
        _begin .1
        _dup
        _ dot_wid
        _ wid_to_link
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

; ### root-wordlist
code root_wordlist, 'root-wordlist'     ; -- wid
        pushrbx
        mov     rbx, root_wid
        next
endcode

; ### root
code root, 'root'
        _quote "root"
        _ lookup_vocab

        _dup
        _f
        _equal
        _abortq "no root vocab"

        _zero
        _ context_vector
        _ vector_set_nth_untagged
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
        _quote "forth"
        _ lookup_vocab

        _dup
        _tagged_if .1
        _zero
        _ context_vector
        _ vector_set_nth_untagged
        _else .1
        _drop
        _error "no forth vocab"
        _then .1
        next
endcode

; ### feline-wordlist
code feline_wordlist, 'feline-wordlist' ; -- wid
        pushrbx
        mov     rbx, feline_wid
        next
endcode

; ### feline
code feline, 'feline'                   ; --
        _quote "feline"
        _ lookup_vocab
        _dup
        _tagged_if .1
        _zero
        _ context_vector
        _ vector_set_nth_untagged
        _else .1
        _drop
        _error "no feline vocab"
        _then .1
        next
endcode

; ### context-vector
value context_vector, 'context-vector', 0

; ### order
code forth_order, 'order'
; SEARCH EXT
        _ ?cr
        _dotq "  Language: "
        _ dot_language
        _ cr
        _dotq "   Context: "
        _ context_vector
        _lit dot_voc_xt
        _ vector_each
        _dotq ";"
        _ cr
        _dotq "   Current: "
        _ current_vocab
        _ dot_voc
        next
endcode

; ### also
code also, 'also'
        _ context_vector
        _ vector_first
        _lit tagged_zero
        _ context_vector
        _ vector_insert_nth_destructive
        next
endcode

; ### only
code only, 'only'
; SEARCH EXT
; "Set the search order to the implementation-defined minimum search order. The
; minimum search order shall include the words FORTH-WORDLIST and SET-ORDER."
        _quote "root"
        _ lookup_vocab

        _dup
        _f
        _equal
        _abortq "no root vocab"

        _lit tagged_zero
        _ context_vector
        _ vector_set_length

        _ context_vector
        _ vector_push

        next
endcode

; ### previous
code previous, 'previous'
; SEARCH EXT
; "Transform the search order consisting of widn, ... wid2, wid1
; (where wid1 is searched first) into widn, ... wid2. An ambiguous
; condition exists if the search order was empty before PREVIOUS
; was executed."
        _ context_vector
        _ vector_length
        _untag_fixnum
        _lit 1
        _ gt
        _if .1
        _lit tagged_zero
        _ context_vector
        _ vector_remove_nth_destructive
        _else .1
        _quote "Search order underflow"
        _to msg
        _lit -50	                ; "search-order underflow"
        _ forth_throw
        _then .1
        next
endcode

; ### forth!
code set_forth_order, 'forth!'
        _ only
        _ feline
        _ also
        _ forth
        _ also
        _ definitions
        next
endcode

; ### feline!
code set_feline_order, 'feline!'
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
%ifdef STANDARD_FORTH
        _ isequal                       ; -- c-addr u flag                      r: -- nfa
%else
        _ memequal                      ; -- c-addr u flag                      r: -- nfa
%endif
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
        _ context_vector
        _ vector_length
        _untag_fixnum
        _zero
        _?do .1
        _dup
        _count
        _i
        _ context_vector
        _ vector_nth_untagged           ; -- vocab-or-wordlist

        _dup
        _ vocab?
        _tagged_if .2
        _ vocab_wordlist
        _then .2

        _ search_wordlist
        _dup_if .3
        _ rot
        _drop
        _unloop
        _return
        _then .3
        _drop
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
