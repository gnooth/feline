; Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

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

; ### vocabs
value vocabs, 'vocabs', 0

; ### wordlist-name
code wordlist_name, 'wordlist-name'     ; wid -- string
        _ wid_to_name
        _fetch                          ; -- nfa|0
        _?dup_if .1
        _count
        _ copy_to_string
        _else .1
        _f
        _then .1
        next
endcode

; ### add-vocab
code add_vocab, 'add-vocab'             ; wid --
        _dup
        _ wordlist_name
        _swap
        _ two_array
        _ vocabs
        _ vector_push
        next
endcode

; ### initialize-vocabs
code initialize_vocabs, 'initialize-vocabs'
        _lit 16
        _ new_vector
        _to vocabs

        _lit vocabs_data
        _ gc_add_root

        _from voclink                   ; -- wid
        _begin .1
        _dup
        _ add_vocab
        _ wid_to_link
        _fetch
        _dup
        _zeq
        _until .1
        _drop
        next
endcode

; ### lookup-vocab
code lookup_vocab, 'lookup-vocab'       ; string -- wid
        _ vocabs
        _ vector_length
        _untag_fixnum
        _zero
        _?do .1
        _i
        _ vocabs
        _ vector_nth_untagged           ; -- string 2array
        _ array_first                   ; -- string string2
        _over
        _ stringequal
        _untag_fixnum
        _if .2
        ; found it
        _drop
        _i
        _ vocabs
        _ vector_nth_untagged
        _ array_second
        _unloop
        _return
        _then .2
        _loop .1
        _drop
        _f
        next
endcode

; ### CURRENT:
code current_colon, 'CURRENT:'
        _ parse_name
        _ copy_to_string
        _ lookup_vocab
        _dup
        _f
        _equal
        _abortq "can't find vocab"      ; FIXME
        _ current
        _store
        next
endcode

; ### CONTEXT:
code context_colon, 'CONTEXT:'
        _lit 10
        _ new_vector_untagged           ; -- handle
        _tor
        _begin .2
        _ parse_name
        _twodup
        _squote ";"
        _ strequal
        _zeq
        _while .2
        _ copy_to_string
        _ lookup_vocab
        _dup
        _f
        _equal
        _abortq "can't find vocab"      ; FIXME
        _rfetch
        _ vector_push
        _repeat .2
        _2drop
        _rfrom
        _to context_vector
        next
endcode
