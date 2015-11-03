#include <stdio.h>
#include <unistd.h>

int main()
{
  char buf[1024];
  FILE *file;
  int i = 0;
  getcwd(buf, sizeof(buf));
  file = fopen("forth_home.asm", "w");
  if (file)
    {
      fprintf(file, "%%define FORTH_HOME \"%s\"\n", buf);
      fclose(file);
    }
}
