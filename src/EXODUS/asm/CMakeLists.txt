#-*- vi: set et ft=cmake ts=2 sts=2 sw=2 fenc=utf-8            :vi -*-┐
#─────────────────────────────────────────────────────────────────────┘
set(EX_ASM_OUT "${CMAKE_CURRENT_BINARY_DIR}/EXODUS/")

add_executable(genasm "${CMAKE_CURRENT_SOURCE_DIR}/holyc2c_asmgen.c")
set_target_properties(genasm PROPERTIES INTERPROCEDURAL_OPTIMIZATION OFF)
add_custom_command(OUTPUT "${EX_ASM_OUT}/tos_callconv.h"
                          "${EX_ASM_OUT}/callconv.s"
                   COMMAND genasm "${CMAKE_CURRENT_BINARY_DIR}" EXODUS
                   DEPENDS genasm)

add_library(FFI
  STATIC
  "${EX_ASM_OUT}/callconv.s"
  "${CMAKE_CURRENT_SOURCE_DIR}/c2holyc.s")

target_compile_options(FFI
  PRIVATE
    -Wno-unused-command-line-argument)

set_property(SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/c2holyc.s"
             APPEND PROPERTY
             COMPILE_OPTIONS "-x" "assembler-with-cpp")

set_target_properties(FFI
  PROPERTIES
    LINKER_LANGUAGE C
    INTERFACE_INCLUDE_DIRECTORIES "${CMAKE_CURRENT_BINARY_DIR}")

target_link_libraries(${PROJECT_NAME} PRIVATE FFI)
