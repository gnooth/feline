; Copyright (C) 2016-2019 Peter Graves <gnooth@gmail.com>

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
code ensure_feline_extension, 'ensure-feline-extension'         ; path -- path
        _ feline_extension
        _over
        _ string_has_suffix?
        _tagged_if_not .1
        _ feline_extension
        _ string_append
        _then .1
        next
endcode

asm_global source_path_, f_value

; ### source-path
code source_path, 'source-path'         ; -- vector
        pushrbx
        mov     rbx, [source_path_]
        next
endcode

; ### initialize_source_path
code initialize_source_path, 'initialize_source_path', SYMBOL_INTERNAL  ; --
        _lit 8
        _ new_vector_untagged
        mov     [source_path_], rbx
        poprbx
        _lit source_path_
        _ gc_add_root

        _ feline_source_directory
        _ add_source_directory

        _ feline_home
        _quote "feral"
        _ path_append
        _ add_source_directory

        _ feline_home
        _quote "examples"
        _ path_append
        _ add_source_directory

        _ feline_home
        _quote "benchmarks"
        _ path_append
        _ add_source_directory

        next
endcode

; ### add-source-directory
code add_source_directory, 'add-source-directory'       ; path --
        _ verify_string

        _dup
        _ source_path
        _ member?
        _tagged_if .1
        _drop
        _else .1
        _ source_path
        _ vector_push
        _then .1
        next
endcode

; ### find-file-in-source-path
code find_file_in_source_path, 'find-file-in-source-path'       ; string -- path

        _ source_path
        _quotation .1
        _ over
        _ path_append
        _ regular_file?
        _end_quotation .1
        _ map_find                      ; -- string boolean directory

        _swap
        _tagged_if .2
        _swap
        _ path_append
        _ canonical_path
        _else .2
        _2drop
        _f
        _then .2

        next
endcode

; ### find-file
code find_file, 'find-file'             ; string -> path/f

        _duptor

        _dup
        _ file_name_absolute?
        _tagged_if .1
        _ canonical_path
        _rdrop
        _return
        _then .1

        _dup
        _ canonical_path

        ; canonical-path might return f
        _dup
        _tagged_if .2

        _dup
        _ regular_file?
        _tagged_if .3
        _nip
        _rdrop
        _return
        _then .3

        _then .2

        _2drop

        _rfrom                          ; -- string

        _ find_file_in_source_path

        next
endcode

; ### load
code load, 'load'                       ; string --

        _ ensure_feline_extension

        _dup
        _ find_file
        _dup
        _tagged_if_not .1
        _drop
        _ error_file_not_found
        _else .1
        _nip
        _then .1

        _dup
        _ file_contents
        _ new_lexer
        _tuck
        _ lexer_set_file                ; -- lexer

        _ begin_dynamic_scope

        _ current_lexer
        _ set                           ; --

        _lit S_public
        _ default_visibility
        _ set

        _ load_verbose?
        _ get
        _tagged_if .2
        _ ?nl
        _write "Loading "
        _ current_lexer
        _ get
        _ lexer_file
        _ write_string
        _ nl
        _then .2

        _ interactive?
        _ get
        _tagged_if .3
        _ current_lexer
        _ get
        _ lexer_file
        _ maybe_set_reload_file
        _then .3

        _f
        _ interactive?
        _ set

        _ save_search_order

        _lit S_interpret                ; try
        _quotation .4                   ; recover
        _ do_error1
        _ restore_search_order
        _ reset
        _end_quotation .4
        _ recover

        ; no error
        _ restore_search_order

        _ end_dynamic_scope

        next
endcode

; ### load-system-file
code load_system_file, 'load-system-file'       ; filename --
        _ feline_source_directory
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
        _ ensure_feline_extension
        _ load
        _else .1
        _error "interactive only"
        _then .1
        next
endcode
