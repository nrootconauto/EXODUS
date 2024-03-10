# -----------------------------------------------------------------------------
# Copyright (c) 2021, Daan Leijen
# -----------------------------------------------------------------------------
list(APPEND ic_cdefs IC_SEPARATE_OBJS)
list(APPEND ic_sources  
            src/isocline.c
            src/attr.c
            src/bbcode.c
            src/common.c
            src/completions.c
            src/completers.c
            src/editline.c
            src/highlight.c
            src/history.c
            src/stringbuf.c
            src/term.c
            src/tty_esc.c
            src/tty.c
            src/undo.c)

add_library(isocline STATIC ${ic_sources})
target_compile_definitions(isocline PRIVATE ${ic_cdefs})
target_include_directories(isocline PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${ic_install_dir}/include>)
