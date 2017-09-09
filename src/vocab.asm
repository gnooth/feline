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
code vocab?, 'vocab?'                   ; handle -- ?
        _ deref                         ; -- raw-object/0
        test    rbx, rbx
        jz      .1
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_VOCAB
        jne     .1
        mov     ebx, t_value
        _return
.1:
        mov     ebx, f_value
        next
endcode

; ### verify_vocab
code verify_vocab, 'verify_vocab'       ; handle -- handle
; returns argument unchanged
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_VOCAB
        jne     .error
        _drop
        next
.error:
        _drop
        _ error_not_vocab
        next
endcode

; ### check_vocab
code check_vocab, 'check_vocab', SYMBOL_INTERNAL        ; handle -- vocab
        _dup
        _ deref
        test    rbx, rbx
        jz      .error
        _object_raw_typecode_eax
        cmp     eax, TYPECODE_VOCAB
        jne     .error
        _nip
        next
.error:
        _drop
        _ error_not_vocab
        next
endcode

; ### <vocab>
code new_vocab, '<vocab>'               ;  name -- vocab
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

        _lit S_string_hashcode
        _ symbol_raw_code_address
        _this_vocab_hashtable
        _ hashtable_set_hash_function

        _lit S_stringequal
        _ symbol_raw_code_address
        _this_vocab_hashtable
        _ hashtable_set_test_function

        pushrbx
        mov     rbx, this_register      ; -- vocab

        ; Return handle.
        _ new_handle                    ; -- handle

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

        _lit S_string_hashcode
        _ symbol_raw_code_address
        _over
        _ hashtable_set_hash_function

        _lit S_stringequal
        _ symbol_raw_code_address
        _over
        _ hashtable_set_test_function

        _swap
        _ vocab_set_hashtable

        next
endcode

; ### vocab-add-symbol
code vocab_add_symbol, 'vocab-add-symbol' ; symbol vocab --
        _tor
        _dup
        _ symbol_name                   ; -- symbol name        r: -- vocab
        _rfrom
        _ vocab_hashtable
        _ hashtable_set_at
        next
endcode

; ### ensure-symbol
code ensure_symbol, 'ensure-symbol'     ; name vocab-spec -- symbol
        _ lookup_vocab
        _tagged_if_not .1
        _drop
        _error "vocab not found"
        _then .1

        _twodup
        _ vocab_hashtable
        _ hashtable_at
        _dup
        _tagged_if .2
        _2nip
        _return
        _else .2
        _drop
        _then .2                        ; -- name vocab

        _ create_symbol                 ; -- symbol

        _dup
        _ set_last_word

        next
endcode

; ### ensure-global
code ensure_global, 'ensure-global'     ; name --
; Ensure that there is a global with the given name in the current vocab.

        _dup
        _ current_vocab
        _ vocab_hashtable
        _ hashtable_at                  ; -- name symbol/f
        _dup
        _tagged_if .2                   ; -- name symbol
        _dup
        _ symbol_global?
        _tagged_if .3                   ; -- name symbol
        _2drop
        _return
        _then .3
        _then .2                        ; -- name f

        _drop

        _ current_vocab
        _ new_symbol                    ; -- handle

        _dup
        _handle_to_object_unsafe
        _dup
        _symbol_flags
        or      rbx, SYMBOL_GLOBAL
        _swap
        _symbol_set_flags               ; -- handle

        _dup
        _ new_wrapper
        _lit S_symbol_value
        _ two_array
        _ array_to_quotation
        _over
        _ symbol_set_def

        _dup
        _ compile_word

        _ set_last_word

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
