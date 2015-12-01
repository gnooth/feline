[defined] include-system-file [if]
   linux? [if]
      include-system-file tests/tester.forth
      include-system-file tests/core.forth
      include-system-file tests/coreplustest.forth
      include-system-file tests/errorreport.forth
      include-system-file tests/coreexttest.forth
      include-system-file tests/filetest.forth
      include-system-file tests/localstest.forth
      include-system-file tests/searchordertest.forth
      include-system-file tests/toolstest.forth
   [else]
      include-system-file tests\tester.forth
      include-system-file tests\core.forth
      include-system-file tests\coreplustest.forth
      include-system-file tests\errorreport.forth
      include-system-file tests\coreexttest.forth
      include-system-file tests\filetest.forth
      include-system-file tests\localstest.forth
      include-system-file tests\searchordertest.forth
      include-system-file tests\toolstest.forth
   [then]
[else]
   include tests/tester.forth
   include tests/core.forth
   include tests/coreplustest.forth
   include tests/errorreport.forth
   include tests/coreexttest.forth
   include tests/filetest.forth
   include tests/localstest.forth
   include tests/searchordertest.forth
   include tests/toolstest.forth
[then]

report-errors

.( Reached end of tests.forth )
