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

; ### cq_nop
constant cq_nop, 'cq-nop', 0            ; token indicates entry should be ignored

; ### cq_lit
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
        _ cq_size
        _ cq_capacity
        _ equal
        _if .1
        _ cq_flush
        _zeroto cq_size                 ; FIXME should be done by cq_flush
        _zeroto cq_index                ; FIXME should be done by cq_flush
        _then .1

        _ cq_lit                        ; token
        _ cq
        _ cq_index
        _cells
        _plus
        _ store                         ; -- n

        _ cq
        _ cq_index
        _oneplus
        _cells
        _plus
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
        _zeroto cq_size
        next
endcode

; ### cq-flush
code cq_flush, 'cq-flush'
        _ true
        _abortq "cq-flush needs code"
        next
endcode

; ### flush-compilation-queue
deferred flush_compilation_queue, 'flush-compilation-queue', noop

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
        mov     qword [opt_data], FALSE
        _ flush_compilation_queue
        next
endcode
