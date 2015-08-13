[defined] include-system-file [if]
   linux? [if]
      include-system-file tests/tester.forth
      include-system-file tests/core.forth
      include-system-file tests/coreplustest.forth
   [else]
      include-system-file tests\tester.forth
      include-system-file tests\core.forth
      include-system-file tests\coreplustest.forth
   [then]
[else]
   include tests/tester.forth
   include tests/core.forth
   include tests/coreplustest.forth
[then]
