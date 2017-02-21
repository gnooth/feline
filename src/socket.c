// Copyright (C) 2017 Peter Graves <gnooth@gmail.com>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

#include <stdio.h>
#include <string.h>

#ifndef WIN64
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#endif

#include "feline.h"

cell c_make_socket(char *hostname, int port)
{
#ifndef WIN64
  struct hostent * host = gethostbyname(hostname);
  if (host == NULL)
    {
      printf("error looking up host\n");
      return (cell) -1;
    }
  int fd = socket(PF_INET, SOCK_STREAM, 0);
  if (fd < 0)
    {
      printf("unable to create socket\n");
      return (cell) -1;
    }
  struct sockaddr_in address;
  address.sin_family = AF_INET;
  address.sin_port = htons(port);
  memcpy(&address.sin_addr, host->h_addr_list[0], sizeof(address.sin_addr));
  if (connect(fd, (struct sockaddr *) &address, sizeof(address)) != 0)
    {
      printf("unable to connect\n");
      return (cell) -1;
    }
  return fd;
#endif
}
