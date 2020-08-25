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

%macro  _vocab_name 0                   ; vocab -- name
        _slot1
%endmacro

%macro  _this_vocab_name 0              ; -- name
        _this_slot1
%endmacro

%macro  _this_vocab_set_name 0          ; name --
        _this_set_slot1
%endmacro

%macro  _vocab_hashtable 0              ; vocab -- hashtable
        _slot2
%endmacro

%macro  _this_vocab_hashtable 0         ; -- hashtable
        _this_slot2
%endmacro

%macro  _vocab_set_hashtable 0          ; hashtable vocab --
        _set_slot2
%endmacro

%macro  _this_vocab_set_hashtable 0     ; hashtable --
        _this_set_slot2
%endmacro

; ### vocab?
code vocab?, 'vocab?'                 ; x -> x/nil
; If x is a vocab, returns x unchanged. If x is not a vocab, returns nil.
        cmp     bl, HANDLE_TAG
        jne     .not_a_vocab
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_VOCAB
        jne     .not_a_vocab
        next
.not_a_vocab:
        mov     ebx, NIL
        next
endcode

; ### verify_vocab
code verify_vocab, 'verify_vocab'       ; vocab -> vocab
; Returns argument unchanged.
        cmp     bl, HANDLE_TAG
        jne     .error
        mov     rax, rbx
        shr     rax, HANDLE_TAG_BITS
        mov     rax, [rax]
        cmp     word [rax], TYPECODE_VOCAB
        jne     .error
        next
.error:
        jmp     error_not_vocab
endcode

; ### check_vocab
code check_vocab, 'check_vocab'         ; vocab -> ^vocab
        cmp     bl, HANDLE_TAG
        jne     error_not_vocab
        mov     rax, rbx
        shr     rbx, HANDLE_TAG_BITS
        mov     rbx, [rbx]              ; rbx: ^vocab
        cmp     word [rbx], TYPECODE_VOCAB
        jne     .error
        next
.error:
        mov     rbx, rax
        jmp     error_not_vocab
        next
endcode

; ### error-not-vocab
code error_not_vocab, 'error-not-vocab' ; x ->
        _quote "a vocabulary"
        _ format_type_error
        next
endcode

; ### <vocab>
code new_vocab, '<vocab>'               ;  name -> vocab
; 3 cells (object header, name, hashtable)
        _lit 3
        _ raw_allocate_cells
        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_raw_typecode TYPECODE_VOCAB

        _this_vocab_set_name

        _lit 32
        _ new_hashtable_untagged
        _this_vocab_set_hashtable

        _symbol string_hashcode
        _ symbol_raw_code_address
        _this_vocab_hashtable
        _ hashtable_set_hash_function

%if 0
        ; Deleting a symbol breaks the current hashtable implementation if
        ; string= is the test function.
        ; Sep 23 2018 11:02 AM
        _symbol stringequal?            ; string= replaced by string=? May 3 2020 10:46 AM
        _ symbol_raw_code_address
        _this_vocab_hashtable
        _ hashtable_set_test_function
%endif

        pushrbx
        mov     rbx, this_register

        ; return handle
        _ new_handle

        pop     this_register
        next
endcode

; ### vocab-name
code vocab_name, 'vocab-name'           ; vocab -- name
        _ check_vocab
        _vocab_name
        next
endcode

; ### vocab-hashtable
code vocab_hashtable, 'vocab-hashtable' ; vocab -- hashtable
        _ check_vocab
        _vocab_hashtable
        next
endcode

; ### vocab-set-hashtable
code vocab_set_hashtable, 'vocab-set-hashtable', SYMBOL_PRIMITIVE | SYMBOL_PRIVATE
; hashtable vocab --
        _ check_vocab
        _swap
        _ verify_hashtable
        _swap
        _vocab_set_hashtable
        next
endcode

; ### vocab-words
code vocab_words, 'vocab-words'         ; vocab-spec -- seq
        _ lookup_vocab                  ; -- vocab/f
        _tagged_if .1
        _ vocab_hashtable
        _ hashtable_values
        _else .1
        _drop
        _error "not a vocabulary specifier"
        _then .1
        next
endcode

; ### vocab-empty?
code vocab_empty?, 'vocab-empty?'       ; vocab-spec -- ?
        _ lookup_vocab                  ; -- vocab/f
        _tagged_if .1
        _ vocab_hashtable
        _ hashtable_count
        _ zero?
        _else .1
        _drop
        _error "not a vocabulary specifier"
        _then .1
        next
endcode

; ### vocab-empty
code vocab_empty, 'vocab-empty'         ; vocab --
        _lit 32
        _ new_hashtable_untagged        ; -- vocab hashtable

        _symbol string_hashcode
        _ symbol_raw_code_address
        _over
        _ hashtable_set_hash_function

        _symbol stringequal?
        _ symbol_raw_code_address
        _over
        _ hashtable_set_test_function

        _swap
        _ vocab_set_hashtable

        next
endcode

; ### vocab-add-symbol
code vocab_add_symbol, 'vocab-add-symbol' ; symbol vocab -> void
        push    rbx
        mov     rbx, [rbp]
        _ symbol_name                   ; -> symbol symbol-name
        _dup
        pop     rbx                     ; -> symbol symbol-name vocab
        _ vocab_hashtable
        _ hashtable_set_at
        next
endcode

; ### vocab-find-name
code vocab_find_name, 'vocab-find-name' ; name vocab -- symbol/name ?
        _ lookup_vocab
        _tagged_if .1
        _ vocab_hashtable
        _ hashtable_at_star
        _then .1
        next
endcode

; ### ?lookup-symbol
code ?lookup_symbol, '?lookup-symbol'   ; name vocab-spec -- symbol/f
        _ lookup_vocab
        _tagged_if_not .1
        _nip
        _return
        _then .1

        _ vocab_hashtable
        _ hashtable_at
        next
endcode

; ### vocab->string
code vocab_to_string, 'vocab->string'   ; vocab -> string
        _dup
        _ vocab_name
        _swap
        _ object_address
        _ to_hex
        _quote `<vocab \"%s\" 0x%s>`
        _ format
        next
endcode
