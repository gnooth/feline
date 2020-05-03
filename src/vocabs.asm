; Copyright (C) 2016-2020 Peter Graves <gnooth@gmail.com>

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

asm_global feline_vocab_, f_value

; ### feline-vocab
code feline_vocab, 'feline-vocab'       ; -> vocab
        pushrbx
        mov     rbx, [feline_vocab_]
        next
endcode

asm_global user_vocab_, f_value

; ### user-vocab
code user_vocab, 'user-vocab'           ; -> vocab
        pushrbx
        mov     rbx, [user_vocab_]
        next
endcode

asm_global accessors_vocab_, f_value

; ### accessors-vocab
code accessors_vocab, 'accessors-vocab' ; -> vocab
        pushrbx
        mov     rbx, [accessors_vocab_]
        next
endcode

asm_global dictionary_, f_value

; ### dictionary
code dictionary, 'dictionary'           ; -> hashtable
        pushrbx
        mov     rbx, [dictionary_]
        next
endcode

asm_global context_vector_

; ### context-vector
code context_vector, 'context-vector', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; -- vector
        pushrbx
        mov     rbx, [context_vector_]
        next
endcode

asm_global current_vocab_, f_value

; ### current-vocab
code current_vocab, 'current-vocab'     ; -- vocab
        pushrbx
        mov     rbx, [current_vocab_]
        next
endcode

; ### set-current-vocab
code set_current_vocab, 'set-current-vocab'     ; vocab --
        _ verify_vocab
        mov     [current_vocab_], rbx
        poprbx
        next
endcode

; ### initialize_vocabs
code initialize_vocabs, 'initialize_vocabs', SYMBOL_INTERNAL    ; --

        _quote "feline"
        _ new_vocab
        mov     [feline_vocab_], rbx
        poprbx

        _lit feline_vocab_
        _ gc_add_root

        _quote "user"
        _ new_vocab
        mov     [user_vocab_], rbx
        poprbx

        _lit user_vocab_
        _ gc_add_root

        _quote "accessors"
        _ new_vocab
        mov     [accessors_vocab_], rbx
        poprbx

        _lit accessors_vocab_
        _ gc_add_root

        _lit 16
        _ new_vector_untagged
        mov     [context_vector_], rbx
        poprbx

        _lit context_vector_
        _ gc_add_root

        _ feline_vocab
        _ context_vector
        _ vector_push

        _ feline_vocab
        _ set_current_vocab

        next
endcode

; ### hash-vocabs
code hash_vocabs, 'hash-vocabs', SYMBOL_INTERNAL

        _ last_static_symbol
        _begin .1
        _dup
        _while .1                       ; -- symbol

        _dup
        _ symbol_set_primitive

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
        mov     [dictionary_], rbx
        poprbx
        _lit dictionary_
        _ gc_add_root

        _ feline_vocab
        _quote "feline"
        _ dictionary
        _ hashtable_set_at

        _ user_vocab
        _quote "user"
        _ dictionary
        _ hashtable_set_at

        _ accessors_vocab
        _quote "accessors"
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

; ### lookup-vocab
code lookup_vocab, 'lookup-vocab'       ; vocab-specifier -- vocab/f ?
        _dup
        _ vocab?
        _tagged_if .1
        _t
        _return
        _then .1

        _ verify_string

        _ dictionary
        _dup
        _tagged_if .2
        _ hashtable_at_star
        _return
        _else .2
        _drop
        _then .2

        ; We haven't created the dictionary yet.
        ; There is only the "feline" vocab.
        _quote "feline"
        _ stringequal?
        _tagged_if .3
        _ feline_vocab
        _t
        _else .3
        _f
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
        _ lookup_vocab                  ; -- string vocab/f ?
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
        _ set_current_vocab
        next
endcode

; ### empty
code empty, 'empty'                     ; --
        _ current_vocab
        _dup
        _ vocab_empty?
        _tagged_if .1
        _drop
        _else .1
        _ vocab_empty
        _then .1
        next
endcode

; ### using-vocab?
code using_vocab?, 'using-vocab?'       ; vocab-specifier -- ?
        _ lookup_vocab
        _tagged_if .1
        _ context_vector
        _ member_eq?
        _then .1
        next
endcode

; ### load-vocab
code load_vocab, 'load-vocab'           ; string -- vocab/f
        _dup                            ; -- string
        _ lookup_vocab
        _tagged_if .1
        _nip
        _return
        _then .1

        _drop                           ; -- string

        ; not loaded
        ; check Feline source directory first
        _dup
        _quote ".feline"
        _ string_append
        _dup
        _ feline_source_directory
        _swap
        _ path_append
        _ regular_file?
        _tagged_if .3
        _ load_system_file
        _else .3
        ; not a system file
        ; try the source path
        _ load
        _then .3

        _ lookup_vocab
        _drop

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

        _dup                            ; -- string
        _ lookup_vocab
        _tagged_if .2
        _nip
        _ context_vector
        _ vector_push
        _return
        _then .2

        _drop                           ; -- string

        _ load_vocab
        _dup

        _tagged_if .4
        _ context_vector
        _ vector_push
        _return
        _then .4

        _drop
        _error "can't find vocab"

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
code unuse_vocab, 'unuse-vocab'         ; vocab-specifier -> void
        _ lookup_vocab
        _tagged_if_not .1
        _drop
        _return
        _then .1

        _ context_vector
        _ index                         ; -> index/f
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

        _lit 16
        _ new_vector_untagged

        _begin .1
        _ must_parse_token
        _dup
        _quote ";"
        _ stringequal?
        _ not
        _tagged_while .1
        _over
        _ vector_push
        _repeat .1

        _drop                           ; -- vector

        ; Verify that we can load all of the specified vocabs before we touch
        ; the context vector.
        _lit S_load_vocab
        _ map

        _lit tagged_zero
        _ context_vector
        _ vector_set_length

        _lit S_use_vocab
        _ vector_each

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
