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

; A compilation queue entry consists of two cells: CAR (compilation address
; register) and CDR (compilation data register). For most words the CAR holds the
; word's xt. Since the xt is an address, we can use also very small numbers
; (arbitrarily, numbers < 10) in the CAR as tokens to indicate cq entries that
; need special handling. There won't be very many of these.

; ### cq-nop
constant cq_nop, 'cq-nop', 0            ; token indicates entry should be ignored

; ### cq-lit
constant cq_lit, 'cq-lit', 1            ; token indicates a literal value in the CDR

; ### cq-capacity
constant cq_capacity, 'cq-capacity', 16 ; space for 16 entries

; ### cq-size
value cq_size, 'cq-size', 0             ; number of entries in use

; ### cq-index
value cq_index, 'cq-index', 0

; ### cq-add-xt
code cq_add_xt, 'cq-add-xt'             ; xt --
        _ cq_size
        _ cq_capacity
        _ equal
        _if .1
        _ cq_flush
        _zeroto cq_size                 ; FIXME should be done by cq_flush
        _zeroto cq_index                ; FIXME should be done by cq_flush
        _then .1

        _ cq
        _ cq_index
        _ twostar
        _cells
        _plus
        _ store
        _lit 1
        _plusto cq_index
        _lit 1
        _plusto cq_size
        next
endcode

; ### cq-add-literal
code cq_add_literal, 'cq-add-literal'   ; n --
;         _ ?cr
;         _dotq "cq-add-literal "
;         _ dup
;         _ decdot

        _ cq_size
        _ cq_capacity
        _ equal
        _if .1
        _ cq_flush
        _zeroto cq_size                 ; FIXME should be done by cq_flush
        _zeroto cq_index                ; FIXME should be done by cq_flush
        _then .1

        _ cq_lit                        ; token
;         _ cq
;         _ cq_index
;         _cells
;         _plus
        _ cq_index_entry
        _ store                         ; -- n

;         _ cq
;         _ cq_index
;         _oneplus
;         _cells
;         _plus
        _ cq_index_entry
        _cellplus
        _ store

        _lit 1
        _plusto cq_index
        _lit 1
        _plusto cq_size
        next
endcode

; ### cq-entry
code cq_entry, 'cq-entry'               ; index -- addr
; returns address of entry pointed to by index
        _ cq
        _ swap
        _ twostar
        _cells
        _plus
        next
endcode

; ### cq-index-entry
code cq_index_entry, 'cq-index-entry'   ; -- addr
; returns address of entry pointed to by cq-index
        _ cq_index
        _ cq_entry
        next
endcode

; ### cq-first
code cq_first, 'cq-first'               ; -- x
; returns contents of CAR of first unprocessed cq entry
; returns 0 if there are no unprocessed entries
        _ cq_index
        _ cq_size
        _ lt
        _if .1
        _ cq_index_entry
        _fetch
        _else .1
        _zero
        _then .1
        next
endcode

; ### cq-first-data
code cq_first_data, 'cq-first-data'     ; -- x
; returns contents of CDR of first unprocessed cq entry
        _ cq_index
        _ cq_size
        _ lt
        _if .1
        _ cq_index_entry
        _cellplus
        _fetch
        _else .1
        _lit 1000                       ; REVIEW
        _ throw
        _then .1
        next
endcode

; ### cq-second
code cq_second, 'cq-second'
; returns contents of CAR of second unprocessed cq entry
; returns 0 if there are not at least 2 unprocessed entries
        _ cq_index
        _oneplus
        _ dup
        _ cq_size
        _ lt
        _if .1
        _ cq_entry
        _fetch
        _else .1
        _drop
        _zero
        _then .1
        next
endcode

; ### cq
value cq, 'cq', 0                       ; address of compilation queue

; ### cq-init
code cq_init, 'cq-init'       ; --
        _ cq
        _zeq_if .1
        _ cq_capacity
        _twostar
        _cells
        _ dup
        _ allocate
        _lit -59                        ; ALLOCATE error
        _ ?throw
        _to cq
        _ cq
        _ swap
        _ erase
        _then .1
        next
endcode

; ### cq-clear
code cq_clear, 'cq-clear'
        _ cq
        _if .1
        _zeroto cq_size
        _zeroto cq_index
        _ cq
        _ cq_capacity
        _ twostar
        _ cells
        _ erase
        _then .1
        next
endcode

; ### .first
; TEMPORARY
code dot_first, '.first'
        _ ?cr
        _dotq "cq_first = "
        _ cq_first
        _if .1
        _ cq_first
        _ decdot
        _ cq_index_entry
        _cellplus
        _ fetch
        _ decdot
        _else .1
        _zero
        _ dot
        _then .1
        next
endcode

; ### cq-flush1
code cq_flush1, 'cq-flush1'
;         _ dot_first

        _ cq_first
        _ cq_nop
        _ equal
        _if .1
        _lit 1
        _plusto cq_index
        _return
        _then .1

        _ cq_first
        _ cq_lit
        _ equal
        _if .2
        _ cq_first_data
        _ iliteral
        _lit 1
        _plusto cq_index
        _return
        _then .2

        _ cq_first                      ; -- xt
        _ dup                           ; -- xt xt
        _tocomp                         ; -- xt >comp
        _fetch                          ; -- xt xt-comp
        _ ?dup
        _if .3
        _ execute
        _else .3
        _ inline_or_call_xt
        _lit 1
        _plusto cq_index
        _then .3

;         _ cq_first
;         _ inline_or_call_xt
;         _lit 1
;         _plusto cq_index

        next
endcode

; TEMPORARY
code dotcq, '.cq'
        _ cq
        _if .1
        _ cq_capacity
        _zero
        _?do .2
        _ ?cr
        _ cq
        _i
        _ twostar
        _cells
        _plus
        _fetch
        _ decdot
        _lit 16
        _ topos
        _ cq
        _i
        _ twostar
        _cells
        _plus
        _cellplus
        _fetch
        _ decdot
        _loop .2
        _then .1
        next
endcode

; ### cq-flush
code cq_flush, 'cq-flush'
        _ opt
        _if .0

;         _ ?cr
;         _dotq "cq-flush size = "
;         _ cq_size
;         _ decdot

;         _ dotcq

        _zeroto cq_index
        _begin .1
        _ cq_index
        _ cq_size
        _ lt
        _while .1
        _ cq_flush1
        _repeat .1

        _ cq_clear

        _then .0
        next
endcode

; ### flush-compilation-queue
deferred flush_compilation_queue, 'flush-compilation-queue', cq_flush

; ### opt
value opt, 'opt', 0

; ### +opt
code plusopt, '+opt', IMMEDIATE   ; --
        _ cq_init
        mov     qword [opt_data], TRUE
        next
endcode

; ### -opt
code minusopt, '-opt', IMMEDIATE  ; --
        _ flush_compilation_queue
        mov     qword [opt_data], FALSE
        next
endcode
