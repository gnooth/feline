create empty  2 cells allot  empty 2 cells erase

create reloadfile  256 allot

: guard  ( -- )
   dp @ empty !
   latest empty cell+ ! ;

: reset  ( -- )
   empty @ dp !
   empty cell+ @ last ! ;

: reload  ( -- )
   empty @ 0= if guard then
   parse-name  ( addr len )
   ?dup if reloadfile place else drop then
   reloadfile count ?dup if reset included else drop then ;
