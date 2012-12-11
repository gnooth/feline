s" tests/tester.forth" file-status nip 0= [if]
   include tests/tester.forth
   include tests/core.forth
[else]
   include tests\tester.forth
   include tests\core.forth
[then]
