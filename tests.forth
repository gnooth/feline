[defined] include-system-file [if]
   linux? [if]
      include-system-file tests/tester.forth
      include-system-file tests/core.forth
      include-system-file tests/coreplustest.forth
      include-system-file tests/errorreport.forth
      include-system-file tests/coreexttest.forth
      include-system-file tests/searchordertest.forth
      report-errors
   [else]
      include-system-file tests\tester.forth
      include-system-file tests\core.forth
      include-system-file tests\coreplustest.forth
      include-system-file tests\errorreport.forth
      include-system-file tests\coreexttest.forth
      include-system-file tests\searchordertest.forth
   [then]
[else]
   include tests/tester.forth
   include tests/core.forth
   include tests/coreplustest.forth
   include tests/errorreport.forth
   include tests/coreexttest.forth
   include tests/searchordertest.forth
[then]
