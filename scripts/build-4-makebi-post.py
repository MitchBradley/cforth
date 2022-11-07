Import("env")

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join([
        "$CC",
        "-O",
        "-DBITS32", "-DNOSYSCALL",
        "-I",
        "$PROJECT_INCLUDE_DIR",
        "-fno-common",
        "-E",
        "-C",
        "-c", "$PROJECT_SRC_DIR/platform/arduino/extend.c",
        "|",
        "$BUILD_DIR/../host_makeccalls/${PROGNAME}",
        ">$BUILD_DIR/tccalls.fth",
    ]), "Building tccalls.fth with makeccalls")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join([
        "$BUILD_DIR/../host_forth/${PROGNAME}",
        "$BUILD_DIR/../host_forth/forth.dic",
        "$BUILD_DIR/tccalls.fth",
        "$PROJECT_SRC_DIR/app/arduino/app.fth",
    ]), "Building target dictionary with host CForth (app.fth -> target.dic)")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join(["mv", "$PROJECT_DIR/target.dic", "$BUILD_DIR/",
    ]), "Moving target dictionary to build tree")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join([
        "$BUILD_DIR/${PROGNAME}",
        "$BUILD_DIR/target.dic",
    ]), "Generating target dictionary source code with makebi (target.dic -> *.h)")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join([
        "mv", "dicthdr.h", "dict.h", "userarea.h", "$PROJECT_INCLUDE_DIR/",
    ]), "Moving source code to include tree")
)
