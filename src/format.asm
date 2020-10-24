; Copyright (C) 2017-2020 Peter Graves <gnooth@gmail.com>

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

; ### parse-format-specifier
code parse_format_specifier, 'parse-format-specifier' ; lexer -> string/nil
        _ check_lexer

        push    this_register
        mov     this_register, rbx
        _drop

        _this_lexer_raw_index
        add     rbx, 2
        _this_lexer_string
        _ string_raw_length

        cmp     qword [rbp], rbx
        _2drop
        jle     .1
        _ error_unexpected_end_of_input
        jmp     .2

.1:
        ; collect token
        _this_lexer_raw_index
        _dup
        _tag_fixnum
        _swap
        add     rbx, 2
        _tag_fixnum
        _this_lexer_string
        _ string_substring

        add     this_lexer_raw_index, 2

.2:
        pop     this_register
        next
endcode

; ### parse-format-text
code parse_format_text, 'parse-format-text' ; lexer -> string
        _ check_lexer

        push    this_register
        mov     this_register, rbx
        _drop

        _lit tagged_char('%')
        _this_lexer_raw_index
        _tag_fixnum
        _this_lexer_string              ; -> char start-index string
        _ string_index_from             ; -> index/nil

        _dup
        _tagged_if .1                   ; -> index

        ; found '%'
        _this_lexer_raw_index
        _tag_fixnum
        _over
        _this_lexer_string
        _ string_substring
        _swap
        _untag_fixnum
        _this_lexer_set_raw_index

        _else .1                        ; -> nil

        ; no '%'
        _drop                           ; -> empty
        _this_lexer_raw_index
        _tag_fixnum
        _this_lexer_string
        _ string_length                 ; -> tagged-index tagged-length
        _dup
        _untag_fixnum
        _this_lexer_set_raw_index
        _this_lexer_string
        _ string_substring

        _then .1

        pop     this_register
        next
endcode

; ### parse-format-string
code parse_format_string, 'parse-format-string' ; format-string -> vector
        _ make_lexer                    ; -> lexer

        push    this_register
        mov     this_register, rbx
        _drop                           ; -> empty

        _lit 10
        _ new_vector_untagged
        _tor

        _begin .1

        _this
        _ lexer_at_end?
        _ not

        _tagged_while .1

        _this
        _ lexer_char
        _eq? tagged_char('%')
        _tagged_if .2
        _this
        _ parse_format_specifier
        _else .2
        _this
        _ parse_format_text
        _then .2

        _rfetch
        _ vector_push

        _repeat .1

        _rfrom
        pop     this_register

        next
endcode

; ### format-specifier?
code format_specifier?, 'format-specifier?' ; x -> ?
        _dup
        _ string?
        _tagged_if_not .1
        mov     ebx, f_value
        _return
        _then .1

        _dup
        _ string_length
        _ zero?
        _tagged_if .2
        mov     ebx, f_value
        _return
        _then .2

        _ string_first_char
        _lit tagged_char('%')
        _eq?

        next
endcode

; ### format-object
code format_object, 'format-object'     ; object format-specifier -> string
        _ verify_string

        _dup
        _quote "%d"
        _ stringequal?
        _tagged_if .1a
        _drop
        _ number_to_string
        _return
        _then .1a

        _dup
        _quote "%x"
        _ stringequal?
        _tagged_if .1b
        _drop
        _ integer_to_raw_bits
        _ raw_int64_to_hex
        _return
        _then .1b

        ; %S print quoted
        _dup
        _quote "%S"
        _ stringequal?
        _tagged_if .2
        _drop
        _ object_to_string
        _return
        _then .2

        ; %s print without quoting
        _dup
        _quote "%s"
        _ stringequal?
        _tagged_if .3
        _drop
        _dup
        _ string?
        _tagged_if_not .4
        _ object_to_string
        _then .4
        _return
        _then .3

        ; %% escaped % char
        _dup
        _quote "%%"
        _ stringequal?
        _tagged_if .5
        _drop
        _quote "%"
        _return
        _then .5

        ; FIXME support more format specifiers
        _error "unsupported"
        next
endcode

; ### format
code format, 'format'                   ; arg(s) format-string -> output-string
        _ parse_format_string           ; -> arg(s) vector

        _ vector_reverse_in_place

        _dup
        _ vector_raw_length
        _register_do_times .1           ; -> arg(s) vector

        _tagged_loop_index
        _over
        _ vector_nth_unsafe
        _dup
        _ format_specifier?
        _tagged_if .2                   ; -> arg(s) vector format-specifier

        _swap                           ; -> arg(s) format-specifier vector
        _tor
        _ format_object                 ; -> arg(s) string
        _rfrom                          ; -> arg(s) string vector
        _swap                           ; -> arg(s) vector string

        _tagged_loop_index              ; -> arg(s) vector string tagged-index
        _pick
        _ vector_set_nth                ; -> arg(s) vector

        _else .2
        ; not a format specifier
        _drop
        _then .2

        _loop .1                        ; -> vector

        _ vector_reverse_in_place

        _lit 256
        _ new_sbuf_untagged

        _swap                           ; -> sbuf vector

        _quotation .3
        _over
        _ sbuf_append_string
        _end_quotation .3
        _ vector_each

        _ sbuf_to_string

        next
endcode

feline_global dprintf?, 'dprintf?', NIL

; ### +dprintf
code dprintf_on, '+dprintf'
        _true
        _tick dprintf?
        _ symbol_set_value
        next
endcode

; ### -dprintf
code dprintf_off, '-dprintf'
        _nil
        _tick dprintf?
        _ symbol_set_value
        next
endcode

; ### dprintf
code dprintf, 'dprintf'                 ; arg(s) format-string -> void
        _ format
        _ dprintf?
        _tagged_if .1
        _ ?nl
        _ print
        _else .1
        _drop
        _then .1
        next
endcode
