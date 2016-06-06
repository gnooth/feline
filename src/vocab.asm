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

%macro  _vocab_name 0                   ; vocab -- name
        _slot1
%endmacro

%macro  _this_vocab_name 0              ; -- name
        _this_slot1
%endmacro

%macro  _this_vocab_set_name 0          ; name --
        _this_set_slot1
%endmacro

%macro  _this_vocab_hashtable 0         ; -- hashtable
        _this_slot2
%endmacro

%macro  _this_vocab_set_hashtable 0     ; hashtable --
        _this_set_slot2
%endmacro

%macro  _vocab_wordlist 0               ; vocab -- wordlist
        _slot3
%endmacro

%macro  _this_vocab_wordlist 0          ; -- wordlist
        _this_slot3
%endmacro

%macro  _vocab_set_wordlist 0           ; wordlist vocab --
        _swap
        _set_slot3
%endmacro

%macro  _this_vocab_set_wordlist 0      ; wordlist --
        _this_set_slot3
%endmacro

; ### vocab?
code vocab?, 'vocab?'                   ; handle -- t|f
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object
        _dup_if .2
        _object_type                    ; -- object-type
        _lit OBJECT_TYPE_VOCAB
        _eq?
        _return
        _then .2
        _then .1
        mov     ebx, f_value
        next
endcode

; ### error-not-vocab
code error_not_vocab, 'error-not-vocab' ; x --
        ; REVIEW
        _drop
        _true
        _abortq "not a vocab"
        next
endcode

; ### check-vocab
code check_vocab, 'check-vocab'         ; handle -- vocab
        _dup
        _ handle?
        _if .1
        _handle_to_object_unsafe        ; -- object|0
        _dup_if .2
        _dup
        _object_type                    ; -- object object-type
        _lit OBJECT_TYPE_VOCAB
        _equal
        _if .3
        _return
        _then .3
        _then .2
        _then .1

        _ error_not_vocab
        next
endcode

; ### <vocab>
code new_vocab, '<vocab>'               ;  name -- vocab
        _lit 4                          ; -- name 4
        _cells                          ; -- name 32
        _dup                            ; -- name 32 32
        _ allocate_object               ; -- name 32 object-address
        push    this_register
        mov     this_register, rbx      ; -- name 32 object-address
        _swap
        _ erase                         ; -- name

        _this_object_set_type OBJECT_TYPE_VOCAB

        _this_vocab_set_name

        _f
        _this_vocab_set_hashtable

        _f
        _this_vocab_set_wordlist

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

; ### vocab-wordlist
code vocab_wordlist, 'vocab-wordlist'   ; vocab -- wordlist
; Returns untagged wid.
        _ check_vocab
        _vocab_wordlist
        next
endcode

; ### vocab-set-wordlist
code vocab_set_wordlist, 'vocab-set-wordlist' ; wordlist vocab --
        _ check_vocab
        _vocab_set_wordlist
        next
endcode
