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
code add_to_definition, 'add-to-definition' ; x -> void
        _get_accum
        _ vector_push
        next
endcode

; ### maybe-add
code maybe_add, 'maybe-add'             ; x -> void
        _get_accum
        _dup
        _tagged_if .1
        _ vector_push
        _else .1
        _drop
        _then .1
        next
endcode

special current_lexer, 'current-lexer'

; ### parse-token
code parse_token, 'parse-token'         ; -> string/nil
        _ current_lexer
        _ get
        cmp     rbx, NIL
        je      .error
        _ lexer_parse_token
        next
.error:
        _drop
        _error "no lexer"
        next
endcode

; ### must-parse-token
code must_parse_token, 'must-parse-token' ; -> string
        _ parse_token
        cmp     rbx, NIL
        je      error_unexpected_end_of_input
        next
endcode

; ### t
code t, 't', SYMBOL_IMMEDIATE
        _t
        _ maybe_add
        next
endcode

; ### f
; Deprecated. Use nil.
code f, 'f', SYMBOL_IMMEDIATE
        _nil
        _ maybe_add
        next
endcode

; ### true
code true, 'true', SYMBOL_IMMEDIATE
        _true
        _ maybe_add
        next
endcode

; ### nil
code nil, 'nil', SYMBOL_IMMEDIATE
        _nil
        _ maybe_add
        next
endcode

; ### immediate?
code immediate?, 'immediate?'           ; object -> ?
        _dup
        _ symbol?
        _tagged_if .1
        _ symbol_immediate?
        _else .1
        _drop
        _nil
        _then .1
        next
endcode

; ### process-token
code process_token, 'process-token'     ; string -> void
        _ using_locals?
        cmp     rbx, NIL
        _drop
        je      .1
        _dup                            ; -> string string
        _ find_local                    ; -> string fixnum/nil
        cmp     rbx, NIL
        je      .1a
        _ maybe_add                     ; -> string
        _ string_last_char
        cmp     rbx, tagged_char('!')
        _drop
        jne     .1b
        _tick local_set
        jmp     .1c
.1b:
        _tick local_get
        jmp     .1c
.1c:
        _ maybe_add
        _return

.1a:
        _drop

.1:
        _ token_string_literal?
        _tagged_if .3
        _ maybe_add
        _return
        _then .3

        _ find_name                     ; -> symbol/string ?
        _tagged_if .4                   ; -> symbol
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
        cmp     rbx, NIL
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
code parse_until, 'parse-until'         ; delimiter -> vector
; REVIEW delimiter is a string

        _ begin_dynamic_scope

        _t
        _ in_definition?
        _ set

        _lit 10
        _ new_vector_untagged
        _set_accum                      ; -> delimiter

.top:
        _ parse_token                   ; -> delimiter string/nil
        cmp     rbx, NIL
        jne     .1
        _2drop
        _ error_unexpected_end_of_input
.1:                                     ; -> delimiter string
        _twodup                         ; -> d s d s
        _ string_equal?                 ; -> d s ?
        cmp     rbx, NIL
        _drop
        jne     .bottom
        _ process_token
        jmp     .top
.bottom:
        _2drop
        _get_accum                      ; -> vector

        _ end_dynamic_scope

        next
endcode

; ### vector{
code old_parse_vector, 'vector{', SYMBOL_IMMEDIATE
        _quote "}"
        _ parse_until
        _ maybe_add
        next
endcode

; ### V{
code parse_vector, 'V{', SYMBOL_IMMEDIATE
        _quote "}"
        _ parse_until
        _ maybe_add
        next
endcode

; ### {
code parse_array, '{', SYMBOL_IMMEDIATE
        _quote "}"
        _ parse_until
        _ vector_to_array
        _ maybe_add
        next
endcode

; ### }
code rbrace, '}', SYMBOL_IMMEDIATE
        _ error_unexpected_delimiter
        next
endcode

feline_global current_quotation, 'current-quotation', NIL

; ### current-quotation!
code set_current_quotation, 'current-quotation!' ; x -> void
        mov [S_current_quotation_symbol_value], rbx
        _drop
        next
endcode

; ### [
code parse_quotation, '[', SYMBOL_IMMEDIATE

        _ current_quotation
        _tor

        _ make_quotation
        _ set_current_quotation

        _rfetch
        _ current_quotation
        _ quotation_set_parent

        _quote "]"
        _ parse_until
        _ vector_to_array

        _ current_quotation
        _ quotation_set_array
        _ current_quotation

        _ maybe_add

        _rfrom
        _ set_current_quotation

        next
endcode

; ### ]
code rbracket, ']', SYMBOL_IMMEDIATE
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

; ### define-symbol
code define_symbol, 'define-symbol'     ; string -> symbol
        _ new_symbol_in_current_vocab   ; -> symbol
        _dup
        _ new_wrapper
        _ one_quotation
        _over
        _ symbol_set_def                ; -> symbol
        _dup
        _ compile_word                  ; -> symbol
        next
endcode

; ### symbol:
code parse_symbol, 'symbol:', SYMBOL_IMMEDIATE
        _ must_parse_token              ; -> string
        _ define_symbol
        _drop
        next
endcode

; ### special
code parse_special, 'special', SYMBOL_IMMEDIATE
        _ must_parse_token              ; -> string
        _ new_symbol_in_current_vocab   ; -> symbol

        _dup
        _ symbol_set_special_bit

        _dup
        _ new_wrapper
        _ one_quotation
        _over
        _ symbol_set_def                ; -> symbol
        _ compile_word
        next
endcode

; ### note-redefinition
code note_redefinition, 'note_redefinition' ; symbol ->
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
        _ current_lexer_location
        _dup
        _tagged_if .1
        _ print_location
        _else .1
        _drop
        _then .1
        next
endcode

; ### maybe-note-redefinition
code maybe_note_redefinition, 'maybe-note-redefinition' ; string ->
        _ current_vocab
        _ vocab_hashtable
        _ hashtable_at_star             ; -> symbol/nil ?
        _tagged_if .1
        _ note_redefinition
        _else .1
        _drop
        _then .1
        next
endcode

; ### new-symbol-in-current-vocab
code new_symbol_in_current_vocab, 'new-symbol-in-current-vocab' ; string -> symbol
        _dup
        _ maybe_note_redefinition
        _ current_vocab
        _ new_symbol

        _ current_lexer_location        ; -> symbol 3array/nil
        _dup
        _tagged_if .1                   ; -> symbol 3array
        _dup
        _ array_first
        _swap
        _ array_second                  ; -> symbol file line-number
        _pick
        _ symbol_set_location
        _else .1
        _drop
        _then .1                        ; -> symbol

        next
endcode

; ### parse-name
code parse_name, 'parse-name'           ; -> symbol

        _ must_parse_token              ; -> string
        _ new_symbol_in_current_vocab   ; -> symbol

        _dup
        _ set_last_word                 ; -> symbol

        next
endcode

asm_global current_definition_, NIL

; ### current-definition
code current_definition, 'current-definition' ; -> vector/nil
        _dup
        mov     rbx, [current_definition_]
        next
endcode

; ### set-current-definition
code set_current_definition, 'set-current-definition' ; vector/nil -> void
        _dup
        _tagged_if .1
        _ verify_vector
        _then .1
        mov     [current_definition_], rbx
        _drop
        next
endcode

; ### parse-definition
code parse_definition, 'parse-definition' ; -> vector

        _ begin_dynamic_scope

        _true
        _ in_definition?
        _ set

        _lit 10
        _ new_vector_untagged
        _dup
        _ set_current_definition
        _set_accum

.top:
        _ parse_token                   ; -> string/nil
        cmp     rbx, NIL
        jne     .1
        _drop
        _ error_unexpected_end_of_input

.1:                                     ; ->  string
        _dup
        _quote ";"
        _ string_equal?
        _tagged_if .2
        _drop
        jmp     .bottom
        _then .2

        _ process_token

        jmp     .top

.bottom:
        _ current_definition            ; -> vector

        _ end_dynamic_scope

        _nil
        _ set_current_definition

        next
endcode

; ### symbol-get-locals-count
code symbol_get_locals_count, 'symbol-get-locals-count' ; symbol -> n
        _tick locals_count
        _swap
        _ symbol_prop
        _lit tagged_zero
        _ feline_or
        next
endcode

; ### symbol-set-locals-count
code symbol_set_locals_count, 'symbol-set-locals-count' ; n symbol -> void
        _tick locals_count
        _swap
        _ symbol_set_prop
        next
endcode

; ### :
code colon, ':', SYMBOL_IMMEDIATE       ; void -> void

        _tick colon
        _ top_level_only

        _ parse_name                    ; -> symbol

        _ make_quotation
        _ set_current_quotation

        _ parse_definition              ; -> symbol vector
        _ vector_to_array               ; -> symbol array
        _ current_quotation             ; -> symbol array quotation
        _ quotation_set_array           ; -> symbol

        _ current_quotation
        _over
        _ symbol_set_def                ; -> symbol

        _ locals_count
        _over
        _ symbol_set_locals_count       ; -> symbol

        _nil
        _ set_current_quotation         ; -> symbol

        _ compile_word                  ; -> void

        next
endcode

; ### constant:
code constant_colon, 'constant:', SYMBOL_IMMEDIATE ; void -> void

        _tick constant_colon
        _ top_level_only

        _ parse_name                    ; -> symbol

        _ make_quotation
        _ set_current_quotation

        _ parse_definition              ; -> symbol vector
        _ vector_to_array               ; -> symbol array
        _ current_quotation             ; -> symbol array quotation
        _ quotation_set_array           ; -> symbol

        _depth
        _tor

        _ current_quotation
        _ call_quotation

        _depth
        _rfrom
        _minus
        cmp     rbx, 1
        jne     .error

        _drop                           ; -> symbol value

        _nil
        _ set_current_quotation         ; -> symbol value

        _ one_quotation                 ; -> symbol quotation

        _over
        _ symbol_set_def                ; -> symbol

        _dup
        _symbol_set_flags_bit SYMBOL_CONSTANT
        _dup
        _symbol_set_flags_bit SYMBOL_INLINE

        _ compile_word                  ; -> void

        next

.error:
        _tag_fixnum
        _quote "ERROR: wrong number of values (expected 1, got %d)"
        _ format
        _ error
        next
endcode

; ### private:
code private_colon, 'private:', SYMBOL_IMMEDIATE
        _tick private_colon
        _ top_level_only

        _ colon
        _ last_word
        _ symbol_set_private
        next
endcode

; ### public:
code public_colon, 'public:', SYMBOL_IMMEDIATE
        _tick public_colon
        _ top_level_only

        _ colon
        _ last_word
        _ symbol_set_public
        next
endcode

; ### ;
code semi, ';', SYMBOL_IMMEDIATE
        _ error_unexpected_delimiter
        next
endcode

; ### immediate
code immediate, 'immediate'
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

; ### find-generic
code find_generic, 'find-generic'       ; symbol-name vocab-designator -> symbol/?

        _debug_?enough 2

        ; vocabulary must exist
        _dup
        _ lookup_vocab
        _tagged_if_not .1
        _drop
        _ error_vocab_not_found
        _else .1
        _ nip
        _then .1                        ; -> symbol-name vocab

        _ vocab_hashtable
        _ hashtable_at_star
        _tagged_if_not .2
        _return
        _then .2

        _dup
        _ generic?
        _tagged_if_not .3
        _drop
        _f
        _then .3

        next
endcode

; ### ensure-generic
code ensure_generic, 'ensure-generic'   ; symbol-name vocab-designator -> symbol

        _debug_?enough 2

        _twodup
        _ find_generic
        _dup
        _tagged_if .1
        _2nip
        _return
        _then .1

        _drop

        ; vocabulary must exist
        _dup
        _ lookup_vocab
        _tagged_if_not .2
        _drop
        _ error_vocab_not_found
        _then .2

        _nip                            ; -> symbol-name vocab

        _ new_symbol
        _ define_generic

        next
endcode

; ### generic
code parse_generic, 'generic', SYMBOL_IMMEDIATE
        _ parse_name                    ; -> symbol
        _ define_generic                ; -> symbol
        _drop
        next
endcode

; ### method:
code method_colon, 'method:', SYMBOL_IMMEDIATE

        _tick method_colon
        _ top_level_only

        ; type
        _ must_parse_token              ; -> string
        _ must_find_type                ; -> type
        _ type_typecode                 ; -> typecode

        ; generic word
        _ must_parse_token              ; -> typecode string
        _ must_find_name                ; -> typecode symbol

        _dup
        _ generic?
        _tagged_if_not .2
        _ error_not_generic_word
        _return
        _then .2                        ; -> typecode generic-symbol

        _ make_quotation
        _ set_current_quotation

        _ symbol_def                    ; -> typecode gf
        _ parse_definition              ; -> typecode gf vector
        _ vector_to_array
        _ current_quotation
        _ quotation_set_array
        _ current_quotation
        _ make_method                   ; -> method

        _dup
        _ method_callable
        _ verify_quotation              ; -> method quotation
        _over
        _ method_symbol
        _ symbol_set_def                ; -> method

        _dup
        _ method_symbol                 ; -> method symbol
        _ locals_count
        _over                           ; -> method symbol n symbol
        _ symbol_set_locals_count       ; -> method symbol

        _nil
        _ set_current_quotation

        _ compile_word                  ; -> method
        _ install_method

        next
endcode

; ### forget
code forget, 'forget', SYMBOL_IMMEDIATE
; Removes the symbol from its vocab.
; Does nothing if the symbol does not exist.

        _tick forget
        _ top_level_only

        _ must_parse_token

        _ find_name
        _tagged_if .1
        _dup
        _ symbol_name
        _swap
        _ symbol_vocab
        _dup
        _tagged_if .2
        _ vocab_hashtable
        _ delete_at
        _else .2
        ; no vocab
        _2drop
        _then .2
        _else .1
        ; name not found
        _drop
        _then .1

        next
endcode

; ### //
code comment_to_eol2, '//', SYMBOL_IMMEDIATE
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

; ### ///
code comment_to_eol3, '///', SYMBOL_IMMEDIATE
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

; ### ?exit
code ?exit, '?exit', SYMBOL_IMMEDIATE
        _ using_locals?
        _tagged_if .1
        _tick ?exit_locals
        _else .1
        _tick ?exit_no_locals
        _then .1
        _get_accum
        _ vector_push
        next
endcode

; ### return-if
code return_if, 'return-if', SYMBOL_IMMEDIATE
        _ ?nl
        _quote "WARNING: return-if is deprecated. Use ?return instead."
        _ print
        _ where

        jmp     ?return
endcode

; ### ?return
code ?return, '?return', SYMBOL_IMMEDIATE
        _ using_locals?
        _tagged_if .1
        _tick ?return_locals
        _else .1
        _tick ?return_no_locals
        _then .1
        _get_accum
        _ vector_push
        next
endcode

; ### store_1_arg
always_inline store_1_arg, 'store_1_arg'
        mov     [r14], rbx
        poprbx
endinline

; ### store_2_args
always_inline store_2_args, 'store_2_args'
        mov     rax, [rbp]
        mov     [r14], rax
        mov     [r14 + BYTES_PER_CELL], rbx
        _2drop
endinline

; ### store_3_args
always_inline store_3_args, 'store_3_args'
        mov     rax, [rbp + BYTES_PER_CELL]
        mov     [r14], rax
        mov     rax, [rbp]
        mov     [r14 + BYTES_PER_CELL], rax
        mov     [r14 + BYTES_PER_CELL * 2], rbx
        _3drop
endinline

; ### store_4_args
always_inline store_4_args, 'store_4_args'
        mov     rax, [rbp + BYTES_PER_CELL * 2]
        mov     [r14], rax
        mov     rax, [rbp + BYTES_PER_CELL]
        mov     [r14 + BYTES_PER_CELL], rax
        mov     rax, [rbp]
        mov     [r14 + BYTES_PER_CELL * 2], rax
        mov     [r14 + BYTES_PER_CELL * 3], rbx
        _4drop
endinline

; ### process-named-parameters
code process_named_parameters, 'process-named-parameters'
        _ locals_count
        _untag_fixnum
        cmp     rbx, 1
        jz      .1
        cmp     rbx, 2
        jz      .2
        cmp     rbx, 3
        jz      .3
        cmp     rbx, 4
        jz      .4

        _error "too many named parameters"

.1:
        _drop
        _tick store_1_arg
        _ add_to_definition
        _return

.2:
        _drop
        _tick store_2_args
        _ add_to_definition
        _return

.3:
        _drop
        _tick store_3_args
        _ add_to_definition
        _return

.4:
        _drop
        _tick store_4_args
        _ add_to_definition
        _return

        next
endcode

; ### add-named-parameter
code add_named_parameter, 'add-named-parameter' ; string ->
        _ add_local_name
        _increment_locals_count
        next
endcode

; ### (
code paren, '(', SYMBOL_IMMEDIATE       ; ->

        _ current_lexer
        _ get
        _tagged_if_not .1
        _error "no lexer"
        _then .1

        _ in_definition?
        _ get
        _tagged_if_not .2
        _error "not in definition"
        _then .2

        ; FIXME
        ; Parameter list must come before anything else in the definition.
        ; Checking locals-count is not enough here.
        _ locals_count
        _ zero?
        _tagged_if_not .3
        _error "misplaced ("
        _then .3

        _ begin_dynamic_scope

        _lit 10
        _ new_vector_untagged
        _set_accum

.again:
        _ must_parse_token              ; -> string
        _dup
        _quote ")"
        _ string_equal?
        cmp     rbx, NIL
        _drop
        jne     .done
        _get_accum
        _ vector_push
        jmp     .again

.done:
        _drop
        _get_accum                      ; -> vector

        _ end_dynamic_scope

        _ initialize_locals

        _lit add_named_parameter
        _ vector_each_internal

        _ process_named_parameters

        next
endcode

; ### :>
code define_immutable_local, ':>', SYMBOL_IMMEDIATE

        _ maybe_initialize_locals

        _ must_parse_token              ; -> string

        _dup
        _ string_last_char
        cmp     rbx, tagged_char('!')
        _drop
        jne     .1

        _dup
        _ add_local_name                ; -> string

        _dup
        _ string_length
        sub     rbx, (1 << FIXNUM_TAG_BITS)
        _swap
        _ string_head

.1:
        _dup
        _ add_local_name
        _increment_locals_count

        _ find_local                    ; -> index
        _ add_to_definition

        _tick local_set
        _ add_to_definition

        next
endcode

; ### !>
code define_mutable_local, '!>', SYMBOL_IMMEDIATE

        _ maybe_initialize_locals

        _ must_parse_token              ; -> string

        _dup
        _tagged_char('!')
        _ string_append_char
        _ add_local_name                ; -> string

        _dup
        _ add_local_name
        _increment_locals_count

        _ find_local
        _ add_to_definition

        _tick local_set
        _ add_to_definition

        next
endcode

; ### local
code local, 'local', SYMBOL_IMMEDIATE
; another way to define a mutable local
; `local x` is equivalent to `nil !> x`

        _ maybe_initialize_locals

        _ must_parse_token              ; -> string

        _dup
        _tagged_char('!')
        _ string_append_char
        _ add_local_name                ; -> string

        _dup
        _ add_local_name
        _increment_locals_count

        _nil
        _ add_to_definition

        _ find_local
        _ add_to_definition

        _tick local_set
        _ add_to_definition

        next
endcode

; ### top-level-only
code top_level_only, 'top-level-only'   ; word ->
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
        _ lexer_line                    ; -> lexer string
        _over
        _ lexer_index                   ; -> lexer string index
        _swap
        _ string_tail                   ; -> lexer tail

        _swap
        _ lexer_next_line
        _ run_shell_command             ; returns fixnum 0 on success
        _ drop                          ; ignore return value
        _else .1
        _drop
        _error "no lexer"
        _then .1

        next
endcode
