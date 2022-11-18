Import("env")

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join([
        "$BUILD_DIR/${PROGNAME}",
        "$BUILD_DIR/../host_meta/kernel.dic",
        "$PROJECT_SRC_DIR/cforth/load.fth",
    ]), "Building dictionary with CForth (load.fth -> forth.dic)")
)

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join(["mv", "$PROJECT_DIR/forth.dic", "$BUILD_DIR/",
    ]), "Moving dictionary to build tree")
)
