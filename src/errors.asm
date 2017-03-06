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

; ### error-not-number
code error_not_number, 'error-not-number'       ; x --
        _quote "The value %s is not a number."
        _ format
        _ error
        next
endcode

; ### error-not-fixnum
code error_not_fixnum, 'error-not-fixnum'       ; x --
        _quote "The value %s is not a fixnum."
        _ format
        _ error
        next
endcode

; ### error-not-float
code error_not_float, 'error-not-float'         ; x --
        _quote "The value %s is not a float."
        _ format
        _ error
        next
endcode

; ### error-not-char
code error_not_char, 'error-not-char'           ; x --
        _quote "The value %s is not a character."
        _ format
        _ error
        next
endcode
