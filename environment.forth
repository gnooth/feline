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

vocabulary environment

' environment >body @ constant environment-wordlist

\ CORE
: environment? ( c-addr u -- false | i * x true )
    environment-wordlist search-wordlist
    if
        execute true
    else
        false
    then ;

environment definitions

255     constant /counted-string
/hold   constant /hold
/pad    constant /pad
8       constant address-unit-bits

-10 7 / -2 =    constant floored        \ test from Win32Forth

#locals constant #locals

255     constant max-char               \ maximum value of any character in the
                                        \ implementation-defined character set

1 63 lshift 1-  constant        max-n   \ largest usable signed integer
-1              constant        max-u   \ largest usable unsigned integer

max-u max-n     2constant       max-d   \ largest usable signed double number
-1 -1           2constant       max-ud  \ largest usable unsigned double number

\   0 constant return-stack-cells       \ FIXME
128     constant stack-cells

only forth definitions
