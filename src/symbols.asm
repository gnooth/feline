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

%macro  symbol 2                        ; label, name
        head    %1, %2, 0, %1_ret - %1
        section .data
        align   DEFAULT_DATA_ALIGNMENT
%1_handle:
        section .text
%1:
        pushrbx
        mov     rbx, [%1_handle]
%1_ret:
        next
%endmacro

symbol accum, 'accum'

; ### initialize-symbols
code initialize_symbols, 'initialize-symbols' ; --
        _quote "accum"
        _quote "feline"
        _ lookup_symbol
        mov     [accum_handle], rbx
        poprbx
        next
endcode
