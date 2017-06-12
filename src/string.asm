; Copyright (C) 2015-2017 Peter Graves <gnooth@gmail.com>

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

; strings are immutable

; 3 cells: object header, length, hashcode

; character data (untagged) starts at offset 24
%define STRING_RAW_DATA_OFFSET  24

; ### string?
code string?, 'string?'                 ; x -- ?
        _dup
        _ handle?
        _tagged_if .1
        _handle_to_object_unsafe        ; -- raw-object/0
        _?dup_if .2
        _object_raw_typecode            ; -- raw-typecode
        _eq? TYPECODE_STRING
        _return
        _then .2
        ; Empty handle.
        _f
        _return
        _then .1

        ; not a handle
        ; make sure address is in the permissible range
        _dup
        _ in_static_data_area?
        _tagged_if_not .3
        ; address is not in the permissible range
        ; -- x
        mov     ebx, f_value
        _return
        _then .3

        ; -- object
        _object_raw_typecode            ; -- raw-typecode
        _eq? TYPECODE_STRING

        next
endcode

; ### verify-static-string
code verify_static_string, 'verify-static-string'       ; string -- string
        cmp     rbx, static_data_area
        jb      error_not_string
        cmp     rbx, static_data_area_limit
        jae     error_not_string
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_STRING
        jne     error_not_string
        next
endcode

; ### check-string
code check_string, 'check-string'       ; x -- unboxed-string
        _dup
        _ deref                         ; -- x object/0
        test    rbx, rbx
        jz      .1
        movzx   eax, word [rbx]
        cmp     eax, TYPECODE_STRING
        jne     .2
        _nip
        _return
.1:
        ; not a handle
        _drop
        _ verify_static_string
        _return
.2:
        _ error_not_string
        next
endcode

; ### verify-string
code verify_string, 'verify-string'     ; handle-or-string -- handle-or-string
; returns argument unchanged
        _dup
        _ handle?
        _tagged_if .1
        _dup
        _handle_to_object_unsafe        ; -- handle object/0
        _dup_if .2
        _object_raw_typecode            ; -- object raw-typecode
        _lit TYPECODE_STRING
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _ error_not_string
        _then .1

        ; not a handle
        _ verify_static_string

        next
endcode

%macro  _string_raw_length 0            ; string -- untagged-length
        _slot1
%endmacro

%define this_string_raw_length this_slot1

%macro  _this_string_raw_length 0       ; -- untagged-length
        _this_slot1
%endmacro

%macro  _this_string_set_raw_length 0   ; untagged-length --
        _this_set_slot1
%endmacro

%macro  _string_hashcode 0              ; string -- tagged-fixnum
        _slot2
%endmacro

%macro  _string_set_hashcode 0          ; tagged-fixnum string --
        _set_slot2
%endmacro

%macro  _this_string_hashcode 0         ; -- tagged-fixnum
        _this_slot2
%endmacro

%macro  _this_string_set_hashcode 0     ; tagged-fixnum --
        _this_set_slot2
%endmacro

%macro  _this_string_substring_unsafe 0 ; from to -- substring
; no bounds checking
        sub     rbx, qword [rbp]        ; length (in rbx) = to - from
        lea     rax, [this_register + STRING_RAW_DATA_OFFSET]   ; raw data address in rax
        add     qword [rbp], rax        ; start of substring = from + raw data address
        _ copy_to_string
%endmacro

; ### string-raw-length
code string_raw_length, 'string-raw-length', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; string -- raw-length
        _ check_string
        _string_raw_length
        next
endcode

; ### string-length
code string_length, 'string-length'     ; string -- length
        _ check_string
        _string_raw_length
        _tag_fixnum
        next
endcode

; ### string-empty?
code string_empty?, 'string-empty?'     ; string -- ?
        _ check_string
        _string_raw_length
        test    rbx, rbx
        jz      .1
        mov     ebx, f_value
        _return
.1:
        mov     ebx, t_value
        next
endcode

; Strings store their character data inline starting at this + STRING_RAW_DATA_OFFSET bytes.
%macro  _string_raw_data_address 0
        lea     rbx, [rbx + STRING_RAW_DATA_OFFSET]
%endmacro

%macro  _this_string_raw_data_address 0
        pushrbx
        lea     rbx, [this_register + STRING_RAW_DATA_OFFSET]
%endmacro

; ### string-raw-data-address
code string_raw_data_address, 'string-raw-data-address', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; string -- raw-data-address
        _ check_string
        _string_raw_data_address
        next
endcode

; ### string-data-address
code string_data_address, 'string-data-address', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; string -- data-address
        _ check_string
        _string_raw_data_address
        _tag_fixnum
        next
endcode

%macro  _string_nth_unsafe 0            ; untagged-index string -- untagged-char
        _string_raw_data_address
        _plus
        _cfetch
%endmacro

%macro  _this_string_nth_unsafe 0       ; untagged-index -- untagged-char
        movzx   ebx, byte [rbx + this_register + STRING_RAW_DATA_OFFSET]
%endmacro

; ### copy-to-string
code copy_to_string, 'copy-to-string', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; from-addr from-length -- handle
; arguments are untagged

        _lit STRING_RAW_DATA_OFFSET
        _over
        _oneplus                        ; +1 for terminal null byte
        _plus                           ; -- from-addr from-length size
        _ allocate_object               ; -- from-addr from-length string

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- from-addr from-length

        ; zero all bits of object header
        xor     eax, eax
        mov     [this_register], rax

        _this_object_set_raw_typecode TYPECODE_STRING
        _this_object_set_flags OBJECT_ALLOCATED_BIT

        _f
        _this_string_set_hashcode

        _this_string_set_raw_length     ; -- from-addr

        _this_string_raw_data_address
        _this_string_raw_length
        _ cmove                         ; --

        ; store terminal null byte
        mov     rdx, this_string_raw_length
        lea     rax, [this_register + STRING_RAW_DATA_OFFSET]
        mov     byte [rax + rdx], 0

        pushrbx
        mov     rbx, this_register      ; -- string

        ; return handle of allocated string
        _ new_handle                    ; -- handle

        pop     this_register
        next
endcode

; ### string_from
code string_from, 'string>'     ; string -- addr len
        _ check_string
        _duptor
        _string_raw_data_address
        _rfrom
        _string_raw_length
        next
endcode

; ### ~string
code destroy_string, '~string'          ; string --
        _ check_string
        _ destroy_string_unchecked
        next
endcode

; ### ~string-unchecked
code destroy_string_unchecked, '~string-unchecked' ; string --
        _dup
        _object_allocated?
        _if .1
        _ in_gc?
        _tagged_if_not .2
        _dup
        _ release_handle_for_object
        _then .2
        ; Zero out the object header so it won't look like a valid object
        ; after it has been destroyed.
        xor     eax, eax
        mov     [rbx], rax
        _ raw_free
        _else .1
        _drop
        _then .1
        next
endcode

; ### hash-string
code hash_string, 'hash-string'         ; string --
; Hash function adapted from SBCL.

        _ check_string                  ; -- string

hash_string_unchecked:
        push    this_register
        popd    this_register           ; --

        _zero                           ; -- accumulator

        _this_string_raw_length
        _register_do_times .1

        _i
        _this_string_nth_unsafe         ; -- accum untagged-char
        _plus                           ; -- accum

        mov     rax, rbx
        shl     rax, 10
        add     rbx, rax

        mov     rax, rbx
        shr     rax, 6
        xor     rbx, rax

        _loop .1

        mov     rax, rbx
        shl     rax, 3
        add     rbx, rax

        mov     rax, rbx
        shr     rax, 11
        xor     rbx, rax

        mov     rax, rbx
        shl     rax, 15
        xor     rbx, rax

        _lit MOST_POSITIVE_FIXNUM
        _and

        _tag_fixnum
        _this_string_set_hashcode

        pop     this_register
        next
endcode

; ### string-hashcode
code string_hashcode, 'string-hashcode' ; handle-or-string -- fixnum
        _ check_string
        _dup
        _string_hashcode
        _dup
        _tagged_if .1
        _nip
        _else .1
        _drop
        _dup
        _ hash_string_unchecked
        _string_hashcode
        _then .1
        next
endcode

; ### as-c-string
code as_c_string, 'as-c-string'         ; c-addr u -- zaddr
; Arguments are untagged.
; Returns a pointer to a null-terminated string.
        _ copy_to_string
        _ string_raw_data_address
        next
endcode

; ### string-nth-unsafe
code string_nth_unsafe, 'string-nth-unsafe' ; tagged-index handle-or-string -- tagged-char
; No bounds check.
        _swap
        _untag_fixnum
        _swap
        _ check_string
        _string_nth_unsafe
        _tag_char
        next
endcode

; ### string-nth
code string_nth, 'string-nth'   ; tagged-index string -- tagged-char
; Return character at index.

        _tor
        _check_index
        _rfrom                          ; -- raw-index string

string_nth_untagged:

        _ check_string

        push    this_register
        mov     this_register, rbx
        poprbx                          ; -- raw-index
        cmp     rbx, this_string_raw_length
        jnb     .1
        _this_string_nth_unsafe
        _tag_char
        pop     this_register
        _return

.1:
        pop     this_register
        _error "index out of bounds"
        next
endcode

; ### string-first-char
code string_first_char, 'string-first-char' ; string -- char
; Returns first character of string.
; Throws an error if the string is empty.
        _ verify_string
        _zero
        _swap
        _ string_nth_untagged
        next
endcode

; ### string-last-char
code string_last_char, 'string-last-char' ; string -- char
; Returns last character of string.
; Throws an error if the string is empty.
        _ check_string
        _dup
        _string_raw_length
        _dup
        _zeq_if .1
        _2drop
        _error "index out of bounds"
        _else .1
        _swap
        _string_raw_data_address
        _plus
        _oneminus
        _cfetch
        _then .1

        _tag_char
        next
endcode

; ### string-find-char
code string_find_char, 'string-find-char'       ; char string -- index/f

        _ check_string

        push    this_register
        popd    this_register           ; -- tagged-char

        _check_char                     ; -- untagged-char

        _this_string_raw_length
        _register_do_times .1
        _raw_loop_index
        _this_string_nth_unsafe
        _over
        _eq?
        _tagged_if .2
        _drop
        _tagged_loop_index
        _unloop
        jmp     .exit
        _then .2
        _loop .1
        ; not found
        _drop
        _f
.exit:
        pop     this_register
        next
endcode

; ### string-substring
code string_substring, 'string-substring'       ; from to string -- substring

        _ check_string

string_substring_unchecked:
        push    this_register
        popd    this_register           ; -- start-index end-index

        _check_index qword [rbp]
        _check_index

        _dup
        _this_string_raw_length
        _ugt
        _if .1
        _error "end index out of range"
        _then .1
                                        ; -- start-index end-index
        _twodup                         ; -- start-index end-index start-index end-index
        _ugt
        _if .2
        _error "start index > end index"
        _then .2                        ; -- start-index end-index

        _this_string_substring_unsafe

        pop     this_register
        next
endcode

; ### string-limit
feline_global string_limit, 'string-limit', tagged_fixnum(40)

; ### limit-string
code limit_string, 'limit-string'       ; string limit -- limited-string
        _dup
        _ string_length
        _ string_limit
        _ fixnum_fixnum_gt
        _tagged_if .1
        _lit tagged_zero
        _ string_limit
        _ rot
        _ string_substring
        _quote "..."
        _ concat
        _then .1
        next
endcode

; ### escaped
code escaped, 'escaped'                 ; -- string
        _quote 'nr"\'
        next
endcode

; ### unescaped
code unescaped, 'unescaped'             ; -- string
        _quote `\n\r\"\\`
        next
endcode

; ### quote-string
code quote_string, 'quote-string'       ; string -- quoted-string
        _dup
        _ string_raw_length
        add     rbx, 16
        _ new_sbuf_untagged             ; -- string sbuf
        _tor                            ; -- string

        _tagged_char '"'
        _rfetch
        _ sbuf_push                     ; -- string

        _ new_iterator                  ; -- iterator

        _begin .1
        _dup
        _ iterator_next                 ; -- iterator char/f
        _dup
        _tagged_if .2                   ; -- iterator char

        _dup
        _ unescaped
        _ string_index                  ; -- iterator char index/f
        _dup
        _tagged_if .3                   ; -- iterator char index

        _nip                            ; -- iterator index

        _tagged_char '\'
        _rfetch
        _ sbuf_push

        _ escaped
        _ string_nth
        _rfetch
        _ sbuf_push

        _else .3                        ; -- iterator char f

        _drop

        _rfetch
        _ sbuf_push

        _then .3

        _else .2                        ; -- iterator f
        _2drop

        _tagged_char '"'
        _rfetch
        _ sbuf_push

        _rfrom
        _ sbuf_to_string

        _return
        _then .2
        _again .1

        next
endcode

; ### string-head
code string_head, 'string-head'         ; string n -- substring
        _lit tagged_zero
        _swap
        _ rot
        _ string_substring
        next
endcode

; ### string-tail
code string_tail, 'string-tail'         ; string n -- substring
        _over
        _ string_length
        _ rot
        _ string_substring
        next
endcode

; ### string-has-prefix?
code string_has_prefix?, 'string-has-prefix?'   ; prefix string -- ?
        _twodup
        _lit S_string_length
        _ bi_at
        _ fixnum_fixnum_le
        _tagged_if .1
        _ mismatch
        _ not
        _else .1
        _2drop
        _f
        _then .1
        next
endcode

; ### substring-start
code substring_start, 'substring-start'         ; pattern string -- index/f
        _ check_string

        push    this_register
        popd    this_register                   ; -- pattern

        _ check_string

        ; return right away if pattern is longer than string
        _dup
        _string_raw_length
        _this_string_raw_length
        cmp     rbx, [rbp]
        _2drop
        jnc     .1
        mov     ebx, f_value
        pop     this_register
        _return

.1:
        _dup
        _string_raw_data_address                ; -- pattern-raw-data-address
        _swap
        _string_raw_length                      ; -- pattern-raw-data-address pattern-raw-length

        _this_string_raw_length
        _over
        _minus
        _oneplus

        _register_do_times .2

        _this_string_raw_data_address
        add rbx, index_register
        _ feline_2over
        _ unsafe_raw_memequal
        _tagged_if .3
        _tagged_loop_index
        _unloop
        _2nip
        jmp     .exit
        _then .3

        _loop .2

        _2drop
        _f

.exit:
        pop     this_register
        next
endcode

; ### string-has-suffix?
code string_has_suffix?, 'string-has-suffix?'   ; suffix string -- ?
        _twodup
        _lit S_string_length
        _ bi_at                 ; -- suffix string len1 len2
        _twodup
        _ fixnum_fixnum_le
        _tagged_if .1
        _swap
        _ fixnum_minus
        _ string_tail
        _ stringequal
        _else .1
        _4drop
        _f
        _then .1
        next
endcode

; ### string-skip-whitespace
code string_skip_whitespace, 'string-skip-whitespace' ; start-index string -- index/f
        _ check_string

        push    this_register
        popd    this_register           ; -- start-index

        _ check_index                   ; -- untagged-start-index

        _this_string_raw_length
        _twodup
        _ge
        _if .1
        _2drop
        _f
        jmp     .exit
        _then .1                        ; -- untagged-start-index untagged-length

        _swap
        _do .2
        _i
        _this_string_nth_unsafe
        _lit 32
        _ugt
        _if .3
        _i
        _tag_fixnum
        _unloop
        jmp     .exit
        _then .3
        _loop .2

        ; not found
        _f

.exit:
        pop     this_register
        next
endcode

; ### string-skip-to-whitespace
code string_skip_to_whitespace, 'string-skip-to-whitespace' ; start-index string -- index/f
        _ check_string

        push    this_register
        popd    this_register           ; -- start-index

        _ check_index                   ; -- untagged-start-index

        _this_string_raw_length
        _twodup
        _ge
        _if .1
        _2drop
        _f
        jmp     .exit
        _then .1                        ; -- untagged-start-index untagged-length

        _swap
        _register_do_range .2
        _raw_loop_index
        _this_string_nth_unsafe
        _lit 33
        _ult_if .3
        _tagged_loop_index
        _unloop
        jmp     .exit
        _then .3
        _loop .2

        ; not found
        _f

.exit:
        pop     this_register
        next
endcode

; ### string-index-from
code string_index_from, 'string-index-from' ; char start-index string -- index/f

        _ check_string

        push    this_register
        popd    this_register

        _ check_index                   ; -- char untagged-start-index

        _this_string_raw_length
        cmp     rbx, [rbp]
        jnc     .1

        _2drop
        jmp     .4

.1:                                     ; -- char untagged-start-index untagged-length
        _untag_char qword [rbp + BYTES_PER_CELL]
        _swap

        _register_do_range .2
        _raw_loop_index
        _this_string_nth_unsafe
        cmp     bl, byte [rbp]
        _drop
        jne     .3
        mov     rbx, index_register
        _tag_fixnum
        _unloop
        jmp     .5
.3:
        _loop   .2

.4:
        ; not found
        mov     ebx, f_value

.5:
        pop     this_register
        next
endcode

; ### string-index
code string_index, 'string-index'       ; char string -- index/f
        _lit tagged_zero
        _swap
        _ string_index_from
        next
endcode

code unsafe_raw_write_chars, 'unsafe-raw-write-chars'   ; raw-address raw-count --
        ; test for zero length string
        test    rbx, rbx
        jnz     .1
        _2drop
        _return
.1:
        ; update output column
        ; FIXME will not be correct if string contains a newline
        add     [output_column], rbx

        ; store last char for ?nl
        mov     rax, [rbp]
        movzx   eax, byte [rax + rbx - 1]
        mov     [last_char], rax

        push    rbx                     ; save length
%ifdef WIN64
        ; args in rcx, rdx, r8, r9
        mov     rcx, [standard_output_handle]
        popd    r8
        popd    rdx
%else
        ; args in rdi, rsi, rdx, rcx
        mov     edi, 1
        popd    rdx
        popd    rsi
%endif
        xcall   os_write_file           ; Cell os_write_file(Cell fd, void *buf, size_t count)
        ; os_write_file returns number of bytes written or -1 in rax
        pop     rdx                     ; length
        cmp     rdx, rax
        jne     .error
        _return
.error:
        _error "error writing to file"
.exit:
        next
endcode

; ### write-string
code write_string, 'write-string'       ; string --
        _ string_from                   ; -- addr len
        _ unsafe_raw_write_chars
        next
endcode

; ### concat
code concat, 'concat'                   ; string1 string2 -- string3
        _swap
        _ string_to_sbuf                ; -- string2 sbuf
        _tuck
        _ sbuf_append_string
        _ sbuf_to_string
        next
endcode

; ### unsafe-raw-mem=
code unsafe_raw_memequal, 'unsafe-raw-mem='     ; addr1 addr2 len -- ?
        push    rdi
        push    rsi
        mov     rcx, rbx
        mov     rdi, [rbp]
        mov     rsi, [rbp + BYTES_PER_CELL]
        lea     rbp, [rbp + BYTES_PER_CELL * 2]
        jrcxz   .1
.3:
        movzx   eax, byte [rdi]
        movzx   edx, byte [rsi]
        cmp     al, dl
        jne     .2
        add     rdi, 1
        add     rsi, 1
        sub     rcx, 1
        jnz     .3
.1:
        mov     ebx, t_value
        pop     rsi
        pop     rdi
        next
.2:
        mov     ebx, f_value
        pop     rsi
        pop     rdi
        next
endcode

; ### string=
code stringequal, 'string='             ; string1 string2 -- ?
        _tor
        _ string_from
        _rfrom
        _ string_from

        cmp     rbx, [rbp + BYTES_PER_CELL]
        jz      .1
        lea     rbp, [rbp + BYTES_PER_CELL * 3]
        mov     ebx, f_value
        next
.1:
        ; lengths match                 ; -- addr1 len1 addr2 len2
        _dropswap                       ; -- addr1 addr2 len1
        _ unsafe_raw_memequal

        next
endcode

; ### string-equal?
code string_equal?, 'string-equal?'     ; object1 object2 -- ?
; Returns true if both objects are strings and those strings are identical.
        _dup
        _ string?
        _tagged_if .1
        _swap
        _dup
        _ string?
        _tagged_if .2

        ; both objects are strings

        _twodup
        _lit S_string_hashcode
        _ bi_at                         ; -- seq1 seq2 hashcode1 hashcode2

        _equal
        _zeq_if .3
        _2drop
        _f
        _return
        _then .3

        _ stringequal
        _return
        _then .2
        _then .1

        _2drop
        _f
        next
endcode

; ### path-get-extension
code path_get_extension, 'path-get-extension'   ; pathname -- extension/f

        _ check_string

        push    this_register
        mov     this_register, rbx

        _string_raw_length

        _begin .1
        _dup
        _while .1
        _oneminus
        _dup
        _this_string_nth_unsafe

        ; If we find a path separator char before finding a '.', there is no
        ; extension. Return f.
        _dup
        _ path_separator_char?
        _if .2
        _2drop
        _f
        jmp     .exit
        _then .2

        _lit '.'
        _equal
        _if .3
        _this_string_raw_length
        _this_string_substring_unsafe
        jmp     .exit
        _then .3
        _repeat .1

        _drop
        _f

.exit:
        pop     this_register
        next
endcode

; ### string-lines
code string_lines, 'string-lines'       ; string -- lines
        _ check_string

        push    r14
        mov     r14, 0

        push    this_register
        mov     this_register, rbx
        poprbx                          ; --

        _lit 10
        _ new_vector_untagged           ; -- vector

        _zero                           ; raw index of start of first line

        _this_string_raw_length
        _register_do_times .1

        ; check for lf
        _raw_loop_index
        _this_string_nth_unsafe
        _dup
        _eq? 10
        _tagged_if .2
        ; looking at lf
        _drop
        _raw_loop_index                 ; -- vector from to

        sub     rbx, r14                ; adjust for preceding cr if necessary
        mov     r14, 0

        _this_string_substring_unsafe   ; -- vector string
        _over
        _ vector_push                   ; -- vector

        _raw_loop_index
        _oneplus                        ; start of next line

        _else .2
        ; not lf
        _eq? 13
        _tagged_if .3
        ; looking at cr
        ; set up adjustment
        mov     r14, 1
        _else .3
        ; no adjustment necessary
        mov     r14, 0
        _then .3
        _then .2

        _loop .1                        ; -- from

        _this_string_raw_length         ; -- from to
        _twodup
        _ult_if .4
        _this_string_substring_unsafe
        _over
        _ vector_push
        _else .4
        _2drop
        _then .4

        pop     this_register

        pop     r14

        next
endcode
