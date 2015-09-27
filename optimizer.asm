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

; ### clear-compilation-queue
; deferred clear_compilation_queue, 'clear-compilation-queue', noop
code clear_compilation_queue, 'clear-compilation-queue'
        _clear pending_xt
        next
endcode

; ### flush-compilation-queue
; deferred flush_compilation_queue, 'flush-compilation-queue', noop
deferred flush_compilation_queue, 'flush-compilation-queue', compile_pending_xt

; ### opt
value opt, 'opt', 0

; ### +opt
code plusopt, '+opt', IMMEDIATE   ; --
        mov     qword [opt_data], TRUE
        next
endcode

; ### -opt
code minusopt, '-opt', IMMEDIATE  ; --
        mov     qword [opt_data], FALSE
        next
endcode
