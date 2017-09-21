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

; ### reload-file
feline_global reload_file, 'reload-file'

; ### maybe-set-reload-file
code maybe_set_reload_file, 'maybe-set-reload-file'     ; path --
        _ reload_file
        _tagged_if_not .1
        _to_global reload_file
        _else .1
        _drop
        _then .1
        next
endcode

; ### reload
code reload, 'reload'   ; --
        _ reload_file
        _dup
        _tagged_if .1
        _ load
        _else .1
        _drop
        _write "nothing to reload"
        _then .1
        next
endcode

; ### r
code interactive_reload, 'r', SYMBOL_IMMEDIATE  ; --
        _ interactive?
        _ get
        _tagged_if .1
        _ reload
        _else .1
        _error "interactive only"
        _then .1
        next
endcode

; ### saved-current-vocab
special saved_current_vocab, 'saved-current-vocab'

; ### saved-context-vector
special saved_context_vector, 'saved-context-vector'

; ### save-search-order
code save_search_order, 'save-search-order'
        _ current_vocab
        _ vocab_name
        _ saved_current_vocab
        _ set

        _ context_vector
        _lit S_vocab_name
        _ map
        _ saved_context_vector
        _ set

        next
endcode

; ### restore-search-order
code restore_search_order, 'restore-search-order'
        _ saved_current_vocab
        _ get
        _ lookup_vocab
        _tagged_if_not .1
        _drop
        _ user_vocab
        _then .1
        _ set_current_vocab

        _lit tagged_zero
        _ context_vector
        _ vector_set_length

        _ saved_context_vector
        _ get
        _lit S_maybe_use_vocab
        _ each

        _ context_vector
        _ vector_length
        _ zero?
        _tagged_if .2
        _ feline_vocab
        _ use_vocab
        _then .2

        next
endcode

special default_visibility, 'default-visibility'

; ### private
code private, 'private'                         ; --
        _lit S_private
        _ default_visibility
        _ set
        next
endcode

; ### public
code public, 'public'                           ; --
        _lit S_public
        _ default_visibility
        _ set
        next
endcode

; ### feline-extension
code feline_extension, 'feline-extension'       ; -- string
        _quote ".feline"
        next
endcode

; ### ensure-feline-extension
code ensure_feline_extension, 'ensure-feline-extension'        ; path -- path
        _dup
        _ path_extension
        _ feline_extension
        _ string_equal?
        _tagged_if_not .1
        _ feline_extension
        _ concat
        _then .1
        next
endcode

; ### load
code load, 'load'                       ; path --
        _ ensure_feline_extension
        _ canonical_path
        _dup
        _ file_contents
        _ new_lexer
        _tuck
        _ lexer_set_file                ; -- lexer

        _ begin_scope

        _ lexer
        _ set                           ; --

        _lit S_public
        _ default_visibility
        _ set

        _ load_verbose?
        _ get
        _tagged_if .1
        _ ?nl
        _write "Loading "
        _ lexer
        _ get
        _ lexer_file
        _ write_string
        _ nl
        _then .1

        _ interactive?
        _ get
        _tagged_if .2
        _ lexer
        _ get
        _ lexer_file
        _ maybe_set_reload_file
        _then .2

        _f
        _ interactive?
        _ set

        _ save_search_order

        _lit S_interpret                ; try
        _quotation .3                   ; recover
        _ do_error1
        _ restore_search_order
        _ reset
        _end_quotation .3
        _ recover

        ; no error
        _ restore_search_order

        _ end_scope

        next
endcode

; ### load-system-file
code load_system_file, 'load-system-file'       ; filename --
        _ feline_home
        _quote "src"
        _ path_append
        _swap
        _ path_append
        _ load
        next
endcode

; ### l
code interactive_load, 'l', SYMBOL_IMMEDIATE    ; --
        _ interactive?
        _ get
        _tagged_if .1
        _ must_parse_token      ; -- string
        _quote ".feline"
        _ concat
        _ load
        _else .1
        _error "interactive only"
        _then .1
        next
endcode
