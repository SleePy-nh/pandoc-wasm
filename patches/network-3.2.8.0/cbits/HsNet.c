/* -----------------------------------------------------------------------------
 * (c) The University of Glasgow 2002
 *
 * static versions of the inline functions from HsNet.h
 * -------------------------------------------------------------------------- */

#define INLINE
#include "HsNet.h"

/* WASI stub implementations for socket functions not available in WASI P1.
 * WASI Preview 1 supports pre-opened sockets but not creating new ones.
 * Functions like accept, send, recv, shutdown ARE provided by libc.
 * Functions like socket, bind, listen, connect are NOT provided. */
#if defined(__wasi__) || defined(__wasm__) || defined(__wasm32__) || defined(__EMSCRIPTEN__)
#include <errno.h>
#include <sys/socket.h>

#ifndef __wasi_sockets__

/* socket() - Cannot create new sockets in WASI P1 */
int socket(int domain, int type, int protocol) {
    (void)domain; (void)type; (void)protocol;
    errno = ENOSYS;
    return -1;
}

/* bind() - Cannot bind sockets in WASI P1 */
int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
    (void)sockfd; (void)addr; (void)addrlen;
    errno = ENOSYS;
    return -1;
}

/* listen() - Cannot listen on sockets in WASI P1 */
int listen(int sockfd, int backlog) {
    (void)sockfd; (void)backlog;
    errno = ENOSYS;
    return -1;
}

/* connect() - Cannot connect sockets in WASI P1 */
int connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen) {
    (void)sockfd; (void)addr; (void)addrlen;
    errno = ENOSYS;
    return -1;
}

/* setsockopt/getsockopt - limited support */
int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen) {
    (void)sockfd; (void)level; (void)optname; (void)optval; (void)optlen;
    /* Return success to avoid breaking code that tries to set options */
    return 0;
}

int getsockopt(int sockfd, int level, int optname, void *optval, socklen_t *optlen) {
    (void)sockfd; (void)level; (void)optname; (void)optval; (void)optlen;
    errno = ENOPROTOOPT;
    return -1;
}

/* getpeername/getsockname - not available */
int getpeername(int sockfd, struct sockaddr *addr, socklen_t *addrlen) {
    (void)sockfd; (void)addr; (void)addrlen;
    errno = ENOSYS;
    return -1;
}

int getsockname(int sockfd, struct sockaddr *addr, socklen_t *addrlen) {
    (void)sockfd; (void)addr; (void)addrlen;
    errno = ENOSYS;
    return -1;
}

/* sendto/recvfrom - not available (would need UDP support) */
ssize_t sendto(int sockfd, const void *buf, size_t len, int flags,
               const struct sockaddr *dest_addr, socklen_t addrlen) {
    (void)sockfd; (void)buf; (void)len; (void)flags; (void)dest_addr; (void)addrlen;
    errno = ENOSYS;
    return -1;
}

ssize_t recvfrom(int sockfd, void *buf, size_t len, int flags,
                 struct sockaddr *src_addr, socklen_t *addrlen) {
    (void)sockfd; (void)buf; (void)len; (void)flags; (void)src_addr; (void)addrlen;
    errno = ENOSYS;
    return -1;
}

/* Note: The following functions ARE provided by WASI libc and should NOT be stubbed:
 * - accept, accept4
 * - send, recv  
 * - shutdown
 * Defining them here would cause duplicate symbol errors at link time.
 */

#endif /* __wasi_sockets__ */
#endif /* __wasi__ */
