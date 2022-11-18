Import("env")

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join([
        "$CC",
        "-E",
        "-C",
        "-DMAKEPRIMS",
        "-DBITS32", "-DNOSYSCALL",
        "-I",
        "$PROJECT_INCLUDE_DIR",
        "-c", "$PROJECT_SRC_DIR/cforth/forth.c",
        ">$BUILD_DIR/forth.ip",
    ]), "Preprocessing forth.c")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join([
        "$BUILD_DIR/${PROGNAME}",
        "$BUILD_DIR/forth.ip"
    ]), "Building vars.h prims.h init.x with makename")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join(["mkdir", "-p", "$PROJECT_INCLUDE_DIR",
    ]), "Creating temporary include directory")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join(["mv", "prims.h", "$PROJECT_INCLUDE_DIR/",
    ]), "Moving prims.h to include/")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join(["mv", "vars.h", "$PROJECT_INCLUDE_DIR/",
    ]), "Moving vars.h to include/")
)
