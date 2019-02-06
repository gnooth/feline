// Copyright (C) 2017-2019 Peter Graves <gnooth@gmail.com>

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
#include <string.h>     // memcpy, memset

#ifdef WIN64
#include <winsock2.h>
#else
#include <unistd.h>     // write
#include <netdb.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#endif

#include "feline.h"

#ifdef WIN64
int winsock_initialized = 0;

static void initialize_winsock()
{
  if (!winsock_initialized)
    {
      WSADATA wsaData;
      if (WSAStartup(MAKEWORD(2, 2), &wsaData ) != 0)
        printf("WSAStartup() error\n");
      else
        winsock_initialized = 1;
    }
}
#endif

cell c_make_socket(char *hostname, int port)
{
#ifdef WIN64
  initialize_winsock();
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

cell c_make_server_socket(int port)
{
#ifdef WIN64
  initialize_winsock();
#endif
  int fd = socket(PF_INET, SOCK_STREAM, 0);
  if (fd < 0)
    {
      printf("unable to create socket\n");
      return (cell) -1;
    }
#ifndef WIN64
  int i = 1;
  setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &i, sizeof(i));
#endif
  struct sockaddr_in address;
  address.sin_family = AF_INET;
  address.sin_port = htons(port);
  memset(&address.sin_addr, 0, sizeof(address.sin_addr));
  if (bind(fd, (struct sockaddr *) &address, sizeof(address)))
    {
      printf("unable to bind\n");
      return (cell) -1;
    }
#ifndef WIN64
  socklen_t addr_length = sizeof(struct sockaddr_in);
  getsockname(fd, (struct sockaddr *) &address, &addr_length);
#endif
  if (listen(fd, 5))
    {
      printf("unable to listen\n");
      return (cell) -1;
    }
  return fd;
}

cell c_accept_connection(cell fd_listen)
{
#ifdef WIN64
  int fd = accept(fd_listen, NULL, NULL);
#else
  struct sockaddr_in address;
  memset(&address, 0, sizeof(struct sockaddr_in));
  socklen_t addr_length = sizeof(struct sockaddr_in);
  int fd = accept(fd_listen, (struct sockaddr *) &address, &addr_length);
#endif
  if (fd < 0)
    {
      printf("unable to accept connection\n");
      return (cell) -1;
    }
  return (cell) fd;
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
  return write(fd, buf, count);
#endif
}

cell c_socket_write_char(int c, int fd)
{
#ifdef WIN64
  return c_socket_write(fd, &c, 1);
#else
  return write(fd, &c, 1);
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
