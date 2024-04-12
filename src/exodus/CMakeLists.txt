#-*- vi: set et ft=cmake ts=2 sts=2 sw=2 fenc=utf-8            :vi -*-┐
#─────────────────────────────────────────────────────────────────────┘
set(SRC_FILES
  sound.c
  misc.c
  main.c
  window.c
  loader.c
  ffi.c
  tosprint.c
  vfs.c
  backtrace.c
  misc.c)

if (CMAKE_SYSTEM_NAME STREQUAL "Linux" OR
    CMAKE_SYSTEM_NAME STREQUAL "FreeBSD")
  set(OS_DIR "posix")
elseif (WIN32)
  set(OS_DIR "nt")
else ()
  message(FATAL_ERROR "Unsupported system")
endif ()

list(APPEND SRC_FILES
  "${OS_DIR}/alloc.c"
  "${OS_DIR}/dbg.c"
  "${OS_DIR}/seth.c"
  "${OS_DIR}/shims.c")

set_source_files_properties(${SRC_FILES}
  PROPERTIES
    LANGUAGE C
    COMPILE_FLAGS "-Werror=implicit-function-declaration")

add_executable(${PROJECT_NAME} ${SRC_FILES})

target_include_directories(${PROJECT_NAME} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}")

add_subdirectory(asm)
