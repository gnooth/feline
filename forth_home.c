#include <stdio.h>

int main()
{
  char inbuf[1024];
  char outbuf[1024];
  FILE *file;
  int i = 0;
  int j = 0;
  getcwd(inbuf, sizeof(inbuf));
  while (i < sizeof(inbuf))
    {
      char c = inbuf[i++];
      if (c == 0)
        break;
      if (c == '\\')
        outbuf[j++] = '\\';             // escape '\'
      outbuf[j++] = c;
    }
  outbuf[j] = 0;
  file = fopen("forth_home.h", "w");
  if (file)
    {
      fprintf(file, "#define FORTH_HOME \"%s\"\n", outbuf);
      fclose(file);
    }
  file = fopen("forth_home.asm", "w");
  if (file)
    {
      fprintf(file, "%%define FORTH_HOME \"%s\"\n", inbuf);
      fclose(file);
    }
}
