; Copyright (C) 2012-2015 Peter Graves <gnooth@gmail.com>

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

value pending_tokens, 'pending-tokens', 0

value pending_data, 'pending-data', 0

constant compilation_queue_capacity, 'compilation-queue-capacity', 16   ; space for 16 entries

value compilation_queue_size, 'compilation-queue-size', 0

; ### initialize-compilation-queue
code initialize_compilation_queue, 'initialize-compilation-queue'       ; --
        _ pending_tokens
        _zeq_if .1
        ; allocate bytes for the tokens
        _ compilation_queue_capacity
        _ dup
        _ allocate
        _ throw                         ; REVIEW
        _to pending_tokens
        ; cells for the data
        _cells
        _ allocate
        _ throw
        _to pending_data
        _then .1
        next
endcode

; ### .entry
code dot_entry, '.entry'                ; index --
        _ ?cr
        _ pending_tokens
        _overplus
        _cfetch
        _ dup
        _ dot
        _lit TOKEN_XT
        _ equal
        _if .1
        _ pending_data
        _ swap
        _cells
        _plus
        _fetch
        _toname
        _ dotid
        _else .1
        _ pending_data
        _ swap
        _cells
        _plus
        _fetch
        _ dot
        _then .1
        next
endcode

; ### convert-token-and-data
code convert_token_and_data, 'convert-token-and-data'                   ; token data --
        _ over                          ; -- token data token
        _lit TOKEN_XT
        _ equal
        _if .1                          ; -- token data
        _lit store_xt
        _ over
        _ equal
        _if .2
        _2drop
        _lit TOKEN_STORE
        _lit store_xt
        _return
        _then .2
        _then .1
        next
endcode

; ### add-compilation-queue-entry
code add_compilation_queue_entry, 'add-compilation-queue-entry'         ; token data --
        _ compilation_queue_size
        _ compilation_queue_capacity
        _ equal
        _if .1
        _ flush_compilation_queue
        _then .1                        ; -- token data

        _ ?cr
        _ dots

        _ convert_token_and_data

        _ ?cr
        _ dots

        _ pending_data
        _ compilation_queue_size
        _cells
        _plus
        _ store                         ; -- token

        _ pending_tokens
        _ compilation_queue_size
        _plus
        _ cstore

        _lit 1
        _plusto compilation_queue_size

        next
endcode


; ### clear-compilation-queue
code clear_compilation_queue, 'clear-compilation-queue'
        _zeroto compilation_queue_size
        next
endcode

; ### process-compilation-queue-entry
code process_compilation_queue_entry, 'process-compilation-queue-entry' ; index --
        _ dup
        _ pending_tokens
        _plus
        _cfetch                         ; -- index token

        _ dup
        _zeq_if .0                      ; zero in the token slot means NOP
        _2drop
        _return
        _then .0

        _ dup                           ; -- index token token
        _lit TOKEN_XT                   ; -- index token token TOKEN_XT
        _ equal                         ; -- index token flag
        _if .1                          ; -- index token
        _drop                           ; -- index
        _ pending_data
        _ swap
        _cells
        _plus
        _fetch                          ; -- xt
        _ inline_or_call_xt
        _return
        _then .1                        ; -- index token

        _ dup
        _lit TOKEN_LITERAL
        _ equal
        _if .2
        _drop
        _ pending_data
        _ swap
        _cells
        _plus
        _fetch                          ; value of literal
        _ iliteral
        _return
        _then .2                        ; -- index token

        ; otherwise ignore the token and compile the xt in the data field
        _ ?cr
        _dotq "here we go "
        _ dots
        _ drop
        _ pending_data
        _ swap
        _ ?cr
        _ dots
        _cells
        _plus
        _ ?cr
        _ dots
        _fetch                          ; -- xt
        _ inline_or_call_xt
;         ; shouldn't happen
;         _nip
;         _dotq "unknown token "
;         _ dot
        next
endcode

; ### flush-compilation-queue
code iflush_compilation_queue, '(flush-compilation-queue)'
        _ compilation_queue_size

        _ dup
        _if .0
        _ ?cr
        _dotq "flush-compilation-queue"
        _then .0

        _lit 0
        _?do .1
        _i
        _ dup
        _ dot_entry
        _ process_compilation_queue_entry
        _loop .1
        _zeroto compilation_queue_size
        next
endcode

deferred flush_compilation_queue, 'flush-compilation-queue', iflush_compilation_queue

; ### opt
value opt, 'opt', 0

; ### +opt
code plusopt, '+opt', IMMEDIATE   ; --
        _ initialize_compilation_queue
        mov     qword [opt_data], TRUE
        next
endcode

; ### -opt
code minusopt, '-opt', IMMEDIATE  ; --
        mov     qword [opt_data], FALSE
        _ flush_compilation_queue
        next
endcode
