; Copyright (C) 2015-2021 Peter Graves <gnooth@gmail.com>

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

; Strings are immutable.

; 3 cells: object header, length, hashcode

%define STRING_RAW_LENGTH_OFFSET        8

%define STRING_HASHCODE_OFFSET          16

; inline character data (untagged) starts at offset 24
%define STRING_RAW_DATA_OFFSET          24

%macro  _string_raw_length 0            ; ^string -> raw-length
        _slot 1
%endmacro

%macro  _this_string_raw_length 0       ; -> raw-length
        _this_slot 1
%endmacro

%macro  _this_string_set_hashcode 0     ; fixnum -> void
        _this_set_slot 2
%endmacro

%macro  _this_string_substring_unsafe 0 ; from to -> substring
; no bounds checking
        sub     rbx, qword [rbp]        ; length (in rbx) = to - from
        lea     rax, [this_register + STRING_RAW_DATA_OFFSET]   ; raw data address in rax
        add     qword [rbp], rax        ; start of substring = raw data address + from
        _ copy_to_string
%endmacro

; Strings store their character data inline starting at this + STRING_RAW_DATA_OFFSET bytes.
%macro  _string_raw_data_address 0
        lea     rbx, [rbx + STRING_RAW_DATA_OFFSET]
%endmacro

%macro  _this_string_raw_data_address 0
        _dup
        lea     rbx, [this_register + STRING_RAW_DATA_OFFSET]
%endmacro

%macro  _string_nth_unsafe 0            ; untagged-index ^string -> untagged-char
        mov     rax, qword [rbp]        ; rax: untagged index
        lea     rbp, [rbp + BYTES_PER_CELL] ; -> ^string
        movzx   ebx, byte [rbx + STRING_RAW_DATA_OFFSET + rax] ; -> untagged-char
%endmacro

%macro  _this_string_nth_unsafe 0       ; untagged-index -> untagged-char
        movzx   ebx, byte [this_register + STRING_RAW_DATA_OFFSET + rbx]
%endmacro

%macro  _string_first_unsafe 0
        movzx   ebx, byte [rbx + STRING_RAW_DATA_OFFSET]
%endmacro

; ### string?
code string?, 'string?'                 ; x -> x/nil
        cmp     bl, HANDLE_TAG
        jne     .1
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_STRING
        jne     .no
        next
.1:
        cmp     bl, STATIC_STRING_TAG
        jne     .no
        next
.no:
        mov     ebx, NIL
        next
endcode

; ### check_string
code check_string, 'check_string'       ; x -> ^string
        cmp     bl, HANDLE_TAG
        jne     .1
        mov     rax, rbx                ; save x in rax for error reporting
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]              ; -> ^string
        cmp     word [rbx], TYPECODE_STRING
        jne     .error
        next
.1:
        cmp     bl, STATIC_STRING_TAG
        jne     error_not_string
        _untag_static_string
        next
.error:
        mov     rbx, rax                ; retrieve x
        _ error_not_string
        next
endcode

; ### error-not-string
code error_not_string, 'error-not-string' ; x ->
        _quote "a string"
        _ format_type_error
        next
endcode

; ### verify-string
code verify_string, 'verify-string'     ; string -> string
; returns argument unchanged
        cmp     bl, HANDLE_TAG
        jne     .1
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
%ifdef DEBUG
        test    rax, rax
        jz      error_empty_handle
%endif
        cmp     word [rax], TYPECODE_STRING
        jne     error_not_string
        next
.1:
        cmp     bl, STATIC_STRING_TAG
        jne     error_not_string
        next
endcode

; ### string_raw_address_unsafe
code string_raw_address_unsafe, 'string_raw_address_unsafe'
        cmp     bl, HANDLE_TAG
        jne     .1
        _handle_to_object_unsafe
        next
.1:
        _untag_static_string
        next
endcode

; ### string-address
code string_address, 'string-address'   ; string -> ^string
        _ check_string
        _tag_fixnum
        next
endcode

; ### string_raw_length
code string_raw_length, 'string_raw_length', SYMBOL_INTERNAL ; string -> raw-length
        _ check_string
        _string_raw_length
        next
endcode

; ### string-length
code string_length, 'string-length'     ; string -> length
        _ check_string
        _string_raw_length
        _tag_fixnum
        next
endcode

; ### string-length-unsafe
code string_length_unsafe, 'string-length-unsafe' ; string -> length
        cmp     bl, HANDLE_TAG
        jne     .1
        _handle_to_object_unsafe
        _string_raw_length
        _tag_fixnum
        next
.1:
        _untag_static_string
        _string_raw_length
        _tag_fixnum
        next
endcode

; ### string-empty?
code string_empty?, 'string-empty?'     ; string -> ?
        _ check_string
        _string_raw_length
        test    rbx, rbx
        jz      .1
        mov     ebx, NIL
        next
.1:
        mov     ebx, TRUE
        next
endcode

; ### string_raw_data_address
code string_raw_data_address, 'string_raw_data_address', SYMBOL_INTERNAL ; string -> raw-data-address
        _ check_string
        _string_raw_data_address
        next
endcode

; ### unsafe-string-data-address
code unsafe_string_data_address, 'unsafe-string-data-address' ; string -> address
        _ check_string
        _string_raw_data_address
        _tag_fixnum
        next
endcode

; ### copy_to_string
code copy_to_string, 'copy_to_string', SYMBOL_INTERNAL
; source-address source-length -> string
; arguments are untagged

        mov     arg0_register, STRING_RAW_DATA_OFFSET
        add     arg0_register, rbx      ; add source length
        inc     arg0_register           ; +1 for terminal null byte
        _ feline_malloc                 ; returns untagged allocated address in rax

        push    this_register
        mov     this_register, rax      ; -> source-address source-length

        mov     qword [this_register], 0
        mov     qword [this_register], TYPECODE_STRING
        mov     qword [this_register + STRING_HASHCODE_OFFSET], NIL
        mov     qword [this_register + STRING_RAW_LENGTH_OFFSET], rbx
        _drop                           ; -> source address (in rbx)

        mov     arg0_register, rbx      ; source address
        lea     arg1_register, [this_register + STRING_RAW_DATA_OFFSET] ; destination address
        mov     arg2_register, [this_register + STRING_RAW_LENGTH_OFFSET] ; length
        _ copy_bytes

        ; store terminal null byte
        mov     rdx, [this_register + STRING_RAW_LENGTH_OFFSET]
        lea     rax, [this_register + STRING_RAW_DATA_OFFSET]
        mov     byte [rax + rdx], 0

        mov     rbx, this_register      ; -> ^string

        _ new_handle                    ; -> handle

        pop     this_register
        next
endcode

; ### alien->string
code alien_to_string, 'alien->string'   ; alien -> string
; make a Feline string from a C string at the specified address
        _ integer_to_raw_bits
        _ zcount
        _ copy_to_string
        next
endcode

; ### string_from
code string_from, 'string_from', SYMBOL_INTERNAL ; string -> raw-data-address raw-length
        _ check_string
        mov     rax, [rbx + STRING_RAW_LENGTH_OFFSET]   ; raw length in rax
        lea     rbx, [rbx + STRING_RAW_DATA_OFFSET]     ; raw data address in rbx
        _dup
        mov     rbx, rax
        next
endcode

; ### hash-string
code hash_string, 'hash-string'         ; string -> fixnum
; Hash function adapted from SBCL.

        _ check_string                  ; -> ^string

hash_string_unchecked:
        push    this_register
        mov     this_register, rbx
        _drop

        _zero                           ; -> accumulator

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

        mov     rax, MOST_POSITIVE_FIXNUM
        and     rbx, rax

        _tag_fixnum
        mov     qword [this_register + STRING_HASHCODE_OFFSET], rbx

        pop     this_register
        next
endcode

; ### string-hashcode
code string_hashcode, 'string-hashcode' ; handle-or-string -> fixnum
        _ check_string
        mov     rax, [rbx + STRING_HASHCODE_OFFSET]
        cmp     rax, NIL
        jz      .1
        mov     rbx, rax
        next
.1:
        ; -> ^string
        _ hash_string_unchecked         ; -> hashcode
        next
endcode

; ### string-nth-unsafe
code string_nth_unsafe, 'string-nth-unsafe' ; index string -> char
; returns char at index
; no bounds checking
        _ check_string                  ; -> tagged-index ^string
        mov     rax, qword [rbp]        ; rax: index
        _nip                            ; rbx: tagged index
        sar     rax, FIXNUM_TAG_BITS
        movzx   ebx, byte [rbx + STRING_RAW_DATA_OFFSET + rax]
        _tag_char
        next
endcode

; ### string-nth
code string_nth, 'string-nth'           ; index string -> char
; returns char at index
        _ check_string                  ; -> tagged-index ^string
        mov     rdx, rbx                ; rdx: ^string
        _drop                           ; rbx: tagged index
        test    bl, FIXNUM_TAG
        jz      error_not_fixnum
        sar     rbx, FIXNUM_TAG_BITS    ; rbx: raw index
        cmp     rbx, [rdx + STRING_RAW_LENGTH_OFFSET]
        jnc     error_string_index_out_of_bounds
        movzx   ebx, byte [rdx + STRING_RAW_DATA_OFFSET + rbx]
        _tag_char
        next
endcode

; ### string-first-char
code string_first_char, 'string-first-char' ; string -> char
; returns first byte of string
; error if string is empty
        _ check_string
        cmp     qword [rbx + STRING_RAW_LENGTH_OFFSET], 0
        je      error_string_index_out_of_bounds
        movzx   ebx, byte [rbx + STRING_RAW_DATA_OFFSET]
        _tag_char
        next
endcode

; ### string-?first
code string_?first, 'string-?first'     ; string -> char/nil
; returns first byte of string
; returns nil if string is empty
        _ check_string
        cmp     qword [rbx + STRING_RAW_LENGTH_OFFSET], 0
        je      .empty
        movzx   ebx, byte [rbx + STRING_RAW_DATA_OFFSET]
        _tag_char
        next
.empty:
        mov     ebx, NIL
        next
endcode

; ### string-last-char
code string_last_char, 'string-last-char' ; string -> char
; returns last byte of string
; error if string is empty
        _ check_string
        mov     rax, [rbx + STRING_RAW_LENGTH_OFFSET]
        sub     rax, 1
        js      error_string_index_out_of_bounds
        movzx   ebx, byte [rbx + STRING_RAW_DATA_OFFSET + rax]
        _tag_char
        next
endcode

; ### string-?last
code string_?last, 'string-?last'       ; string -> char/nil
; returns last byte of string
; returns nil if string is empty
        _ check_string
        mov     rax, [rbx + STRING_RAW_LENGTH_OFFSET]
        sub     rax, 1
        js      .empty
        movzx   ebx, byte [rbx + STRING_RAW_DATA_OFFSET + rax]
        _tag_char
        next
.empty:
        mov     ebx, NIL
        next
endcode

; ### string-find-char
code string_find_char, 'string-find-char'       ; char string -- index/nil

        _ check_string

        push    this_register
        mov     this_register, rbx
        _drop

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
        _nil
.exit:
        pop     this_register
        next
endcode

; ### string-find-char-from-index
code string_find_char_from_index, 'string-find-char-from-index'
; index char string -> index/nil

        _ check_string

        push    this_register
        mov     this_register, rbx
        _drop                           ; -> tagged-index tagged-char

        _check_char                     ; -> tagged-index untagged-char

        _swap
        _check_index                    ; -> untagged-char untagged-start-index

        ; is start index (in rbx) >= length?
        cmp     rbx, [this_register + STRING_RAW_LENGTH_OFFSET]
        jge     .exit2

        %define limit_register  rax
        %define index_register  rdx

        mov     limit_register, [this_register + STRING_RAW_LENGTH_OFFSET]
        mov     index_register, rbx
        _drop
        jmp     .loop

.exit2:
        ; not found
        _nip
        pop     this_register
        mov     ebx, NIL
        next

        align   DEFAULT_CODE_ALIGNMENT
.loop:
        cmp     bl, byte [this_register + STRING_RAW_DATA_OFFSET + index_register]
        je      .found
        add     index_register, 1
        cmp     index_register, limit_register
        je      .exit

        cmp     bl, byte [this_register + STRING_RAW_DATA_OFFSET + index_register]
        je      .found
        add     index_register, 1
        cmp     index_register, limit_register
        je      .exit

        cmp     bl, byte [this_register + STRING_RAW_DATA_OFFSET + index_register]
        je      .found
        add     index_register, 1
        cmp     index_register, limit_register
        je      .exit

        cmp     bl, byte [this_register + STRING_RAW_DATA_OFFSET + index_register]
        je      .found
        add     index_register, 1
        cmp     index_register, limit_register
        je      .exit

        jmp     .loop

.found:
        mov     rbx, index_register
        shl     rbx, 1
        or      rbx, 1
        pop     this_register
        next

.exit:
        ; not found
        pop     this_register
        mov     ebx, NIL
        next

        %undef  limit_register
        %undef  index_register
endcode

; ### string-validate-slice
code string_validate_slice, 'string-validate-slice'
; from to string -> from to string
        push    rbx
        _ string_raw_length
        mov     rax, rbx                ; rax: length
        pop     rbx                     ; rbx: string

        ; -> from to string
        mov     rcx, [rbp + BYTES_PER_CELL]     ; rcx: from
        test    cl, FIXNUM_TAG
        jz      .error1
        sar     rcx, FIXNUM_TAG_BITS
        js      .error2

        mov     rdx, [rbp]                      ; rdx: to
        test    dl, FIXNUM_TAG
        jz      .error3
        sar     rdx, FIXNUM_TAG_BITS
        js      .error4

        cmp     rdx, rax                ; to must be <= length
        jg      .error5
        cmp     rcx, rdx                ; from must be <= to
        jg      .error6
        next

.error1:
        mov     rbx, rcx
        _2nip
        jmp     error_not_index
.error2:
        mov     rbx, rcx
        _tag_fixnum
        _2nip
        jmp     error_not_index
.error3:
        mov     rbx, rdx
        _2nip
        jmp     error_not_index
.error4:
        mov     rbx, rdx
        _tag_fixnum
        _2nip
        jmp     error_not_index
.error5:
        _drop
        _tag_fixnum rdx
        mov     [rbp], rdx
        mov     rbx, rax
        _tag_fixnum
        jmp     error_index_not_valid_for_string
.error6:
        _drop
        _tag_fixnum rdx
        mov     rbx, rdx
        _tag_fixnum rcx
        mov     [rbp], rcx
        _quote "ERROR: the start index (%d) must not be greater than the end index (%d)."
        _ format
        _ error
        next
endcode

; ### error-index-not-valid-for-string  ; index length -> void
code error_index_not_valid_for_string, 'error-index-not-valid-for-string'
        _quote "ERROR: the value %d is not a valid index for a string of length %d."
        _ format
        _ error
        next
endcode

; ### string-substring
code string_substring, 'string-substring' ; from to string -> substring
        _ string_validate_slice

        _ check_string                  ; -> from to ^string

        push    this_register
        mov     this_register, rbx      ; ^string in this_register
        _drop                           ; -> from to

        ; already validated by string-validate-slice
        _untag_2_fixnums

        _this_string_substring_unsafe   ; -> substring

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
        _ string_append
        _then .1
        next
endcode

; ### escaped
code escaped, 'escaped'                 ; -- string
        _quote 'abtnvfre"\'
        next
endcode

; ### unescaped
code unescaped, 'unescaped'             ; -- string
        _quote `\a\b\t\n\v\f\r\e\"\\`
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
        _ iterator_next                 ; -- iterator char/nil
        _dup
        _tagged_if .2                   ; -- iterator char

        _dup
        _ unescaped
        _ string_index                  ; -- iterator char index/nil
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

        _else .3                        ; -- iterator char nil

        _drop

        _rfetch
        _ sbuf_push

        _then .3

        _else .2                        ; -- iterator nil
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
code string_head, 'string-head'         ; n string -> substring
        _lit tagged_zero
        _ rrot
        _ string_substring
        next
endcode

; ### string-tail
code string_tail, 'string-tail'         ; n string -> substring
        _dup
        _ string_length
        _swap
        _ string_substring
        next
endcode

; ### string-has-prefix?
code string_has_prefix?, 'string-has-prefix?'   ; prefix string -> ?
        _ check_string
        _swap
        _ check_string                          ; -> ^string ^prefix

        mov     arg0_register, rbx              ; ^prefix in arg0_register
        mov     arg1_register, [rbp]            ; ^string in arg1_register
        mov     arg2_register, [arg0_register + STRING_RAW_LENGTH_OFFSET] ; prefix length
        _nip

        ; zero length prefix -> true
        test    arg2_register, arg2_register
        jz      .yes

        ; prefix length greater than string length -> nil
        cmp     arg2_register, [arg1_register + STRING_RAW_LENGTH_OFFSET]
        jg      .no

        lea     arg0_register, [arg0_register + STRING_RAW_DATA_OFFSET]
        lea     arg1_register, [arg1_register + STRING_RAW_DATA_OFFSET]
        xor     arg3_register, arg3_register

.loop:
        mov     al, [arg0_register + arg3_register]
        cmp     al, [arg1_register + arg3_register]
        jne     .no
        add     arg3_register, 1
        cmp     arg3_register, arg2_register
        jl      .loop

.yes:
        mov     ebx, TRUE
        next
.no:
        mov     ebx, NIL
        next
endcode

; ### string=?
code stringequal?, 'string=?'           ; x y -> ?
        _ check_string                  ; -> x ^y

        ; rbx: ^y
        push    rbx
        _drop                           ; -> x (in rbx)
        _ check_string                  ; rbx: ^x
        pop     rax                     ; rax: ^y

        cmp     rbx, rax
        jne     .1
        mov     ebx, TRUE
        next

.1:
        mov     rdx, [rbx + STRING_RAW_LENGTH_OFFSET]   ; rdx: x raw length
        cmp     rdx, [rax + STRING_RAW_LENGTH_OFFSET]   ; compare with y raw length
        jne     .no                                     ; must be the same length

        test    rdx, rdx                ; both zero length strings?
        jz      .yes

        lea     r8, [rbx + STRING_RAW_DATA_OFFSET]      ; r8: x raw data address
        lea     r9, [rax + STRING_RAW_DATA_OFFSET]      ; r9: y raw data address

        xor     ecx, ecx                ; rcx: 0

.top:
        mov     al, [r8 + rcx]          ; al: char from x
        cmp     al, [r9 + rcx]          ; compare with char from y
        jne     .no
        add     rcx, 1
        cmp     rcx, rdx
        jne     .top
        ; fall through...

.yes:
        mov     ebx, TRUE
        next

.no:
        mov     ebx, NIL
        next
endcode

; ### string-ci=?
code string_ci_equal?, 'string-ci=?'    ; x y -> ?
        _ check_string                  ; -> x ^y

        ; rbx: ^y
        push    rbx
        _drop                           ; -> x (in rbx)
        _ check_string                  ; rbx: ^x
        pop     rax                     ; rax: ^y

        cmp     rbx, rax
        jne     .1
        mov     ebx, TRUE
        next

.1:
        ; rbx: ^x
        ; rax: ^y
        mov     rdx, [rbx + STRING_RAW_LENGTH_OFFSET]   ; rdx: x raw length
        cmp     rdx, [rax + STRING_RAW_LENGTH_OFFSET]   ; compare with y raw length
        jne     .no                                     ; must be the same length

        test    rdx, rdx                ; both zero length strings?
        jz      .yes

        lea     r8, [rbx + STRING_RAW_DATA_OFFSET]      ; r8: x raw data address
        lea     r9, [rax + STRING_RAW_DATA_OFFSET]      ; r9: y raw data address

        xor     ecx, ecx                ; rcx: 0

.top:
        mov     al, [r8 + rcx]          ; al: char from x
        cmp     al, [r9 + rcx]          ; compare with char from y
        jne     .ignore_case
        add     rcx, 1
        cmp     rcx, rdx
        jne     .top
        mov     ebx, TRUE
        next

.ignore_case:
        ; r8: x raw data address
        ; r9: y raw data address
        ; al: raw char from x
        mov     r10b, al                ; r10b: raw char from x
        mov     r11b, byte [r9 + rcx]   ; r11b: raw char from y

        sub     r10b, 'A'
        cmp     r10b, 25
        ja      .2
        ; char is upper case
        or      r10b, 0x20
.2:
        sub     r11b, 'A'
        cmp     r11b, 25
        ja      .3
        ; char is upper case
        or      r11b, 0x20
.3:
        cmp     r10b, r11b
        jne     .no
        add     rcx, 1
        cmp     rcx, rdx
        jne     .top
        ; fall through...

.yes:
        mov     ebx, TRUE
        next

.no:
        mov     ebx, NIL
        next
endcode

; ### substring-start
code substring_start, 'substring-start'         ; pattern string -> index/nil
        _ check_string                          ; -> pattern ^string

        push    this_register
        mov     this_register, rbx              ; ^string in this_register
        _drop                                   ; -> pattern

        _ check_string                          ; -> ^pattern (in rbx)

        ; return right away if pattern is longer than string
        mov     rax, [rbx + STRING_RAW_LENGTH_OFFSET] ; pattern raw length in rax
        mov     rdx, [this_register + STRING_RAW_LENGTH_OFFSET] ; string raw length in rdx
        cmp     rdx, rax
        jge     .1

        ; -> ^pattern
        mov     ebx, NIL
        pop     this_register
        next

.1:
        ; -> ^pattern
        ; rax: pattern raw length
        ; rdx: string raw length
        lea     rbx, [rbx + STRING_RAW_DATA_OFFSET]     ; -> pattern-raw-data-address
        _dup
        mov     rbx, rax                ; -> pattern-raw-data-address pattern-raw-length

        sub     rdx, rax
        add     rdx, 1
        _dup
        mov     rbx, rdx

        _register_do_times .2

        _this_string_raw_data_address   ; -> pattern-raw-data-address pattern-raw-length string-raw-data-address
        add     rbx, index_register

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
        _nil

.exit:
        pop     this_register
        next
endcode

; ### string-has-suffix?
code string_has_suffix?, 'string-has-suffix?'   ; suffix string -- ?
        _twodup
        _symbol string_length
        _ bi@                           ; -- suffix string len1 len2
        _twodup
        _ fixnum_fixnum_le
        _tagged_if .1
        _swap
        _ fixnum_minus
        _swap
        _ string_tail
        _ stringequal?
        _else .1
        _4drop
        _nil
        _then .1
        next
endcode

; ### string-skip-whitespace
code string_skip_whitespace, 'string-skip-whitespace' ; index string -> index/nil
        _ check_string

        mov     rdx, rbx                ; rdx: ^string
        _drop                           ; -> start=index

        test    bl, FIXNUM_TAG
        jz      error_not_index
        test    rbx, rbx
        js      error_not_index
        sar     rbx, FIXNUM_TAG_BITS    ; rbx: index (untagged)

        mov     rcx, [rdx + STRING_RAW_LENGTH_OFFSET]   ; rcx: length (untagged)

        cmp     rcx, rbx                ; is length in rcx > index in rbx?
        jng     .not_found              ; REVIEW should this be an error?

        ; rdx: ^string
        lea     rdx, [rdx + STRING_RAW_DATA_OFFSET]

.top:
        ; rdx: starting address of string raw data
        ; rbx: index
        cmp     byte [rdx + rbx], 0x20
        jg      .found

        add     rbx, 1
        cmp     rcx, rbx
        jg      .top

        ; reached end of string
        ; fall through...
.not_found:
        mov     ebx, NIL
        next

.found:
        ; rbx: index
        _tag_fixnum
        next
endcode

; ### string-skip-to-whitespace
code string_skip_to_whitespace, 'string-skip-to-whitespace' ; index string -> index/nil
        _ check_string

        mov     rdx, rbx                ; rdx: ^string
        _drop                           ; -> start=index

        test    bl, FIXNUM_TAG
        jz      error_not_index
        test    rbx, rbx
        js      error_not_index
        sar     rbx, FIXNUM_TAG_BITS    ; rbx: index (untagged)

        mov     rcx, [rdx + STRING_RAW_LENGTH_OFFSET]   ; rcx: length (untagged)

        cmp     rcx, rbx                ; is length in rcx > index in rbx?
        jng     .not_found              ; REVIEW should this be an error?

        ; rdx: ^string
        lea     rdx, [rdx + STRING_RAW_DATA_OFFSET]

.top:
        ; rdx: starting address of string raw data
        ; rbx: index
        cmp     byte [rdx + rbx], 0x20
        jle     .found

        add     rbx, 1
        cmp     rcx, rbx
        jg      .top

        ; reached end of string
        ; fall through...
.not_found:
        mov     ebx, NIL
        next

.found:
        ; rbx: index
        _tag_fixnum
        next
endcode

; ### string-index-from
code string_index_from, 'string-index-from'     ; char start-index string -- index/nil

        _ check_string

        push    this_register
        mov     this_register, rbx
        _drop

        _ check_index                   ; -- char untagged-start-index

        _this_string_raw_length
        cmp     rbx, [rbp]
        jnc     .1

        _2drop
        jmp     .not_found

.1:                                     ; -- char untagged-start-index untagged-length
        _check_char qword [rbp + BYTES_PER_CELL]
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
        jmp     .exit
.3:
        _loop .2

.not_found:
        ; not found
        mov     ebx, NIL

.exit:
        pop     this_register
        next
endcode

; ### string-index
code string_index, 'string-index'       ; char string -- index/nil
        _lit tagged_zero
        _swap
        _ string_index_from
        next
endcode

; ### string-last-index-from
code string_last_index_from, 'string-last-index-from'   ; char start-index string -- index/nil

        _ check_string

        push    this_register
        mov     this_register, rbx
        _drop

        _check_index                    ; -> char untagged-start-index

        cmp     rbx, [this_register + STRING_RAW_LENGTH_OFFSET]
        jge     .out_of_bounds

        push    r12
        mov     r12, rbx                ; untagged start index in r12
        _drop                           ; -> char

        _untag_char                     ; -> untagged-char

        align   DEFAULT_CODE_ALIGNMENT
.loop:
        cmp     bl, byte [r12 + this_register + STRING_RAW_DATA_OFFSET]
        je      .found
        sub     r12, 1
        jns     .loop

        ; not found
        mov     ebx, NIL
        pop     r12
        pop     this_register
        next

.found:
        mov     rbx, r12
        _tag_fixnum
        pop     r12
        pop     this_register
        next

.out_of_bounds:
        _nip
        mov     ebx, NIL
        pop     this_register
        next

endcode

; ### unsafe_raw_write_chars
code unsafe_raw_write_chars, 'unsafe_raw_write_chars', SYMBOL_INTERNAL
; raw-address raw-count --

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
        mov     [last_char_], rax

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

; ### string-append
code string_append, 'string-append'     ; string1 string2 -> string3
        _swap
        _ string_to_sbuf                ; -> string2 sbuf
        _tuck
        _ sbuf_append_string
        _ sbuf_to_string
        next
endcode

; ### string-append-char
code string_append_char, 'string-append-char' ; string char -> string'
        _swap
        _ string_to_sbuf                ; -> char sbuf
        _tuck
        _ sbuf_push
        _ sbuf_to_string
        next
endcode

; ### memequal
subroutine memequal
; arg0_register: untagged addr1
; arg1_register: untagged addr2
; arg2_register: untaqgged len
; returns TRUE or NIL in rax

        ; zero length -> true
        test    arg2_register, arg2_register
        jz      .yes

        xor     arg3_register, arg3_register

.loop:
        mov     al, byte [arg0_register + arg3_register]
        cmp     al, byte [arg1_register + arg3_register]
        jne     .no
        add     arg3_register, 1
        cmp     arg3_register, arg2_register
        jl     .loop

.yes:
        mov     eax, TRUE
        ret
.no:
        mov     eax, NIL
        ret
endsub

; ### unsafe_raw_memequal
code unsafe_raw_memequal, 'unsafe_raw_memequal', SYMBOL_INTERNAL
; addr1 addr2 len -> ?
        mov     arg0_register, [rbp + BYTES_PER_CELL]
        mov     arg1_register, [rbp]
        mov     arg2_register, rbx
        _2nip
        call    memequal
        mov     rbx, rax
        next
endcode

; ### unsafe-memequal
code unsafe_memequal, 'unsafe-memequal' ; address1 address2 length -> ?
        ; address1
        mov     rax, [rbp + BYTES_PER_CELL]
        test    al, FIXNUM_TAG
        jz      error_not_fixnum_rax
        _untag_fixnum rax
        mov     arg0_register, rax

        ; address2
        mov     rdx, [rbp]
        test    dl, FIXNUM_TAG
        jz      error_not_fixnum_rdx
        _untag_fixnum rdx
        mov     arg1_register, rdx

        ; length
        _check_fixnum
        mov     arg2_register, rbx

        _2nip
        call    memequal
        mov     rbx, rax

        next
endcode

; ### string-equal?
code string_equal?, 'string-equal?'     ; object1 object2 -> ?
; Returns true if both objects are strings and those strings are identical.
        _ string?                       ; -> object1 string/nil
        cmp     rbx, NIL
        jne     .1
        _nip
        next
.1:
        _swap
        _ string?
        cmp     rbx, NIL
        jne     stringequal?
        _nip
        next
endcode

; ### string-lines
code string_lines, 'string-lines'       ; string -> vector

        ; protect string from gc
        push    rbx

        _ check_string

        push    r14
        mov     r14, 0

        push    this_register
        mov     this_register, rbx
        _drop                           ; ->

        _lit 10
        _ new_vector_untagged           ; -> vector

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
        _raw_loop_index                 ; -> vector from to

        sub     rbx, r14                ; adjust for preceding cr if necessary
        mov     r14, 0

        _this_string_substring_unsafe   ; -> vector string
        _over
        _ vector_push                   ; -> vector

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

        _loop .1                        ; -> from

        _this_string_raw_length         ; -> from to
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

        ; drop string
        pop     rax

        next
endcode

; ### zstrlen
subroutine zstrlen                      ; raw-address -> raw-length
        mov     rcx, rbx
.1:
        mov     al, [rbx]
        test    al, al
        jz      .2
        inc     rbx
        jmp     .1
.2:
        sub     rbx, rcx
        next
endsub

; ### zcount
subroutine zcount                       ; raw-address -> raw-address raw-length
        _dup
        _ zstrlen
        next
endsub
