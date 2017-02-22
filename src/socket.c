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
#include <unistd.h>     // write

#ifdef WIN64
#include <winsock2.h>
#else
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#endif

#include "feline.h"

cell c_make_socket(char *hostname, int port)
{
#ifdef WIN64
  WSADATA wsaData;
  if (WSAStartup(MAKEWORD(2, 2), &wsaData ) != 0)
    {
      printf("WSAStartup() error");
      return (cell) -1;
    }
  // FIXME we need to call WSACleanup() somewhere
#endif
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
}

cell c_socket_read_char(cell fd)
{
  char c;
  int n = recv(fd, (char *) &c, 1, 0);
  if (n == 0)
    return -1;
  else
    return c;
}

cell c_socket_write(cell fd, void *buf, size_t count)
{
#ifdef WIN64
  if (send(fd, buf, count, 0) != count)
    {
      printf("WSAGetLastError() = %d\n", WSAGetLastError());
      fflush(stdout);
      return -1;
    }
  return count;
#else
  return os_write_file(fd, buf, count);
#endif
}

void c_socket_write_char(int c, int fd)
{
#ifdef WIN64
  c_socket_write(fd, &c, 1);
#else
  write(fd, &c, 1);
#endif
}

cell c_socket_close(cell fd)
{
#ifdef WIN64
  return closesocket(fd);
#else
  return os_close_file(fd);
#endif
}
