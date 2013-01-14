; Copyright (C) 2012-2013 Peter Graves <gnooth@gmail.com>

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

variable r0, 'r0', 0

variable s0, 's0', 0                    ; initialized in main()

variable saved_rbp, 'saved-rbp', 0

variable origin, 'origin', 0

variable origin_c, 'origin-c', 0

variable dp, 'dp', 0                    ; initialized in main()

variable cp, 'cp', 0                    ; initialized in main()

variable limit, 'limit', 0              ; initialized in main()

variable limit_c, 'limit-c', 0          ; initialized in main()

code cold, 'cold'                       ; --
        mov     [r0_data], rsp
        mov     [saved_rbp_data], rbp
        mov     rbp, [s0_data]
        _ here
        _ origin
        _ store
        _ here_c
        _ origin_c
        _ store
        _ forth_wordlist
        _fetch
        _zeq
        _if cold1
        _ latest
        _ forth_wordlist
        _ store
        _then cold1
        _string "boot.forth"
        _ included
        jmp quit
        next
endcode
