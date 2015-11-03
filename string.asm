; Copyright (C) 2015 Peter Graves <gnooth@gmail.com>

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

; Layout of a string object:
;
;                                Size   Offset
;                               ------  ------
; type                          1 cell     0
; capacity                      1 cell     8
; length                        1 cell    16
; address of character data     1 cell    24

%define OFFSET_TYPE              0
%define OFFSET_CAPACITY          8
%define OFFSET_LENGTH           16
%define OFFSET_DATA_ADDRESS     24

; ### string-length
inline string_length, 'string-length'   ; string -- n
        mov     rbx, [rbx + OFFSET_LENGTH]
endinline

; ### >string
code to_string, '>string'               ; c-addr u -- string
; construct a string object from a Forth string descriptor
; return address of string object
        _lit 4
        _cells
        _ iallocate
        _tor                            ; -- c-addr u           r: -- string
        _zero
        _rfetch
        _ store
        _ dup
        _rfetch
        _lit OFFSET_CAPACITY
        _ plus
        _ store
        _ dup
        _rfetch
        _lit OFFSET_LENGTH
        _ plus
        _ store                         ; -- c-addr u
        _ dup
        _oneplus                        ; terminal null byte
        _ iallocate                     ; -- c-addr u data-address
        _ dup
        _rfetch
        _lit OFFSET_DATA_ADDRESS
        _ plus
        _ store

        _ swap                          ; -- c-addr data-address u

        _ twodup
        _ plus
        _zero
        _ swap
        _ cstore

        _ cmove

        _ rfrom
        next
endcode

; ### string>
code string_from, 'string>'             ; string -- caddr u
;         mov     rax, [rbx + OFFSET_DATA_ADDRESS]
;         mov     rbx, [rbx + OFFSET_LENGTH]
;         pushrbx
;         mov     rbx, rax
;         _ swap
        mov     rax, rbx                ; address of string object in rax
        mov     rbx, [rax + OFFSET_DATA_ADDRESS]
        pushrbx
        mov     rbx, [rax + OFFSET_LENGTH]
        next
endcode

; ### ~string
code string_destroy, '~string'          ; string --
        _dup
        mov     rbx, [rbx]
        _ ifree
        _ ifree
        next
endcode

%undef OFFSET_TYPE
%undef OFFSET_CAPACITY
%undef OFFSET_LENGTH
%undef OFFSET_DATA_ADDRESS
