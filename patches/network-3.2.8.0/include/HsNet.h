/* -----------------------------------------------------------------------------
 *
 * Definitions for package `network' which are visible in Haskell land.
 *
 * ---------------------------------------------------------------------------*/

#ifndef HSNET_H
#define HSNET_H

#include "HsNetDef.h"

#ifndef INLINE
# if defined(_MSC_VER)
#  define INLINE extern __inline
# elif defined(__GNUC_GNU_INLINE__)
#  define INLINE extern inline
# else
#  define INLINE inline
# endif
#endif

#ifndef _WIN32
# define _GNU_SOURCE 1 /* for struct ucred on Linux */
#endif
#define __APPLE_USE_RFC_3542 1 /* for IPV6_RECVPKTINFO */

/* WASI-specific definitions - only add missing constants, WASI already has the structs */
#if defined(__wasi__) || defined(__wasm32__)
# ifndef SCM_RIGHTS
#  define SCM_RIGHTS 0x01  /* Transfer file descriptors */
# endif
# ifndef AF_UNIX
#  define AF_UNIX 1
# endif
# ifndef SOMAXCONN
#  define SOMAXCONN 128
# endif
# ifndef F_GETFD
#  define F_GETFD 1
# endif
# ifndef F_GETFL
#  define F_GETFL 3
# endif
# ifndef FD_CLOEXEC
#  define FD_CLOEXEC 1
# endif
/* Address info flags (AI_*) */
# ifndef AI_PASSIVE
#  define AI_PASSIVE     0x0001
# endif
# ifndef AI_CANONNAME
#  define AI_CANONNAME   0x0002
# endif
# ifndef AI_NUMERICHOST
#  define AI_NUMERICHOST 0x0004
# endif
# ifndef AI_V4MAPPED
#  define AI_V4MAPPED    0x0008
# endif
# ifndef AI_ALL
#  define AI_ALL         0x0010
# endif
# ifndef AI_ADDRCONFIG
#  define AI_ADDRCONFIG  0x0020
# endif
# ifndef AI_NUMERICSERV
#  define AI_NUMERICSERV 0x0400
# endif
/* Name info flags (NI_*) */
# ifndef NI_NUMERICHOST
#  define NI_NUMERICHOST 0x0001
# endif
# ifndef NI_NUMERICSERV
#  define NI_NUMERICSERV 0x0002
# endif
# ifndef NI_NOFQDN
#  define NI_NOFQDN      0x0004
# endif
# ifndef NI_NAMEREQD
#  define NI_NAMEREQD    0x0008
# endif
# ifndef NI_DGRAM
#  define NI_DGRAM       0x0010
# endif
/* Max host/service name lengths */
# ifndef NI_MAXHOST
#  define NI_MAXHOST     1025
# endif
# ifndef NI_MAXSERV
#  define NI_MAXSERV     32
# endif
/* Error codes for getaddrinfo */
# ifndef EAI_AGAIN
#  define EAI_AGAIN      -3
# endif
# ifndef EAI_BADFLAGS
#  define EAI_BADFLAGS   -1
# endif
# ifndef EAI_FAIL
#  define EAI_FAIL       -4
# endif
# ifndef EAI_FAMILY
#  define EAI_FAMILY     -6
# endif
# ifndef EAI_MEMORY
#  define EAI_MEMORY     -10
# endif
# ifndef EAI_NONAME
#  define EAI_NONAME     -2
# endif
# ifndef EAI_SERVICE
#  define EAI_SERVICE    -8
# endif
# ifndef EAI_SOCKTYPE
#  define EAI_SOCKTYPE   -7
# endif
# ifndef EAI_SYSTEM
#  define EAI_SYSTEM     -11
# endif
# ifndef EAI_OVERFLOW
#  define EAI_OVERFLOW   -12
# endif
#endif /* __wasi__ */

#ifdef _WIN32
# include <winsock2.h>
# include <ws2tcpip.h>
# include <mswsock.h>
# include "win32defs.h"
# include "afunix_compat.h"
# define IPV6_V6ONLY 27
#endif

#ifdef HAVE_LIMITS_H
# include <limits.h>
#endif
#ifdef HAVE_STDLIB_H
# include <stdlib.h>
#endif
#ifdef HAVE_UNISTD_H
#include <unistd.h>
#endif
#ifdef HAVE_SYS_TYPES_H
# include <sys/types.h>
#endif
#ifdef HAVE_FCNTL_H
# include <fcntl.h>
#endif
#ifdef HAVE_SYS_UIO_H
# include <sys/uio.h>
#endif
#ifdef HAVE_SYS_SOCKET_H
# include <sys/socket.h>
#endif
#ifdef HAVE_NETINET_IN_H
# include <netinet/in.h>
#endif
#ifdef HAVE_NETINET_TCP_H
# include <netinet/tcp.h>
#endif
#ifdef HAVE_SYS_UN_H
# if defined(__wasi__) || defined(__wasm32__)
/* WASI's sys/un.h has incomplete sockaddr_un - provide our own complete definition */
struct sockaddr_un {
    sa_family_t sun_family;
    char sun_path[108];
};
# else
#  include <sys/un.h>
# endif
#endif
#ifdef HAVE_ARPA_INET_H
# include <arpa/inet.h>
#endif
#ifdef HAVE_NETDB_H
#include <netdb.h>
#endif
#ifdef HAVE_NET_IF_H
# include <net/if.h>
#endif
#ifdef HAVE_NETIOAPI_H
# include <netioapi.h>
#endif

#ifdef _WIN32
extern int   initWinSock ();
extern const char* getWSErrorDescr(int err);
extern void* newAcceptParams(int sock,
			     int sz,
			     void* sockaddr);
extern int   acceptNewSock(void* d);
extern int   acceptDoProc(void* param);

extern LPWSACMSGHDR
cmsg_firsthdr(LPWSAMSG mhdr);

extern LPWSACMSGHDR
cmsg_nxthdr(LPWSAMSG mhdr, LPWSACMSGHDR cmsg);

extern unsigned char *
cmsg_data(LPWSACMSGHDR cmsg);

extern unsigned int
cmsg_space(unsigned int l);

extern unsigned int
cmsg_len(unsigned int l);

/**
 * WSASendMsg function
 */
extern WINAPI int
WSASendMsg (SOCKET, LPWSAMSG, DWORD, LPDWORD,
            LPWSAOVERLAPPED, LPWSAOVERLAPPED_COMPLETION_ROUTINE);

/**
 * WSARecvMsg function
 */
extern WINAPI int
WSARecvMsg (SOCKET, LPWSAMSG, LPDWORD,
            LPWSAOVERLAPPED, LPWSAOVERLAPPED_COMPLETION_ROUTINE);
#else  /* _WIN32 */
extern int
sendFd(int sock, int outfd);

extern int
recvFd(int sock);

extern struct cmsghdr *
cmsg_firsthdr(struct msghdr *mhdr);

extern struct cmsghdr *
cmsg_nxthdr(struct msghdr *mhdr, struct cmsghdr *cmsg);

extern unsigned char *
cmsg_data(struct cmsghdr *cmsg);

extern size_t
cmsg_space(size_t l);

extern size_t
cmsg_len(size_t l);
#endif /* _WIN32 */

/* WASI doesn't have DNS resolution support - provide stubs that return errors */
#if defined(__wasi__) || defined(__wasm32__)

/* EAI_SYSTEM indicates a system error - use -1 as a generic failure */
#ifndef EAI_SYSTEM
#define EAI_SYSTEM -1
#endif
#ifndef EAI_FAIL
#define EAI_FAIL -4
#endif

/* Stub struct addrinfo for WASI */
struct addrinfo {
    int ai_flags;
    int ai_family;
    int ai_socktype;
    int ai_protocol;
    socklen_t ai_addrlen;
    struct sockaddr *ai_addr;
    char *ai_canonname;
    struct addrinfo *ai_next;
};

INLINE int
hsnet_getnameinfo(const struct sockaddr* a, socklen_t b, char* c,
                  socklen_t d, char* e, socklen_t f, int g)
{
    (void)a; (void)b; (void)c; (void)d; (void)e; (void)f; (void)g;
    return EAI_FAIL; /* DNS not supported in WASI */
}

INLINE int
hsnet_getaddrinfo(const char *hostname, const char *servname,
		  const struct addrinfo *hints, struct addrinfo **res)
{
    (void)hostname; (void)servname; (void)hints;
    *res = NULL;
    return EAI_FAIL; /* DNS not supported in WASI */
}

INLINE void
hsnet_freeaddrinfo(struct addrinfo *ai)
{
    (void)ai; /* Nothing to free for stubs */
}

#else /* Normal platforms */

INLINE int
hsnet_getnameinfo(const struct sockaddr* a,socklen_t b, char* c,
# if defined(_WIN32)
                  DWORD d, char* e, DWORD f, int g)
# else
                  socklen_t d, char* e, socklen_t f, int g)
# endif
{
  return getnameinfo(a,b,c,d,e,f,g);
}

INLINE int
hsnet_getaddrinfo(const char *hostname, const char *servname,
		  const struct addrinfo *hints, struct addrinfo **res)
{
    return getaddrinfo(hostname, servname, hints, res);
}

INLINE void
hsnet_freeaddrinfo(struct addrinfo *ai)
{
    freeaddrinfo(ai);
}

#endif /* __wasi__ */

#ifndef IOV_MAX
# define IOV_MAX 1024
#endif

#ifndef SOCK_NONBLOCK // Missing define in Bionic libc (Android)
# define SOCK_NONBLOCK O_NONBLOCK
#endif

#endif /* HSNET_H */
