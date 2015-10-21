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

only forth also definitions

0 value log-filename                    \ set this in ~/.init.forth

\ TEMPORARY!
s" /home/peter/forth.log" >$ to log-filename

0 value log-file                        \ fileid

: initialize-logging ( -- )
    log-filename count 2dup file-exists? if
        w/o open-file throw
    else
        w/o create-file throw
    then
    to log-file
;

false value log?

: +log ( -- )
    true to log?
    log-file 0= if
        initialize-logging
    then
;

: -log ( -- )
    false to log?
;

0 value old-output-file

0 value logging?

: >log ( -- )
    log? if
        output-file log-file <> if
            output-file to old-output-file
            log-file to output-file
            true to logging?
        then
    then
;

: log> ( -- )
    log? if
        logging? if
            cr
            log-file flush-file drop
            old-output-file to output-file
            false to logging?
        then
    then
;
