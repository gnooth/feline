#include <stdio.h>
#ifndef _MSC_VER
#include <unistd.h>
#endif

int main()
{
#ifdef WIN64
  char sep = '\\';
#else
  char sep = '/';
#endif
  char buf[1024];
  FILE *file;
  int i = 0;
  chdir("..");
  getcwd(buf, sizeof(buf));
  file = fopen("src/feline_home.asm", "w");
  if (file)
    {
      fprintf(file, "%%define FELINE_HOME \"%s\"\n", buf);
      fprintf(file, "%%define FELINE_SOURCE_DIR \"%s%csrc\"\n", buf, sep);
      fclose(file);
    }
}
