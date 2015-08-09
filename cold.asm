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

; ### rp0
variable rp0, 'rp0', 0

; ### sp0
variable sp0, 'sp0', 0                  ; initialized in main()

; ### saved-rbp
variable saved_rbp, 'saved-rbp', 0

; ### origin
variable origin, 'origin', 0

; ### origin-c
variable origin_c, 'origin-c', 0

; ### dp
variable dp, 'dp', 0                    ; initialized in main()

; ### cp
variable cp, 'cp', 0                    ; initialized in main()

; ### limit
variable limit, 'limit', 0              ; initialized in main()

; ### limit-c
variable limit_c, 'limit-c', 0          ; initialized in main()

; ### cold
code cold, 'cold'                       ; --
        mov     [rp0_data], rsp
        mov     [saved_rbp_data], rbp
        mov     rbp, [sp0_data]
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
        _squote "boot.forth"
        _ system_file_pathname
        _lit included_cfa
        _ catch
        _ ?dup
        _if cold2
        _ do_error
        _then cold2
        jmp quit
        next
endcode
