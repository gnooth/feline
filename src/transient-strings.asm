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

; ### tsb
value tsb, 'tsb', 0

; ### tsb-next
value tsb_next, 'tsb-next', 0

; ### tsb-limit
value tsb_limit, 'tsb-limit', 0

; ### tsb-size
constant tsb_size, 'tsb-size', 16384    ; REVIEW size

; ### tsb-init
code tsb_init, 'tsb-init'
        _ tsb_size
        _ iallocate
        _dup
        _to tsb
        _to tsb_next

        _ tsb
        _ tsb_size
        _plus
        _to tsb_limit

        next
endcode

constant tsb_alloc_max, 'tsb-alloc-max', 1024   ; REVIEW size

; ### tsb-alloc
code tsb_alloc, 'tsb-alloc'             ; u -- addr
        _from tsb
        _zeq_if .1
        _ tsb_init
        _then .1                        ; -- u

        _dup
        _ tsb_alloc_max
        _ ugt
        _abortq "TSB-ALLOC requested size too big"      ; FIXME error message

        _from tsb_next
        _ aligned                       ; -- u a-addr1
        _twodup
        _plus                           ; -- u a-addr1 addr2
        _dup
        _from tsb_limit
        _ ult
        _if .3                          ; -- u a-addr1 addr2
        _to tsb_next                    ; -- u a-addr1
        _nip                            ; -- a-addr1
        _else .3                        ; -- u a-addr1 addr2
        _2drop                          ; -- u
        _from tsb
        _plus
        _to tsb_next
        _from tsb                       ; -- addr
        _then .3
        next
endcode
