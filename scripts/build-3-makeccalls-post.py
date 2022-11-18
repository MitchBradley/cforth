Import("env")

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join([
        "$CC",
        "-O",
        "-DBITS32", "-DNOSYSCALL",
        "-I",
        "$PROJECT_INCLUDE_DIR",
        "-I",
        "src/cforth",
        "-I",
        "src/lib",
        "-fno-common",
        "-E",
        "-C",
        "-c", "$PROJECT_SRC_DIR/app/host-serial/extend-posix.c",
        "|",
        "$BUILD_DIR/${PROGNAME}",
        ">$BUILD_DIR/ccalls.fth",
    ]), "Building ccalls.fth with makeccalls")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join([
        "$BUILD_DIR/../host_forth/${PROGNAME}",
        "$BUILD_DIR/../host_forth/forth.dic",
        "$BUILD_DIR/ccalls.fth",
        "$PROJECT_SRC_DIR/app/host-serial/app.fth",
    ]), "Building host dictionary with CForth (app.fth -> app.dic)")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join(["mv", "$PROJECT_DIR/app.dic", "$BUILD_DIR/",
    ]), "Moving host dictionary to build tree")
)
