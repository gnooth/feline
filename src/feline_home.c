#include <stdio.h>
#include <unistd.h>

int main()
{
  char buf[1024];
  FILE *file;
  int i = 0;
  chdir("..");
  getcwd(buf, sizeof(buf));
  file = fopen("src/feline_home.asm", "w");
  if (file)
    {
      fprintf(file, "%%define FELINE_HOME \"%s\"\n", buf);
      fclose(file);
    }
}
