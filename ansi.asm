; Copyright (C) 2015 Peter Graves <gnooth@gmail.com>

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

constant black,   'black',   0
constant red,     'red',     1
constant green,   'green',   2
constant yellow,  'yellow',  3
constant blue,    'blue',    4
constant magenta, 'magenta', 5
constant cyan,    'cyan',    6
constant white,   'white',   7

value color?, 'color?', 0

; ### esc[
code ansi_escape, 'esc['
        _lit $1b
        _ emit
        _lit '['
        _ emit
        next
endcode

; ### foreground
code foreground, 'foreground'           ; color --
%ifdef WIN64
        _drop
%else
        _ color?
        _if .1
        _ ansi_escape
        _lit '3'
        _ emit
        _lit '0'
        _plus
        _ emit
        _lit 'm'
        _ emit
        _else .1
        _drop
        _then .1
%endif
        next
endcode

; ### background
code background, 'background'           ; color --
%ifdef WIN64
        _drop
%else
        _ color?
        _if .1
        _ ansi_escape
        _lit '4'
        _ emit
        _lit '0'
        _plus
        _ emit
        _lit 'm'
        _ emit
        _else .1
        _drop
        _then .1
%endif
        next
endcode

; ### page
code page, 'page'
; FACILITY
; "On a terminal, PAGE clears the screen and resets the cursor
; position to the upper left corner."
%ifdef WIN64
        _squote "cls"
        _ system_
%else
        _ ansi_escape
        _lit '2'
        _ emit
        _lit 'J'
        _ emit
        _ ansi_escape
        _lit $3b
        _ emit
        _lit 'H'
        _ emit
%endif
        next
endcode

%ifdef WIN64
extern os_set_console_cursor_position
%endif

; ### at-xy
code at_xy, 'at-xy'                     ; col row --
; FACILITY
; zero based (Forth 2012 10.6.1.0742)
; ANSI values are 1-based
%ifdef WIN64
        popd    rdx
        popd    rcx
        xcall   os_set_console_cursor_position
%else
        _ ansi_escape
        _ paren_udot                    ; -- col c-addr u
        _ type
        _lit ';'
        _ emit
        _ paren_udot
        _ type
        _lit 'H'
        _ emit
%endif
        next
endcode
