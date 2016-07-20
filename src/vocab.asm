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

%macro  _vocab_hashtable 0              ; vocab -- hashtable
        _slot2
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

; ### verify-vocab
code verify_vocab, 'verify-vocab'       ; handle-or-vocab -- handle-or-vocab
; Returns argument unchanged.
        _dup
        _ handle?
        _if .1
        _dup
        _handle_to_object_unsafe        ; -- handle object|0
        _dup_if .2
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
; 4 cells (object header, name, hashtable, wordlist)
        _lit 4
        _ allocate_cells
        push    this_register
        mov     this_register, rbx
        poprbx

        _this_object_set_type OBJECT_TYPE_VOCAB

        _this_vocab_set_name

        _lit 32
        _ new_hashtable_untagged
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

; ### vocab-hashtable
code vocab_hashtable, 'vocab-hashtable' ; vocab -- hashtable
        _ check_vocab
        _vocab_hashtable
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

; ### vocab-add-symbol
code vocab_add_symbol, 'vocab-add-symbol' ; symbol vocab --
        _tor
        _dup
        _ symbol_name                   ; -- symbol name        r: -- vocab
        _rfrom
        _ vocab_hashtable
        _ set_at
        next
endcode

; ### vocab-add-name
code vocab_add_name, 'vocab-add-name'   ; nfa vocab ---
        _tor
        _dup
        _namefrom                       ; -- nfa xt
        _swap                           ; -- xt nfa
        _count
        _ copy_to_string                ; -- xt string
        _rfetch                         ; -- xt string vocab
        _ new_symbol                    ; -- xt symbol
        _tuck                           ; -- symbol xt symbol
        _ symbol_set_xt                 ; -- symbol
        _rfrom
        _ vocab_add_symbol
        next
endcode

; ### hash-vocab
code hash_vocab, 'hash-vocab'           ; vocab --
        _duptor
        _ vocab_wordlist
        _begin .1
        _fetch
        _ ?dup
        _while .1
        _dup
        _rfetch
        _ vocab_add_name
        _name_to_link
        _repeat .1
        _rdrop
        next
endcode

; ### intern
code intern, 'intern'                   ; name vocab -- symbol
        _twodup
        _ check_vocab
        _vocab_hashtable
        _ at_star
        _tagged_if .1
        _2nip
        _return
        _else .1
        _drop
        _then .1                        ; -- name vocab

        _duptor                         ; -- name vocab         r: -- vocab
        _ new_symbol                    ; -- symbol
        _dup
        _rfrom                          ; -- symbol symbol vocab
        _ vocab_add_symbol              ; -- symbol

        next
endcode

; ### lookup-symbol
code lookup_symbol, 'lookup-symbol'     ; name vocab-name -- symbol/f
        _ lookup_vocab
        _dup
        _tagged_if_not .1
        _nip
        _return
        _then .1

        _ vocab_hashtable
        _ at_
        next
endcode
