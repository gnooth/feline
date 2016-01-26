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

; ### code-alignment
value code_alignment, 'code-alignment', DEFAULT_CODE_ALIGNMENT

; ### align-code
code align_code, 'align-code'
        _begin .1
        _ here_c
        _ code_alignment
        _ mod
        _while .1
        _lit $90
        _ ccommac
        _repeat .1
        next
endcode

; ### data-alignment
value data_alignment, 'data-alignment', DEFAULT_DATA_ALIGNMENT

; ### align-data
code align_data, 'align-data'
        _begin .1
        _ here
        _ data_alignment
        _ mod
        _while .1
        _zero
        _ ccomma
        _repeat .1
        next
endcode

; ### align
code forth_align, 'align'
; CORE
; "If the data-space pointer is not aligned, reserve enough space to align it."
        _ align_data
        next
endcode

; REVIEW We assume this has to do with data space (like ALIGN).
; ### aligned
code aligned, 'aligned'                 ; addr -- a-addr
; CORE
; "a-addr is the first aligned address greater than or equal to addr."
        _ data_alignment
        _oneminus
        _ plus
        _ data_alignment
        _ negate
        _ and
        next
endcode
