Import("env")

env.AddPostAction(
    "$BUILD_DIR/${PROGNAME}",
    env.VerboseAction(" ".join([
        "$BUILD_DIR/${PROGNAME}",
        "$PROJECT_SRC_DIR/cforth/interp.fth",
        "$BUILD_DIR/kernel.dic"
    ]), "Building dictionary with metacompiler (interp -> kernel.dic)")
)
