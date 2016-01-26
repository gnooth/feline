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

deferred free_history, 'free-history', noop

extern os_bye

; ### bye
code bye, "bye"
        _ free_locals_stack
        _ free_history

        _ ?cr
        _ report_allocations

        _ interactive?
        _if .1
        _ ?cr
        _dotq 'Bye!'
        _ cr
        _then .1

        jmp os_bye
        next
endcode
