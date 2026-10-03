/* x86_64 glibc before 2.28 exposes large-file stat through __xstat64 and
 * fcntl rather than the newer exported wrappers selected by today's headers.
 * Keep this tiny SQLite bridge on those original, compatible entry points. */
#define _LARGEFILE64_SOURCE 1
#include <sys/stat.h>
#include <fcntl.h>
#include <stdarg.h>

extern int __xstat64(int, const char *, struct stat64 *);
extern int __lxstat64(int, const char *, struct stat64 *);
extern int __fxstat64(int, int, struct stat64 *);

__attribute__((visibility("hidden")))
int stat64(const char *path, struct stat64 *buffer) {
    return __xstat64(1, path, buffer);
}

__attribute__((visibility("hidden")))
int lstat64(const char *path, struct stat64 *buffer) {
    return __lxstat64(1, path, buffer);
}

__attribute__((visibility("hidden")))
int fstat64(int fd, struct stat64 *buffer) {
    return __fxstat64(1, fd, buffer);
}

__attribute__((visibility("hidden")))
int fcntl64(int fd, int command, ...) {
    va_list arguments;
    va_start(arguments, command);
    int result;
    switch (command) {
    case F_GETFD:
    case F_GETFL:
        result = fcntl(fd, command);
        break;
    case F_SETFD:
    case F_SETFL:
        result = fcntl(fd, command, va_arg(arguments, int));
        break;
    default:
        result = fcntl(fd, command, va_arg(arguments, void *));
        break;
    }
    va_end(arguments);
    return result;
}
