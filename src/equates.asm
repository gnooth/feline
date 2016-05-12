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

BYTES_PER_CELL  equ     8

TRUE            equ     -1
FALSE           equ     0

%ifdef WIN64_NATIVE
GENERIC_READ    equ     $80000000       ; winnt.h
GENERIC_WRITE   equ     $40000000
%endif

MAX_PATH        equ     260             ; windef.h

NVOCS           equ     8               ; maximum number of word lists in the search order

MAX_LOCALS      equ     16              ; maximum number of local variables in a definition
