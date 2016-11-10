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

; ### current-vocab
value current_vocab, 'current-vocab', f_value

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
        _dup                            ; -- wid wid
        _ wordlist_name                 ; -- wid name
        _tuck                           ; -- name wid name
        _ new_vocab                     ; -- name wid vocab
        _tuck                           ; -- name vocab wid vocab
        _ vocab_set_wordlist            ; -- name vocab

        _ two_array
        _ vocabs
        _ vector_push
        next
endcode

; ### initialize-vocabs
code initialize_vocabs, 'initialize-vocabs'
        _lit 16
        _ new_vector_untagged
        _to vocabs

        _lit vocabs_data
        _ gc_add_root

        _ feline_wordlist
        _ add_vocab

        next
endcode

; ### hash-vocabs
code hash_vocabs, 'hash-vocabs'
%if 0
        _ vocabs
        _quotation .1
        _ array_second
        _ hash_vocab
        _end_quotation .1
        _ vector_each
%else
        _ last_symbol
        _begin .1
        _dup
        _while .1                       ; -- symbol

        _lit PRIMITIVE
        _over
        _ symbol_set_flags_bit

        _dup
        _ symbol_name
        _ force_hashcode
        _over
        _ symbol_vocab_name
        _ force_hashcode
        _ hash_combine
        _over
        _ symbol_set_hashcode

        _ dup
        _quote "feline"
        _ lookup_vocab
        _ vocab_add_symbol

        _cellminus
        _fetch
        _repeat .1

        _drop
%endif
        next
endcode

; ### all-words
code all_words, 'all-words'             ; -- seq
        _lit 2048
        _ new_vector_untagged
        _ vocabs
        _quotation .1
        _ array_second
        _ vocab_words
        _over
        _ vector_push_all
        _end_quotation .1
        _ each
        next
endcode

; ### lookup-vocab
code lookup_vocab, 'lookup-vocab'       ; vocab-spec -- vocab/f
        _dup
        _ vocab?
        _tagged_if .1
        _return
        _then .1

        _ verify_string
        _ vocabs
        _ vector_length
        _untag_fixnum
        _zero
        _?do .2
        _i
        _ vocabs
        _ vector_nth_untagged           ; -- string 2array
        _ array_first                   ; -- string string2
        _over
        _ stringequal
        _untag_fixnum
        _if .3
        ; found it
        _drop
        _i
        _ vocabs
        _ vector_nth_untagged
        _ array_second
        _unloop
        _return
        _then .3
        _loop .2
        _drop
        _f
        next
endcode

; ### ensure-vocab
code ensure_vocab, 'ensure-vocab'       ; string -- vocab
        _ verify_string
        _dup                            ; -- string string
        _ lookup_vocab                  ; -- string vocab/f
        _dup
        _tagged_if .1                   ; -- string vocab
        _nip                            ; -- vocab
        _else .1                        ; -- string f
        _drop
        _dup
        _ new_vocab                     ; -- string vocab
        _tuck
        _ two_array
        _ vocabs
        _ vector_push
        _then .1
        next
endcode

; ### IN:
code in_colon, 'IN:'
        _ parse_token                   ; -- string/f
        _dup
        _tagged_if .1
        _ ensure_vocab                  ;
        _to current_vocab
        _else .1
        _error "unexpected end of input"
        _then .1
        next
endcode

; ### in:
code in_colon_alias, 'in:'
        _ in_colon
        next
endcode

; ### USING:
code using_colon, 'USING:'
        _lit 10
        _ new_vector_untagged           ; -- handle
        _tor
        _begin .1
        _ parse_token                   ; -- string/f
        _dup
        _tagged_if_not .2
        _drop
        _error "unexpected end of input"
        _then .2
        _dup
        _quote ";"
        _ stringequal
        _untag_boolean
        _zeq
        _while .1
        _ lookup_vocab
        _dup
        _tagged_if_not .3
        _drop
        _error "can't find vocab"
        _then .3
        _rfetch
        _ vector_push
        _repeat .1
        _drop
        _rfrom
        _to context_vector
        next
endcode

; ### using:
code using_colon_alias, 'using:'
        _ using_colon
        next
endcode

; ### order
code order, 'order'
        _ ?nl
        _write "using: "
        _ context_vector
        _quotation .1
        _ vocab_name
        _ write_string
        _ space
        _end_quotation .1
        _ vector_each
        _write ";"
        _ nl
        _write "in: "
        _ current_vocab
        _ vocab_name
        _ write_string
        next
endcode
