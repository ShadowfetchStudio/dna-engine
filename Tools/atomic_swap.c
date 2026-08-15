#include <errno.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>

static int require_directory(const char *path) {
    struct stat info;
    if (lstat(path, &info) != 0) {
        fprintf(stderr, "atomic_swap: cannot inspect %s: %s\n", path, strerror(errno));
        return 0;
    }
    if (!S_ISDIR(info.st_mode)) {
        fprintf(stderr, "atomic_swap: path is not a directory: %s\n", path);
        return 0;
    }
    return 1;
}

int main(int argc, char *argv[]) {
    if (argc != 3) {
        fprintf(stderr, "usage: atomic_swap <staged-directory> <installed-directory>\n");
        return 64;
    }
    if (!require_directory(argv[1]) || !require_directory(argv[2])) {
        return 65;
    }
    if (renamex_np(argv[1], argv[2], RENAME_SWAP) != 0) {
        fprintf(stderr, "atomic_swap: swap failed: %s\n", strerror(errno));
        return 66;
    }
    return 0;
}
