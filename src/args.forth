\ Copyright (C) 2015 Peter Graves <gnooth@gmail.com>

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

: (process-command-line)
    argc @ 3 = if
        argv @ cell+ @
        ?dup if
            zcount s" -e" str= if
                argv @ 2 cells + @
                ?dup if
                    zcount evaluate
                then
            then
        then
    then ;

' (process-command-line) is process-command-line
