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

; ### process-token
code process_token, 'process-token'     ; string -- object
        _ token_character_literal?
        _tagged_if .1
        _return
        _then .1

        _ token_string_literal?
        _tagged_if .2
        _return
        _then .2

        _ string_to_number

        next
endcode

; ### V{
code parse_vector, 'V{', IMMEDIATE      ; -- handle
        _lit 10
        _ new_vector_untagged
        _tor
        _begin .1
        _ parse_token                   ; -- string
        _dup
        _quote "}"
        _ string_equal?
        _untag_boolean
        _zeq
        _while .1
        _ process_token                 ; -- object
        _rfetch
        _ vector_push
        _repeat .1
        _drop
        _rfrom                          ; -- handle

        _ statefetch
        _if .2
        ; Add the newly-created vector to gc-roots. This protects it from
        ; being collected and also ensures that its children will be scanned.
        _dup
        _ gc_add_root
        _ literal
        _then .2

        next
endcode
