#-*- vi: set et ft=cmake ts=2 sts=2 sw=2 fenc=utf-8            :vi -*-┐
#─────────────────────────────────────────────────────────────────────┘
add_library(dyad STATIC ${CMAKE_CURRENT_SOURCE_DIR}/dyad/dyad.c)
add_library(vec STATIC ${CMAKE_CURRENT_SOURCE_DIR}/vec/vec.c)
add_library(map STATIC ${CMAKE_CURRENT_SOURCE_DIR}/map/map.c)
add_subdirectory(isocline)
add_subdirectory(argtable3)

set_target_properties(dyad argtable3 vec map isocline
  PROPERTIES
    C_STANDARD 11
    C_STANDARD_REQUIRED YES
    C_EXTENSIONS YES
    C_VISIBILITY_PRESET hidden
    LINKER_LANGUAGE C
)

add_library(c_opts INTERFACE)
target_compile_options(c_opts
  INTERFACE
    -fno-exceptions
    -fno-unwind-tables
    -fno-asynchronous-unwind-tables
    -fno-stack-protector
    -mno-shstk
    -mno-red-zone
    -fcf-protection=none)

if (CMAKE_BUILD_TYPE STREQUAL "MinSizeRel"
    OR CMAKE_INTERPROCEDURAL_OPTIMIZATION)
  if (CMAKE_C_COMPILER_ID MATCHES "Clang")
    set_target_properties(dyad argtable3 vec isocline map
      PROPERTIES
        INTERPROCEDURAL_OPTIMIZATION OFF)
    target_compile_options(c_opts INTERFACE -flto=full)
  else ()
    set_target_properties(dyad argtable3 vec isocline map
      PROPERTIES
        INTERPROCEDURAL_OPTIMIZATION ON)
  endif ()
endif ()
# I don't know how to CMake
target_link_libraries(dyad      PRIVATE c_opts)
target_link_libraries(argtable3 PRIVATE c_opts)
target_link_libraries(vec       PRIVATE c_opts)
target_link_libraries(map       PRIVATE c_opts)
target_link_libraries(isocline  PRIVATE c_opts)

target_link_libraries(${PROJECT_NAME} PRIVATE dyad argtable3 vec isocline map)
target_include_directories(${PROJECT_NAME}
  PRIVATE
    "${CMAKE_CURRENT_SOURCE_DIR}")
