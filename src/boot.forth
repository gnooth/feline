\ Copyright (C) 2012-2016 Peter Graves <gnooth@gmail.com>

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

LANGUAGE: forth

CONTEXT: forth feline ;
CURRENT: forth

import swap
import drop
import 2drop
import 3drop
import 4drop
import dup
import 2dup
import 3dup
import rot
import -rot
import over
import nip
import tuck

include-system-file vocabulary.forth
include-system-file bracket-if.forth
include-system-file defer.forth
include-system-file backtrace.forth

standard-forth? [if]
include-system-file locals.forth
[then]

\ include-system-file quotations.forth
include-system-file escaped-strings.forth
include-system-file case.forth
include-system-file dump.forth
include-system-file view.forth
include-system-file ekey.forth
include-system-file switch.forth
include-system-file accept.forth
include-system-file search.forth
include-system-file words.forth
include-system-file args.forth
\ include-system-file empty.forth
include-system-file double.forth
include-system-file environment.forth
include-system-file process-init-file.forth
include-system-file see.forth

include-system-file feline.forth

\ forth-mode

\ : edit ( "<spaces>name" -- )
\     warning @ >r
\     warning off
\     s" editor.forth" system-file-pathname included
\     r> warning !
\     -5 >in +! ;

\ empty!
