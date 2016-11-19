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

special accum, 'accum'

%macro _get_accum 0
        _ accum
        _ get
%endmacro

%macro _set_accum 0
        _ accum
        _ set
%endmacro

; ### maybe-add
code maybe_add, 'maybe-add'             ; x -- ???
        _get_accum
        _dup
        _tagged_if .1
        _ vector_push                   ; --
        _else .1
        _drop
        _then .1                        ; -- x
        next
endcode

special lexer, 'lexer'

; ### parse-token
code parse_token, 'parse-token'         ; -- string/f
        _ lexer
        _ get
        _dup
        _tagged_if .2
        _ lexer_parse_token
        _else .2
        _drop
        _error "no lexer"
        _then .2
        next
endcode

; ### t
code t, 't', SYMBOL_PARSING_WORD        ; -- t
        _t
        _ maybe_add
        next
endcode

; ### f
code f, 'f', SYMBOL_PARSING_WORD        ; -- f
        _f
        _ maybe_add
        next
endcode

; ### parsing-word?
code parsing_word?, 'parsing-word?'     ; object -- ?
        _dup
        _ symbol?
        _tagged_if .1
        _ symbol_parsing_word?
        _else .1
        _drop
        _f
        _then .1
        next
endcode

; ### process-token
code process_token, 'process-token'     ; string -- ???
        _ local_names
        _if .1
        _dup
        _ local_names                   ; -- string string vector
        _ vector_find_string            ; -- string index/f ?
        _tagged_if .2                   ; -- string index
        _nip
        _get_accum
        _ vector_push

        _lit S_local_fetch
        _get_accum
        _ vector_push

        _return
        _else .2                        ; -- string f
        _drop
        _then .2
        _then .1

        _ token_string_literal?
        _tagged_if .6
        _ maybe_add
        _return
        _then .6

        _ find_name                     ; -- symbol/string ?
        _tagged_if .3                   ; -- symbol
        _dup
        _ parsing_word?
        _tagged_if .4
        _ call_symbol
        _else .4
        _ maybe_add
        _then .4
        _return
        _then .3

        _ token_character_literal?
        _tagged_if .5
        _ maybe_add
        _return
        _then .5

        _dup
        _ string_to_number
        cmp     rbx, f_value
        je      .error
        _nip
        _ maybe_add
        _return

.error:
        _drop
        _ undefined

        next
endcode

; ### parse-until
code parse_until, 'parse-until'         ; delimiter -- vector
; REVIEW Delimiter is a string.

        _ begin_scope

        _lit 10
        _ new_vector_untagged
        _set_accum                      ; -- delimiter

.top:
        _ parse_token                   ; -- delimiter string/f
        cmp     rbx, f_value
        jne     .1
        _2drop
        _error "unexpected end of input"
.1:                                     ; -- delimiter string
        _twodup                         ; -- d s d s
        _ string_equal?                 ; -- d s ?
        cmp     rbx, f_value
        poprbx
        jne     .bottom
        _ process_token
        jmp     .top
.bottom:
        _2drop
        _get_accum                      ; -- vector

        _ end_scope

        next
endcode

; ### V{
code parse_vector, 'V{', SYMBOL_PARSING_WORD ; -- handle
        _quote "}"
        _ parse_until
        _ maybe_add
        next
endcode

; ### {
code parse_array, '{', SYMBOL_PARSING_WORD ; -- handle
        _quote "}"
        _ parse_until
        _ vector_to_array
        _ maybe_add
        next
endcode

; ### [
code parse_quotation, '[', SYMBOL_PARSING_WORD ; -- quotation
        _quote "]"
        _ parse_until
        _ vector_to_array
        _ array_to_quotation
        _ maybe_add
        next
endcode

; ### \
; We need some additional comment text here so that NASM isn't
; confused by the '\' in the explicit tag.
; "NASM uses backslash (\) as the line continuation character;
; if a line ends with backslash, the next line is considered to
; be a part of the backslash-ended line."
code quote_symbol, '\', SYMBOL_PARSING_WORD ; -- symbol
        _ parse_token
        _dup
        _tagged_if_not .1
        _error "unexpected end of input"
        _return
        _then .1

        _ find_name
        _tagged_if .2                   ; -- symbol
        _get_accum
        _dup
        _tagged_if .3
        _swap
        _ new_wrapper
        _swap
        _ vector_push                   ; --
        _else .3
        _drop
        _then .3                        ; -- symbol
        _else .2
        _ undefined
        _then .2

        next
endcode

; ### SYMBOL:
code parse_symbol, 'SYMBOL:', SYMBOL_PARSING_WORD ; --
        _ parse_token                   ; -- string/f
        _dup
        _tagged_if_not .1
        _drop
        _error "unexpected end of input"
        _return
        _then .1

        ; -- string
        _dup
        _ current_vocab
        _ vocab_hashtable
        _ at_star                       ; -- string value/f ?
        _tagged_if .2
        ; -- string symbol
        _2drop
        _return
        _then .2

        ; -- string f
        _drop
        _ current_vocab
        _ create_symbol

        _to_global last_word

        next
endcode

; ### global:
code parse_global, 'global:', SYMBOL_PARSING_WORD ;  --
        _ parse_token
        _dup
        _tagged_if_not .1
        _drop
        _error "unexpected end of input"
        _return
        _then .1
        _ ensure_global
        next
endcode

; ### parse-definition
code parse_definition, 'parse-definition' ; -- vector

        _ begin_scope

        _lit 10
        _ new_vector_untagged
        _set_accum
.top:
        _ parse_token                   ; -- string/f
        cmp     rbx, f_value
        jne     .1
        poprbx
        _error "unexpected end of input"
.1:                                     ; --  string
        _dup
        _quote ";"
        _ string_equal?
        _tagged_if .3
        _drop
        jmp     .bottom
        _then .3

        _ process_token

        jmp     .top

.bottom:
        _ using_locals?
        _if .5
        _lit S_locals_leave
        _get_accum
        _ vector_push
        _then .5

        _get_accum                          ; -- vector

        _ end_scope

        next
endcode

; ### :
code define, ':'                        ; --
        _zeroto using_locals?

        _ parse_token                   ; -- string/f
        _dup
        _tagged_if .1

        ; check for redefinition in current vocab only!
        _dup
        _ current_vocab
        _ vocab_hashtable
        _ at_star                       ; -- string symbol/f ?

        _tagged_if .2
        _nip
        ; REVIEW
        _ ?nl
        _quote "redefining "
        _ write_string
        _dup
        _ symbol_name
        _ write_string
        _else .2
        _drop                           ; -- string
        _ current_vocab
        _ new_symbol                    ; -- symbol
        _then .2                        ; -- symbol

        _dup
        _ set_last_word                 ; -- symbol

        _ parse_definition

        _ vector_to_array
        _ array_to_quotation            ; -- symbol quotation

        _over
        _ symbol_set_def                ; -- symbol
        _ compile_word

        _zeroto using_locals?
        _zeroto local_names

        _else .1
        _error "attempt to use zero-length string as a name"
        _then .1
        next
endcode

; ### //
code comment_to_eol, '//', SYMBOL_PARSING_WORD ; --
        _ lexer
        _ get
        _dup
        _tagged_if .1
        _ lexer_next_line
        _else .1
        _drop
        _error "no lexer"
        _then .1
        next
endcode

; ### --
code comment_to_eol2, '--', SYMBOL_PARSING_WORD ; --
        _ lexer
        _ get
        _dup
        _tagged_if .1
        _ lexer_next_line
        _else .1
        _drop
        _error "no lexer"
        _then .1
        next
endcode

; ### (
code feline_paren, '(', SYMBOL_PARSING_WORD
        _ lexer
        _ get
        _dup
        _tagged_if .1

        ; -- lexer
        _dup
        _ lexer_index
        _over
        _ lexer_string
        _lit tagged_char(')')
        _ rrot
        _ string_index_from             ; -- lexer index/f

        _dup
        _tagged_if .2
        ; found ')'
        _lit tagged_fixnum(1)
        _ fixnum_plus
        _swap
        _ lexer_set_index
        _else .2
        _drop
        _dup
        _ lexer_string
        _ string_length
        _swap
        _ lexer_set_index
        _then .2

        _return

        _else .1
        _drop
        _error "no lexer"
        _then .1

        next
endcode

; ### local:
code declare_local, 'local:', SYMBOL_PARSING_WORD

        _ using_locals?
        _zeq_if .2
        ; first local in this definition
        _ initialize_local_names
        _lit S_locals_enter
        _lit tagged_zero
        _get_accum
        _ vector_insert_nth_destructive
        _then .2

        ; FIXME verify that we're inside a named quotation

        _ parse_token                   ; -- string

        ; add name to quotation locals so it can be found
        ; assign index
        _ local_names
        _ vector_push

        next
endcode

; ### ->
code storeto, '->', SYMBOL_PARSING_WORD

        _ parse_token                   ; -- string

        _ local_names
        _if .1
        _dup
        _ local_names                   ; -- string string vector
        _ vector_find_string            ; -- string index/f ?
        _tagged_if .2                   ; -- string index
        _nip

        ; add index to quotation
        _get_accum
        _ vector_push

        ; add local! to quotation as a symbol
        _lit S_local_store
        _get_accum
        _ vector_push

        _return
        _else .2
        _drop
        _then .2

        _then .1

        ; not a local
        _ find_name

        _tagged_if_not .3
        _error "undefined symbol"
        _then .3

        _dup
        _ symbol_global?
        _tagged_if_not .4
        _error "not a global"
        _then .4

        _get_accum
        _tagged_if .5
        _ new_wrapper
        _get_accum
        _ vector_push
        _lit S_symbol_set_value
        _get_accum
        _ vector_push
        _else .5
        _ symbol_set_value
        _then .5

        next
endcode

; ### <<
code parse_immediate, '<<', SYMBOL_PARSING_WORD
        _quote ">>"
        _ parse_until
        _ vector_to_array
        _ array_to_quotation
        _ call_quotation

        ; FIXME
        _ maybe_add

        next
endcode

; ### HELP:
code parse_help, 'HELP:', SYMBOL_PARSING_WORD
        _ parse_token                   ; -- string/f
        _dup
        _tagged_if_not .1
        _drop
        _error "unexpected end of input after HELP:"
        _return
        _then .1                        ; -- string

        _ find_name
        _tagged_if_not .2
        _ undefined
        _return
        _then .2                        ; -- symbol

        _quote ";"
        _ parse_until
        _ vector_to_array               ; -- symbol array

        _swap
        _ symbol_set_help

        next
endcode

; ### LANGUAGE:
code parse_language, 'LANGUAGE:', SYMBOL_PARSING_WORD
; Deprecated.
        _ parse_token                   ; -- string/f
        ; Do nothing.
        _drop
        next
endcode

; ### sh
code sh, 'sh'
        _ lexer
        _ get
        _dup
        _tagged_if .1
        _dup
        _ lexer_line                    ; -- lexer string
        _over
        _ lexer_index                   ; -- lexer string index
        _ string_tail                   ; -- lexer tail

        _swap
        _ lexer_next_line

        _ string_data                   ; -- untagged-address

%ifdef WIN64
        popd    rcx
%else
        popd    rdi
%endif
        xcall   os_system

        _else .1
        _drop
        _error "no lexer"
        _then .1

        next
endcode
