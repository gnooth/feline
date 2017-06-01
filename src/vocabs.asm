; Copyright (C) 2016-2017 Peter Graves <gnooth@gmail.com>

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

; ### feline-vocab
feline_global feline_vocab, 'feline-vocab'

; ### user-vocab
feline_global user_vocab, 'user-vocab'

; ### dictionary
feline_global dictionary, 'dictionary'  ; -- hashtable

; ### context-vector
feline_global context_vector, 'context-vector'

; ### current-vocab
feline_global current_vocab, 'current-vocab'

; ### initialize-vocabs
code initialize_vocabs, 'initialize-vocabs'     ; --
        _quote "feline"
        _ new_vocab
        _to_global feline_vocab

        _quote "user"
        _ new_vocab
        _to_global user_vocab

        _lit 16
        _ new_vector_untagged
        _to_global context_vector

        _ feline_vocab
        _ context_vector
        _ vector_push

        _ feline_vocab
        _to_global current_vocab

        next
endcode

; ### hash-vocabs
code hash_vocabs, 'hash-vocabs'
        _ last_static_symbol
        _begin .1
        _dup
        _while .1                       ; -- symbol

        _lit SYMBOL_PRIMITIVE
        _over
        _ symbol_set_flags_bit

        _dup
        _ symbol_name
        _ string_hashcode
        _over
        _ symbol_vocab_name
        _ string_hashcode
        _ hash_combine
        _over
        _ symbol_set_hashcode

        _ dup
        _ feline_vocab
        _ vocab_add_symbol

        _cellminus
        _fetch
        _repeat .1

        _drop

        _lit 16
        _ new_hashtable_untagged
        _to_global dictionary

        _ feline_vocab
        _quote "feline"
        _ dictionary
        _ hashtable_set_at

        _ user_vocab
        _quote "user"
        _ dictionary
        _ hashtable_set_at

        next
endcode

; ### all-words
code all_words, 'all-words'             ; -- seq
        _lit 2048
        _ new_vector_untagged
        _ dictionary
        _ hashtable_values
        _quotation .1
        _ vocab_words
        _over
        _ vector_push_all
        _end_quotation .1
        _ each
        next
endcode

; ### apropos
code apropos, 'apropos'                 ; pattern --
        _ all_words
        _quotation .1
        _ symbol_name
        _over
        _swap
        _ substring_start
        _end_quotation .1
        _ filter
        _nip
        _quotation .2
        _ dot_object
        _ nl
        _end_quotation .2
        _ vector_each
        next
endcode

; ### ap
code ap, 'ap'                           ; --
        _ must_parse_token
        _ apropos
        next
endcode

; ### lookup-vocab
code lookup_vocab, 'lookup-vocab'       ; vocab-specifier -- vocab/f
        _dup
        _ vocab?
        _tagged_if .1
        _return
        _then .1

        _ verify_string

        _ dictionary
        _dup
        _tagged_if .2
        _ hashtable_at
        _return
        _else .2
        _drop
        _then .2

        ; We haven't created the dictionary yet.
        ; There is only the "feline" vocab.
        _quote "feline"
        _ stringequal
        _tagged_if .3
        _ feline_vocab
        _else .3
        _f
        _then .3

        next
endcode

; ### delete-vocab
code delete_vocab, 'delete-vocab'       ; vocab-specifier --
        _dup
        _ vocab?
        _tagged_if .1
        _ vocab_name
        _ dictionary
        _ delete_at
        _return
        _then .1

        _ verify_string

        _ dictionary
        _ delete_at

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
        _swap
        _ dictionary
        _ hashtable_set_at
        _then .1
        next
endcode

; ### in:
code in_colon, 'in:'
        _ must_parse_token              ; -- string/f
        _ ensure_vocab
        _to_global current_vocab
        next
endcode

; ### using-vocab?
code using_vocab?, 'using-vocab?'       ; vocab-specifier -- ?
        _ lookup_vocab
        _dup
        _tagged_if .1
        _ context_vector
        _ member_eq?
        _then .1
        next
endcode

; ### use-vocab
code use_vocab, 'use-vocab'             ; vocab-specifier --
        _dup
        _ using_vocab?
        _tagged_if .1
        _drop
        _return
        _then .1

        _ lookup_vocab
        _dup
        _tagged_if_not .2
        _drop
        _error "can't find vocab"
        _return
        _then .2

        _ context_vector
        _ vector_push
        next
endcode

; ### maybe-use-vocab
code maybe_use_vocab, 'maybe-use-vocab' ; vocab-specifier --
        _dup
        _ using_vocab?
        _tagged_if .1
        _drop
        _return
        _then .1

        _ lookup_vocab
        _dup
        _tagged_if .2
        _ context_vector
        _ vector_push
        _else .2
        _drop
        _then .2
        next
endcode

; ### use:
code use_colon, 'use:'
        _ must_parse_token
        _ use_vocab
        next
endcode

; ### unuse-vocab
code unuse_vocab, 'unuse-vocab'         ; vocab-specifier --
        _ lookup_vocab
        _dup
        _tagged_if_not .1
        _drop
        _return
        _then .1

        _ context_vector
        _ member_eq?                    ; -- index/f
        _dup
        _tagged_if_not .2
        _drop
        _return
        _then .2

        _ context_vector
        _ vector_remove_nth_mutating
        next
endcode

; ### unuse:
code unuse_colon, 'unuse:'
        _ must_parse_token              ; -- string
        _ unuse_vocab
        next
endcode

; ### using:
code using_colon, 'using:'
        _begin .1
        _ must_parse_token
        _dup
        _quote ";"
        _ stringequal
        _tagged_if .2
        _drop
        _return
        _then .2
        _ use_vocab
        _again .1
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
