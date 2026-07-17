#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include "../../src/cforth/forth.h"

/* wrapper voor system() */
int alsystem(char *path, cell arg) {
    (void)arg;  /* arg wordt hier niet gebruikt */
    return system(path);
}

/* wrapper voor chdir() */
int alchdir(char *path, cell arg) {
    (void)arg;
    return chdir(path);
}
