; Copyright (C) 2017 Peter Graves <gnooth@gmail.com>

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

%macro  _boolean? 0                     ; x -- ?
        and     ebx, TAG_MASK
        mov     eax, t_value
        cmp     ebx, BOOLEAN_TAG
        mov     ebx, f_value
        cmove   ebx, eax
%endmacro

; ### boolean?
inline boolean?, 'boolean?'             ; x -- ?
        _boolean?
endinline

; ### boolean-equal?
code boolean_equal?, 'boolean-equal?'
        _dup
        _boolean?
        _tagged_if .1
        _eq?
        _return
        _then .1

        _drop
        mov     ebx, f_value

        next
endcode
