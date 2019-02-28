#include "version.h"

char * version ()
{
#ifdef REPOSITORY_VERSION
  return REPOSITORY_VERSION;
#else
  return RELEASE_VERSION;
#endif
}

char * build ()
{
#ifdef BUILD
  return BUILD;
#else
  return "";
#endif
}
