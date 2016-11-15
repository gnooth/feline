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

; ### wid>name
code wid_to_name, 'wid>name'
        sub     rbx, BYTES_PER_CELL
        next
endcode

section .data
        dq      0                       ; link
        dq      feline_nfa
feline_wid:
        dq      0

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
