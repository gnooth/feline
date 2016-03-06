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

; ### transient-area
value transient_area, 'transient_area', 0

; ### transient-area-next
value transient_area_next, 'transient-area-next', 0

; ### transient-area-limit
value transient_area_limit, 'transient-area-limit', 0

; ### transient-area-size
constant transient_area_size, 'transient-area-size', 16384 ; REVIEW size

; ### transient-alloc-max
constant transient_alloc_max, 'transient-alloc-max', 1024 ; REVIEW size

; ### initialize-transient-area
code initialize_transient_area, 'initialize-transient-area'
        _ transient_area_size
        _ iallocate
        _dup
        _to transient_area
        _to transient_area_next

        _ transient_area
        _ transient_area_size
        _plus
        _to transient_area_limit

        next
endcode

; ### transient-alloc
code transient_alloc, 'transient-alloc' ; u -- addr
        _ transient_area
        _zeq_if .1
        _ initialize_transient_area
        _then .1                        ; -- u

        _dup
        _ transient_alloc_max
        _ugt
        _abortq "transient-alloc requested size too big" ; FIXME error message

        _ transient_area_next
        _ aligned                       ; -- u a-addr1
        _twodup
        _plus                           ; -- u a-addr1 addr2
        _dup
        _ transient_area_limit
        _ult
        _if .3                          ; -- u a-addr1 addr2
        _to transient_area_next         ; -- u a-addr1
        _nip                            ; -- a-addr1
        _else .3                        ; -- u a-addr1 addr2
        _2drop                          ; -- u
        _ transient_area
        _plus
        _to transient_area_next
        _ transient_area                ; -- addr
        _then .3
        next
endcode
