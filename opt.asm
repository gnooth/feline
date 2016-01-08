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

; Cached literals.

; ### cq-cached-literals
value cq_cached_literals, 'cq-cached-literals', 0

; ### cq-cached-literals-capacity
constant cq_cached_literals_capacity, 'cq-cached-literals-capacity', 1

; ### cq-lit1
; value cq_lit1, 'cq-lit1', 0
code cq_lit1, 'cq-lit1'
        _ cq_cached_literals
        _fetch
        next
endcode

; ### cq-#lits
value cq_nlits, 'cq-#lits', 0

; ### cq-flush-literals
code cq_flush_literals, 'cq-flush-literals'
        _ opt_debug
        _if .1
        _ ?cr
        _dotq "cq-flush-literals"
        _then .1

        _ cq_nlits
        _if .2
        _ cq_lit1
        _ iliteral
        _zeroto cq_nlits
        _then .2
        next
endcode

; ### cq-cache-literal
code cq_cache_literal, 'cq-cache-literal'       ; n --
        _ cq_nlits
        _if .1

        _ opt_debug
        _if .debug
        _ ?cr
        _dotq "cq-cache-literal calling cq-flush-literals"
        _then .debug

        _ cq_flush_literals
        _then .1
;         _to cq_lit1
        _ cq_cached_literals
        _ store

        _oneplusto cq_nlits
        next
endcode

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

; ### cq-length
value cq_length, 'cq-length', 0         ; number of entries in use

; ### cq-index
value cq_index, 'cq-index', 0

; ### cq-add-xt
code cq_add_xt, 'cq-add-xt'             ; xt --
        _ opt_debug
        _if .1
        _ ?cr
        _dotq "cq-add-xt "
        _dup
        _toname
        _ dotid
        _then .1

        _ cq_length
        _ cq_capacity
        _ equal
        _if .2
        _ cq_flush
;         _zeroto cq_length               ; FIXME should be done by cq_flush
;         _zeroto cq_index                ; FIXME should be done by cq_flush
        _then .2

        _ cq
        _ cq_index
        _ twostar
        _cells
        _plus
        _ store
        _oneplusto cq_index
        _oneplusto cq_length

;         _ opt_debug
;         _if .3
;         _ dotcq
;         _then .3

        next
endcode

; ### cq-add-literal
code cq_add_literal, 'cq-add-literal'   ; n --
        _ opt_debug
        _if .1
        _ ?cr
        _dotq "cq-add-literal "
        _dup
        _ dot
        _dup
        _ hdot
        _then .1

        _ cq_length
        _ cq_capacity
        _ equal
        _if .2
        _ cq_flush
;         _zeroto cq_length               ; FIXME should be done by cq_flush
;         _zeroto cq_index                ; FIXME should be done by cq_flush
        _then .2

        _ cq_lit                        ; token
        _ cq_index_entry
        _ store                         ; -- n

        _ cq_index_entry
        _cellplus
        _ store

        _oneplusto cq_index
        _oneplusto cq_length

;         _ opt_debug
;         _if .3
;         _ dotcq
;         _then .3

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
        _ cq_length
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
        _ cq_length
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
        _ cq_length
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
code cq_init, 'cq-init'                 ; --
        _ cq
        _zeq_if .1
        _ cq_cached_literals_capacity
        _cells
        _dup
        _ iallocate
        _to cq_cached_literals
        _ cq_cached_literals
        _ swap
        _ erase

        _ cq_capacity
        _twostar
        _cells
        _dup
        _ iallocate
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
        _zeroto cq_length
        _zeroto cq_index
        _ cq
        _ cq_capacity
        _twostar
        _cells
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

; ### .cq-entry
code dotcq_entry, '.cq-entry'           ; addr --
        _duptor
        _fetch                          ; -- xt or cq-lit
        _lit 4
        _ topos
        _dup
;         _lit 256
;         _ lt
        _ cq_lit
        _ equal
        _if .1
        _drop
        _dotq "cq_lit "
        _rfrom
        _cellplus
        _fetch
;         _lit 20
;         _ topos
        _ decdot
        _else .1
        _toname
        _ dotid
        _rfromdrop
        _then .1
        next
endcode

; ### cq-flush1
code cq_flush1, 'cq-flush1'
        _ opt_debug
        _if .debug
        _ ?cr
        _dotq "cq-flush1 "
        _ cq_first
        _dup
        _ cq_lit
        _ equal
        _if .debug1
        _drop
        _dotq "cq-lit "
        _ cq_first_data
        _ decdot
        _else .debug1
        _toname
        _ dotid
        _then .debug1
        _then .debug

        ; nop
        _ cq_first
        _ cq_nop
        _ equal
        _if .1
        _oneplusto cq_index
        _return
        _then .1

        ; literal
        _ cq_first
        _ cq_lit
        _ equal
        _if .2
        _ cq_first_data
        _ cq_cache_literal
        _oneplusto cq_index
        _return
        _then .2

        ; variable
        _ cq_first                      ; -- xt
        _totype
        _cfetch
        _ tvar
        _ equal
        _if .3
        _ cq_first
        _tobody
        _ cq_cache_literal
        _oneplusto cq_index
        _return
        _then .3

        ; constant
        _ cq_first
        _totype
        _cfetch
        _ tconst
        _ equal
        _if .4
        _ cq_first
        _ execute
        _ cq_cache_literal
        _oneplusto cq_index
        _return
        _then .4

        ; xt
        _ cq_first                      ; -- xt
        _ dup                           ; -- xt xt
        _tocomp                         ; -- xt >comp
        _fetch                          ; -- xt xt-comp
        _ ?dup
        _if .5
        _ execute
        _else .5

        _ opt_debug
        _if .6
        _ ?cr
        _dotq "cq-flush1 calling cq-flush-literals"
        _then .6

        _ cq_flush_literals
        _ inline_or_call_xt
        _oneplusto cq_index
        _then .5

        next
endcode

; ### .cq
code dotcq, '.cq'                       ; --
        _ ?cr
        _dotq "compilation queue:"

        _ cq
        _if .1
        _ cq_length
        _zero
        _?do .2
        _ ?cr
        _i
        _ cq_entry
        _ dotcq_entry
        _loop .2

        _ ?cr
        _dotq "cached literals:"
        _ cr
        _lit 4
        _ topos
        _ cq_nlits
        _if .3
        _ cq_lit1
        _ decdot
        _else .3
        _dotq "none"
        _then .3
        _then .1
        next
endcode

; ### cq-flush
code cq_flush, 'cq-flush'
        _ opt_debug
        _if .1
        _ ?cr
        _dotq "cq-flush"
        _ dotcq
        _then .1

        _ opt
        _if .2
        _zeroto cq_index
        _begin .3
        _ cq_index
        _ cq_length
        _ lt
        _while .3
        _ cq_flush1
        _repeat .3
        _ cq_clear

        _ opt_debug
        _if .debug
        _ ?cr
        _dotq "cq-flush calling cq-flush-literals"
        _then .debug

        _ cq_flush_literals
        _then .2
        next
endcode

; ### flush-compilation-queue
deferred flush_compilation_queue, 'flush-compilation-queue', noop

; ### opt
value opt, 'opt', 0

; ### +opt
code plus_opt, '+opt', IMMEDIATE   ; --
        _ cq_init
        _lit cq_flush_xt
        _lit flush_compilation_queue_xt
        _tobody
        _ store
        mov     qword [opt_data], TRUE
        next
endcode

; ### -opt
code minus_opt, '-opt', IMMEDIATE  ; --
        _ flush_compilation_queue
        _lit noop_xt
        _lit flush_compilation_queue_xt
        _tobody
        _ store
        mov     qword [opt_data], FALSE
        next
endcode

; ### opt-debug
value opt_debug, 'opt-debug', 0

; ### +opt-debug
inline plus_opt_debug, '+opt-debug'
        mov     qword [opt_debug_data], TRUE
endinline

; ### -opt-debug
inline minus_opt_debug, '-opt-debug'
        mov     qword [opt_debug_data], FALSE
endinline
