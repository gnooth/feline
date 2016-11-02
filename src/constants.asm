; Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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

; ### feline?
constant feline?, 'feline?', -1

; Types

; ### tvar
constant tvar, 'tvar', TYPE_VARIABLE
; ### tvalue
constant tvalue, 'tvalue', TYPE_VALUE
; ### t2value
constant t2value, 't2value', TYPE_2VALUE
; ### tdefer
constant tdefer, 'tdefer', TYPE_DEFERRED
; ### tconst
constant tconst, 'tconst', TYPE_CONSTANT

; ### false
constant false, 'false', 0              ; CORE EXT

; ### true
constant true, 'true', -1               ; CORE EXT

; ### bl
constant blchar, 'bl', 32               ; CORE

; ### cell
constant cell, 'cell', BYTES_PER_CELL   ; not in standard

; ### min-int32
constant min_int32, 'min-int32', -2147483648

; ### max-int32
constant max_int32, 'max-int32', 2147483647

; ### max-int64
constant max_int64, 'max-int64', $7fffffffffffffff

; ### min-int64
constant min_int64, 'min-int64', $8000000000000000

; ### linux?
code linux?, 'linux?'
        pushrbx
%ifdef WIN64
        xor     ebx, ebx
%else
        mov     rbx, -1
%endif
        next
endcode

; ### windows?
code windows?, 'windows?'
        pushrbx
%ifdef WIN64
        mov     rbx, -1
%else
        xor     ebx, ebx
%endif
        next
endcode

; ### windows-ui?
code windows_ui?, 'windows-ui?'
        pushrbx
%ifdef WINDOWS_UI
        mov     rbx, -1
%else
        xor     ebx, ebx
%endif
        next
endcode

; ### r/o
%ifdef WIN64_NATIVE
constant readonly, 'r/o', GENERIC_READ
%else
constant readonly, 'r/o', 0
%endif

; ### w/o
%ifdef WIN64_NATIVE
constant writeonly, 'w/o', GENERIC_WRITE
%else
constant writeonly, 'w/o', 1
%endif

; ### r/w
%ifdef WIN64_NATIVE
constant readwrite, 'r/w', GENERIC_READ | GENERIC_WRITE
%else
constant readwrite, 'r/w', 2
%endif
