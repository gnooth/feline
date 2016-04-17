\ Copyright (C) 2016 Peter Graves <gnooth@gmail.com>

\ This program is free software: you can redistribute it and/or modify
\ it under the terms of the GNU General Public License as published by
\ the Free Software Foundation, either version 3 of the License, or
\ (at your option) any later version.

\ This program is distributed in the hope that it will be useful,
\ but WITHOUT ANY WARRANTY; without even the implied warranty of
\ MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
\ GNU General Public License for more details.

\ You should have received a copy of the GNU General Public License
\ along with this program.  If not, see <http://www.gnu.org/licenses/>.

[forth]

only forth definitions

: save-compilation-state
    csp @
    local-names
    using-locals?
;

: restore-compilation-state
    to using-locals?
    to local-names
    csp !
;

: [:
    state@ if
        save-compilation-state
        0 to using-locals?
        postpone ahead
        true
    else
        false
    then
    :noname
; immediate

: ;]
    postpone ;
    >r
    if
        ]
        postpone then
        r>
        postpone literal
        restore-compilation-state
    else
        r>
    then
; immediate

only forth also feline definitions

synonym [ [:

synonym ] ;]
