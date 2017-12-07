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

special in_definition?, 'in-definition?'

special accum, 'accum'

%macro _get_accum 0
        _ accum
        _ get
%endmacro

%macro _set_accum 0
        _ accum
        _ set
%endmacro

; ### add-to-definition
code add_to_definition, 'add-to-definition'     ; x --
        _get_accum
        _ vector_push
        next
endcode

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

special current_lexer, 'current-lexer'

; ### parse-token
code parse_token, 'parse-token'         ; -- string/f
        _ current_lexer
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

; ### must-parse-token
code must_parse_token, 'must-parse-token'       ; -- string
        _ parse_token
        _dup
        _tagged_if_not .1
        _drop
        _error "unexpected end of input"
        _then .1
        next
endcode

; ### t
code t, 't', SYMBOL_IMMEDIATE   ; -- t
        _t
        _ maybe_add
        next
endcode

; ### f
code f, 'f', SYMBOL_IMMEDIATE   ; -- f
        _f
        _ maybe_add
        next
endcode

; ### immediate?
code immediate?, 'immediate?'   ; object -- ?
        _dup
        _ symbol?
        _tagged_if .1
        _ symbol_immediate?
        _else .1
        _drop
        _f
        _then .1
        next
endcode

; ### process_local_fetch
code process_local_fetch, 'process_local_fetch', SYMBOL_INTERNAL        ; tagged-index --
        _dup
        _lit tagged_zero
        _eq?
        _tagged_if .1
        _drop
        _lit S_local_0_fetch
        _get_accum
        _ vector_push
        _return
        _then .1

        _dup
        _tagged_fixnum 1
        _eq?
        _tagged_if .2
        _drop
        _lit S_local_1_fetch
        _get_accum
        _ vector_push
        _return
        _then .2

        ; push index
        _get_accum
        _ vector_push                   ; --

        ; push local@
        _lit S_local_fetch
        _get_accum
        _ vector_push

        next
endcode

; ### process-token
code process_token, 'process-token'     ; string -- ???
        _ local_names
        _tagged_if .1
        _dup
        _ local_names                   ; -- string string vector
        _ vector_find_string            ; -- string index/f ?
        _tagged_if .2                   ; -- string index
        _nip
        _ process_local_fetch
        _return
        _else .2                        ; -- string f
        _drop
        _then .2
        _then .1

        _ token_string_literal?
        _tagged_if .3
        _ maybe_add
        _return
        _then .3

        _ find_name                     ; -- symbol/string ?
        _tagged_if .4                   ; -- symbol
        _dup
        _ symbol_immediate?
        _tagged_if .5
        _ call_symbol
        _else .5
        _ maybe_add
        _then .5
        _return
        _then .4

        _ token_character_literal?
        _tagged_if .6
        _ maybe_add
        _return
        _then .6

        _ token_keyword?
        _tagged_if .7
        _ maybe_add
        _return
        _then .7

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

        _ begin_dynamic_scope

        _t
        _ in_definition?
        _ set

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

        _ end_dynamic_scope

        next
endcode

; ### vector{
code parse_vector, 'vector{', SYMBOL_IMMEDIATE  ; -- handle
        _quote "}"
        _ parse_until
        _ maybe_add
        next
endcode

; ### {
code parse_array, '{', SYMBOL_IMMEDIATE         ; -- handle
        _quote "}"
        _ parse_until
        _ vector_to_array
        _ maybe_add
        next
endcode

; ### }
code rbrace, '}', SYMBOL_IMMEDIATE              ; --
        _ error_unexpected_delimiter
        next
endcode

; ### [
code parse_quotation, '[', SYMBOL_IMMEDIATE     ; -- quotation
        _quote "]"
        _ parse_until
        _ vector_to_array
        _ array_to_quotation
        _ maybe_add
        next
endcode

; ### ]
code rbracket, ']', SYMBOL_IMMEDIATE            ; --
        _ error_unexpected_delimiter
        next
endcode

; ### '
code tick, "'", SYMBOL_IMMEDIATE        ; symbol
        _ must_parse_token
        _ must_find_name
        _get_accum
        _dup
        _tagged_if .1
        _swap
        _ new_wrapper
        _swap
        _ vector_push
        _else .1
        _drop
        _then .1
        next
endcode

; ### postpone:
code postpone, 'postpone:', SYMBOL_IMMEDIATE
        _ must_parse_token
        _ must_find_name
        _get_accum
        _dup
        _tagged_if .1
        _ vector_push
        _else .1
        _drop
        _then .1
        next
endcode

; ### symbol:
code parse_symbol, 'symbol:', SYMBOL_IMMEDIATE  ; --
        _ must_parse_token              ; -- string
        _ new_symbol_in_current_vocab   ; -- symbol
        _dup
        _ new_wrapper
        _ one_quotation
        _over
        _ symbol_set_def                ; -- handle
        _ compile_word
        next
endcode

; ### special:
code parse_special, 'special:', SYMBOL_IMMEDIATE        ; --
        _ must_parse_token              ; -- string
        _ new_symbol_in_current_vocab   ; -- symbol

        _dup
        _ symbol_set_special_bit

        _dup
        _ new_wrapper
        _ one_quotation
        _over
        _ symbol_set_def                ; -- handle
        _ compile_word
        next
endcode

; ### note-redefinition
code note_redefinition, 'note_redefinition'     ; symbol --
        _ ?nl
        _dup
        _ symbol_vocab_name
        _swap
        _ symbol_name
        _quote "NOTE: redefining %s:%s"
        _ format
        _ comment_style
        _ print
        _ output_style
        _ location
        _dup
        _tagged_if .1
        _ print_location
        _else .1
        _drop
        _then .1
        next
endcode

; ### maybe-note-redefinition
code maybe_note_redefinition, 'maybe-note-redefinition' ; string --
        _ current_vocab
        _ vocab_hashtable
        _ hashtable_at_star             ; -- symbol/f ?
        _tagged_if .1
        _ note_redefinition
        _else .1
        _drop
        _then .1
        next
endcode

; ### new-symbol-in-current-vocab
code new_symbol_in_current_vocab, 'new-symbol-in-current-vocab', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; string -- symbol
        _dup
        _ maybe_note_redefinition
        _ current_vocab
        _ new_symbol
        next
endcode

; ### parse-definition-name
code parse_definition_name, 'parse-definition-name'     ; -- symbol

        _ must_parse_token              ; -- string
        _ new_symbol_in_current_vocab   ; -- symbol

        _ location                      ; -- symbol 3array/f
        _dup
        _tagged_if .3                   ; -- symbol 3array
        _dup
        _ array_first
        _swap
        _ array_second                  ; -- symbol file line-number
        _pick
        _ symbol_set_location
        _else .3
        _drop
        _then .3                        ; -- symbol

        _dup
        _ set_last_word                 ; -- symbol

        next
endcode

; ### parse-definition
code parse_definition, 'parse-definition'       ; -- vector

        _zeroto using_locals?

        _ begin_dynamic_scope

        _t
        _ in_definition?
        _ set

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

        _get_accum                      ; -- vector

        _ end_dynamic_scope

        _zeroto using_locals?

        _f
        _to_global local_names

        next
endcode

; ### :
code colon, ':', SYMBOL_IMMEDIATE       ; --

        _lit S_colon
        _ top_level_only

        _ parse_definition_name         ; -- symbol
        _ parse_definition              ; -- symbol vector
        _ vector_to_array
        _ array_to_quotation            ; -- symbol quotation
        _over
        _ symbol_set_def                ; -- symbol
        _ compile_word
        next
endcode

; ### private:
code private_colon, 'private:', SYMBOL_IMMEDIATE        ; --
        _lit S_private_colon
        _ top_level_only

        _ colon
        _ last_word
        _ symbol_set_private
        next
endcode

; ### public:
code public_colon, 'public:', SYMBOL_IMMEDIATE          ; --
        _lit S_public_colon
        _ top_level_only

        _ colon
        _ last_word
        _ symbol_set_public
        next
endcode

; ### ;
code semi, ';', SYMBOL_IMMEDIATE        ; --
        _ error_unexpected_delimiter
        next
endcode

; ### immediate
code immediate, 'immediate'             ; --
        _ last_word
        _ symbol_set_immediate
        next
endcode

; ### syntax:
code syntax, 'syntax:', SYMBOL_IMMEDIATE
        _ colon
        _ immediate
        next
endcode

; ### test:
code define_test, 'test:'               ; --
        _ parse_definition_name         ; -- symbol
        _ parse_definition              ; -- symbol vector

        _lit S_?nl
        _lit tagged_zero
        _pick
        _ vector_insert_nth

        _over
        _ symbol_name
        _lit tagged_fixnum(1)
        _pick
        _ vector_insert_nth

        _lit S_write_string
        _lit tagged_fixnum(2)
        _pick
        _ vector_insert_nth

        _ vector_to_array
        _ array_to_quotation            ; -- symbol quotation
        _over
        _ symbol_set_def                ; -- symbol
        _ compile_word
        next
endcode

; ### generic:
code define_generic, 'generic:', SYMBOL_IMMEDIATE       ; --
        _ parse_definition_name         ; -- symbol

        _dup
        _ initialize_generic_function   ; -- symbol

        _dup
        _ new_wrapper
        _lit S_symbol_value
        _lit S_do_generic
        _ three_array
        _ array_to_quotation
        _over
        _ symbol_set_def                ; -- symbol

        _dup
        _ symbol_set_generic

        _ compile_word                  ; --

        next
endcode

; ### method:
code method_colon, 'method:', SYMBOL_IMMEDIATE  ; --

        _lit S_method_colon
        _ top_level_only

        _ must_parse_token              ; -- string
        _ must_find_name                ; -- symbol
        _ call_symbol                   ; -- class

        _dup
        _ tuple_class?
        _tagged_if .1
        _ tuple_class_typecode
        _else .1
        _ type_typecode                 ; -- tagged-typecode
        _then .1

        _ must_parse_token              ; -- typecode string
        _ find_name                     ; -- typecode symbol/string ?
        _tagged_if_not .2
        _error "can't find generic word"
        _return
        _then .2                        ; -- typecode generic-symbol

        _dup
        _ generic?
        _tagged_if_not .3
        _error "not a generic word"
        _return
        _then .3

        _ parse_definition              ; -- typecode generic-symbol vector
        _ vector_to_array
        _ array_to_quotation            ; -- typecode generic-symbol quotation
        _ compile_quotation             ; -- typecode generic-symbol quotation
        _ quotation_raw_code_address    ; -- typecode generic-symbol raw-code-address

        _ rrot
        _ add_method_to_dispatch_table  ; --

        next
endcode

; ### --
code comment_to_eol, '--', SYMBOL_IMMEDIATE     ; --
        _ current_lexer
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
code feline_paren, '(', SYMBOL_IMMEDIATE        ; --
        _ current_lexer
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

; ### return-if
code return_if, 'return-if', SYMBOL_IMMEDIATE
        _ using_locals?
        _if .1
        _lit S_return_if_locals
        _else .1
        _lit S_return_if_no_locals
        _then .1
        _get_accum
        _ vector_push
        next
endcode

; ### declare-local-internal
code declare_local_internal, 'declare-local-internal'   ; --
        _ using_locals?
        _zeq_if .1
        ; first local in this definition
        _ initialize_local_names
        _lit S_locals_enter
        _lit tagged_zero
        _get_accum
        _ vector_insert_nth

        ; check for return-if-no-locals
        ; if found, replace with return-if-locals
        _get_accum
        _quotation .2
        ; -- elt index
        _swap
        _lit S_return_if_no_locals
        _eq?
        _tagged_if .3
        _lit S_return_if_locals
        _swap
        _get_accum
        _ vector_set_nth
        _else .3
        _drop
        _then .3
        _end_quotation .2
        _ vector_each_index

        _then .1

        ; FIXME verify that we're inside a named quotation

        _ parse_token                   ; -- string

        ; add name to quotation locals so it can be found
        _ local_names
        _ vector_push

        ; return index of added name
        _ local_names
        _ vector_length
        _lit tagged_fixnum(1)
        _ fixnum_minus

        next
endcode

; ### local:
code declare_local, 'local:', SYMBOL_IMMEDIATE  ; -- tagged-index
        _ declare_local_internal
        _drop
        next
endcode

; ### >local:
code assign_local, '>local:', SYMBOL_IMMEDIATE  ; x --
        _ declare_local_internal        ; -- index

        ; add index to quotation
        _get_accum
        _ vector_push

        ; add local! to quotation as a symbol
        _lit S_local_store
        _get_accum
        _ vector_push

        next
endcode

; ### find-local-name
code find_local_name, 'find-local-name' ; string -- index/string ?

        _ local_names
        _tagged_if_not .1
        _f                      ; -- string f
        _return
        _then .1                ; -- string

        _ local_names           ; -- string vector
        _ vector_find_string    ; -- index/string ?

        next
endcode

%macro define_prefix_operator 2         ; local global
        _ must_parse_token      ; -- string

        _ in_definition?
        _ get
        _tagged_if .1

        _ find_local_name       ; -- index/string ?
        _tagged_if .2           ; -- index

        _ add_to_definition

        _lit S_%1
        _ add_to_definition

        _else .2

        ; not a local
        _ must_find_global
        _ new_wrapper
        _ add_to_definition

        _lit S_%2
        _ add_to_definition

        _then .2

        _else .1

        ; not in a definition
        _ must_find_global
        _ %2

        _then .1
%endmacro

; ### !>
code storeto, '!>', SYMBOL_IMMEDIATE    ; --
        define_prefix_operator local_store, symbol_set_value
        next
endcode

; ### 1+!>
code oneplusstoreto, '1+!>', SYMBOL_IMMEDIATE   ; --
        define_prefix_operator local_inc, global_inc
        next
endcode

; ### 1-!>
code oneminusstoreto, '1-!>', SYMBOL_IMMEDIATE  ; --
        define_prefix_operator local_dec, global_dec
        next
endcode

; ### top-level-only
code top_level_only, 'top-level-only'   ; word --
        _ in_definition?
        _ get
        _tagged_if .1
        _quote "ERROR: `%s` may only appear at top level."
        _ format
        _ error
        _else .1
        _drop
        _then .1
        next
endcode

; ### sh
code sh, 'sh'
        _ current_lexer
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

        _ string_raw_data_address       ; -- untagged-address

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
