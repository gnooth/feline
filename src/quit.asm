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

; ### find-qualified-name               ; string -- symbol/string ?
code find_qualified_name, 'find-qualified-name'
        _lit ':'
        _tag_char
        _over
        _ index                         ; -- string index/f
        cmp     rbx, f_value
        jnz     .1
        _return
.1:
        ; -- string index
        _dupd                           ; -- string string index

        _quotation .2
        _swap
        _ string_head
        _end_quotation .2

        _quotation .3
        _lit tagged_fixnum(1)
        _ generic_plus
        _swap
        _ string_tail
        _end_quotation .3

        _ twobi                         ; -- string head tail

        _swap

        _ vocab_find_name               ; -- string symbol/string ?

        _tagged_if .4
        _nip
        _t
        _else .4
        _drop
        _f
        _then .4

        next
endcode

; ### find-name-in-context-vocab
code find_name_in_context_vocab, 'find-name-in-context-vocab'
; string vocab --  symbol/f ?

        _ vocab_hashtable
        _ hashtable_at_star             ; -- symbol/f ?

        cmp     ebx, f_value
        jne     .1
        ; not found
        _rep_return

.1:
        mov     rbx, [rbp]              ; -- symbol symbol
        _ symbol_private?               ; -- symbol ?
        cmp     ebx, f_value
        jne     .2

        mov     rbx, [rbp]
        _ symbol_internal?
        cmp     ebx, f_value
        jne     .2

        mov     ebx, t_value
        _return

.2:
        ; symbol is private
        mov     ebx, f_value
        mov     [rbp], rbx
        _return
endcode

; ### find-name
code find_name, 'find-name'             ; string -> symbol/string ?
        _dup
        _ current_vocab
        _ vocab_hashtable
        _ hashtable_at_star             ; -> string symbol/nil ?
        _tagged_if .1

        ; found in current vocab
        _dup
        _ symbol_internal?
        _tagged_if .2
        ; internal
        _drop
        _f
        _return
        _then .2

        ; not internal
        _nip
        _t
        _return
        _else .1
        _drop
        _then .1

        _ context_vector
        _ vector_raw_length
        _register_do_times .3
        _dup                            ; -- string string
        _raw_loop_index
        _ context_vector
        _ vector_nth_untagged           ; -- string string vocab
        _ find_name_in_context_vocab
        _tagged_if .4
        _nip
        _t
        _unloop
        _return
        _then .4
        _drop
        _loop .3

        _ find_qualified_name

        next
endcode

; ### error
code error, 'error'                     ; string -> void
        _ save_backtrace
        _ throw
        next
endcode

; ### undefined
code undefined, 'undefined'             ; string/symbol --
        _dup
        _ symbol?
        _tagged_if .1
        _ symbol_name
        _then .1
        _quote " ?"
        _ string_append
        _ error
        next
endcode

; ### must-find-name
code must_find_name, 'must-find-name'   ; string -- symbol
        _ find_name
        cmp     ebx, f_value
        poprbx
        je      undefined
        _rep_return
endcode

; ### must-find-global
code must_find_global, 'must-find-global'       ; string -- global
        _ find_name
        _tagged_if .1
        _ verify_global
        _else .1
        _ undefined
        _then .1
        next
endcode

; ### token-keyword?
code token_keyword?, 'token-keyword?'   ; string -> keyword/string ?
        _quote ":"
        _over
        _ string_has_prefix?
        _tagged_if .1
        _lit tagged_fixnum(1)
        _swap
        _ string_tail
        _ intern_keyword
        _t
        _else .1
        _f
        _then .1
        next
endcode

; ### token-literal?
code token_literal?, 'token-literal?'   ; string -- literal/string ?
        _ token_character_literal?
        _tagged_if .1                   ; -- literal
        _t
        _return
        _then .1                        ; -- string

        _ token_string_literal?
        _tagged_if .2                   ; -- literal
        _t
        _return
        _then .2                        ; -- string

        _ token_keyword?
        _tagged_if .3
        _t
        _return
        _then .3

        _dup
        _ string_to_number              ; -- string n/f
        _dup
        _tagged_if .4                   ; -- string n
        _nip
        _t
        _return
        _else .4
        _drop
        _then .4                        ; -- string

        _f

        next
endcode

; ### interpret1
code interpret1, 'interpret1'           ; string --
        _ find_name                     ; -- symbol/string ?
        _tagged_if .1
        _ call_symbol
        _return
        _then .1

        _ token_literal?
        _tagged_if .2
        _return
        _then .2                        ; -- string

        _ undefined

        next
endcode

; ### ?stack
code ?stack, '?stack'
        _ current_thread_raw_sp0_rax
        cmp     rbp, rax
        ja      error_data_stack_underflow
        next
endcode

; ### ?enough
code ?enough, '?enough'                 ; n --

        _verify_fixnum

        test    rbx, rbx
        js      .1

        _ current_thread_raw_sp0_rax
        cmp     rbp, rax

        ja      error_data_stack_underflow

        ; save expected number of parameters in rdx
        mov     rdx, rbx

        _untag_fixnum

        ; adjust for n on stack
        add     rbx, 1

        ; convert cells to bytes
        _cells

        _ current_thread_raw_sp0_rax

        sub     rax, rbx
        cmp     rbp, rax
        ja      .2

        ; ok
        poprbx
        _return

.2:
        ; not enough parameters

        ; retrieve expected number of parameters
        pushrbx
        mov     rbx, rdx

        _depth
        sub     rbx, 2
        _tag_fixnum

        _quote "ERROR: not enough parameters (expected %d, got %d)."
        _ format
        _ error
        _return

.1:
        _quote "ERROR: the value %S is not a non-negative fixnum."
        _ format
        _ error

        next
endcode

; ### ?enough-1
code ?enough_1, '?enough-1'
        _ current_thread_raw_sp0_rax
        sub     rax, 8
        cmp     rbp, rax
        ja      .error
        next
.error:
        _quote "ERROR: not enough parameters (expected 1, got 0)."
        _ format
        _ error
        next
endcode

; ### interpret
code interpret, 'interpret'             ; --
        _begin .1
        _ ?stack
        _ parse_token                   ; -- string/f
        _dup
        _tagged_while .1
        _ interpret1
        _repeat .1
        _drop
        next
endcode

; ### reset
code reset, 'reset'

        _ current_thread_is_primordial?
        _tagged_if .1

        _ get_dynamic_scope
        _dup
        _ vector?
        _tagged_if .2
        _lit tagged_fixnum(1)
        _swap
        _ vector_set_length
        _then .2

        ; REVIEW
        _ forget_locals

        _ quit

        _else .1

        ; not primordial thread
        _ lock_all_threads
        _ current_thread
        _ all_threads
        _ vector_remove_mutating        ; -> vector
        _drop                           ; -> empty
        _ update_thread_count
        _ unlock_all_threads

%ifdef WIN64
        mov     arg0_register, 0        ; REVIEW exit code
        extern  ExitThread
        xcall   ExitThread
%else
        ; Linux
        mov     arg0_register, 0        ; REVIEW exit code
        extern  pthread_exit
        xcall   pthread_exit
%endif

        _then .1

        next                            ; for decompiler
endcode

asm_global error_location_, f_value

; ### error-location
code error_location, 'error-location'   ; -> location/f
        pushrbx
        mov     rbx, [error_location_]
        next
endcode

; ### set-error-location
code set_error_location, 'set-error-location'   ; location/f -> void
        mov     [error_location_], rbx
        poprbx
        next
endcode

; ### print-source-line
code print_source_line, 'print-source-line'     ; path line-number --
        ; convert 1-based line number to 0-based index into file-lines vector
        _lit tagged_fixnum(1)
        _ generic_minus
        _swap
        _ file_lines
        _ nth
        _ write_string
        next
endcode

; ### mark-error-location
code mark_error_location, 'mark-error-location'         ; --
        _ error_location
        _dup
        _tagged_if .1
        _ nl
        _ third
        _ spaces
        _lit '^'
        _tag_char
        _ write_char
        _ nl
        _else .1
        _drop
        _then .1
        next
endcode

; ### print-location
code print_location, 'print-location'   ; location --
        _dup
        _ array_first           ; path
        _dup
        _tagged_if .1
        _ write_string
        _else .1
        _2drop
        _return
        _then .1
        _ array_second          ; line number
        _dup
        _tagged_if .2
        _write " line "
        _ decimal_dot
        _else .2
        _drop
        _then .2
        _ nl
        next
endcode

; ### print-error-location
code print_error_location, 'print-error-location'       ; --
        _ error_location
        _ print_location
        next
endcode

; ### where
code where, 'where'

        _ error_location
        _tagged_if_not .1
        _ current_lexer_location
        _ set_error_location
        _then .1

        _ error_location
        _tagged_if_not .2
        _return
        _then .2

        _ ?nl
        _ output_style

        _ error_location
        _ first
        _dup
        _tagged_if .3
        _ error_location
        _ second
        _ print_source_line
        _ mark_error_location
        _else .3
        _drop
        _ current_lexer
        _ get
        _ lexer_string
        _ write_string
        _ mark_error_location
        _then .3

        _ print_error_location

        _f
        _ set_error_location

        next
endcode

; ### do-error1
code do_error1, 'do-error1'             ; string --
        _ ?nl
        _ error_style
        _ write_string
        _ where
        next
endcode

; ### do-error
code do_error, 'do-error'               ; error --

        _ use_default_screen_buffer

        _dup
        _ string?
        _tagged_if .1
        _ do_error1
        _ reset
        _else .1

        ; not a string

        ; REVIEW
        _ error_style
        _write "Error: "
        _ dot_object
        _ reset

        _then .1

        next
endcode

; ### line-input?
value line_input, 'line-input?', -1

; ### query
code query, 'query'                     ; -- string/f
        _ ?nl

        _quote "accept-string"          ; -- name
        _quote "accept"                 ; -- name vocab-name
        _ ?lookup_symbol
        _dup
        _tagged_if .1
        _ catch

        _dup
        _tagged_if .2
        _ do_error
        _else .2
        _drop
        _then .2

        _return
        _then .1

        _drop

        _write "> "
        xcall   os_accept_string        ; -- untagged
        pushrbx
        mov     rbx, rax
        _?dup_if .3
        _ zcount
        _ copy_to_string
        _else .3
        _f
        _then .3

        ; last char was a newline
        mov     qword [last_char_], 10
        mov     qword [output_column], 0

        next
endcode

; ### print-datastack1
code print_datastack1, 'print-datastack1'       ; x -> void
        _lit tagged_fixnum(4)
        _ tab
        _ output_style
        _ dup
        _ object_to_short_string
        _ write_string
        _ comment_style
        _lit tagged_fixnum(50)
        _ tab
        _write "// "
        _ type_of
        _ type_name
        _ write_string
        _ nl
        next
endcode

; ### print-datastack
code print_datastack, 'print-datastack'
        _ ?nl
        _ comment_style
        _print "// Data stack: "
        _depth
        _if .1
        _ get_datastack
        _lit S_print_datastack1
        _ each
        _else .1
        _ output_style
        _print "Empty"
        _then .1
        _ output_style
        next
endcode

; ### maybe-print-datastack
code maybe_print_datastack, 'maybe-print-datastack'
        _depth
        _if .1
        _ print_datastack
        _then .1
        next
endcode

; ### evaluate
code evaluate, 'evaluate'               ; string --
        _ begin_dynamic_scope

        _ new_lexer
        _ current_lexer
        _ set

        _lit S_interpret        ; try
        _lit S_do_error         ; recover
        _ recover

        _ end_dynamic_scope
        next
endcode

; ### quit
code quit, 'quit'                       ; --
        _ use_default_screen_buffer
        _ show_cursor

        _begin .1

        mov     rsp, [primordial_rp0_]

        _t
        _ interactive?
        _ set

        _ query                         ; -- string
        _ evaluate
        _ maybe_print_datastack

        _again .1

        next
endcode

asm_global saved_data_stack_, f_value

asm_global continue?_, f_value

; ### continue
code continue, 'continue'
        mov     qword [continue?_], TRUE
        next
endcode

; ### cont
code cont, 'cont'
        mov     qword [continue?_], TRUE
        next
endcode

; ### break
code break, 'break'                     ; --
        _ save_backtrace

        _ get_datastack
        mov     [saved_data_stack_], rbx
        poprbx

        _ ?nl
        _ error_style
        _write "break called"
        _ print_datastack

.loop:
        _ query
        _ evaluate
        cmp     qword [continue?_], NIL
        jne     .continue
        _ maybe_print_datastack
        jmp     .loop

.continue:
        ; restore data stack
        _ clear
        pushrbx
        mov     rbx, [saved_data_stack_]
        _quotation .1
        _ identity
        _end_quotation .1
        _ each

        next
endcode
