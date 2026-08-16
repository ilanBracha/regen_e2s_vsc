# Please see README.md for build instructions

cmake_minimum_required(VERSION 3.16.4)

set(CMAKE_SYSTEM_NAME Generic)

set(CMAKE_SYSTEM_PROCESSOR arm)

# Use add_library() with the STATIC option to name the source file in the generated project.
# This avoids running the linker and is intended for use with cross-compiling toolchains that
# cannot link without custom flags or linker scripts
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_CONFIGURATION_TYPES Debug Release RelWithDebInfo MinSizeRel)

if(BUILD_KIT)
	message(NOTICE "Build Kit is defined as ${BUILD_KIT}")
endif()

message(NOTICE "CMAKE_CURRENT_BINARY_DIR is defined as ${CMAKE_CURRENT_BINARY_DIR}")

get_property(isMultiConfig GLOBAL PROPERTY GENERATOR_IS_MULTI_CONFIG)

if(isMultiConfig)
    message(NOTICE "Multi-config generator(${CMAKE_GENERATOR}) is active")
else()
    message(NOTICE "Single-config generator(${CMAKE_GENERATOR}) is active")
	if(DEFINED CMAKE_BUILD_TYPE)
	 	message(NOTICE "CMAKE_BUILD_TYPE is defined as ${CMAKE_BUILD_TYPE}")
	elseif(DEFINED BUILD_TYPE)
		set(CMAKE_BUILD_TYPE ${BUILD_TYPE})
		message(NOTICE "CMAKE_BUILD_TYPE is set to BUILD_TYPE ENV ${CMAKE_BUILD_TYPE}")
	else()
		message(FATAL_ERROR "Please specify the CMAKE_BUILD_TYPE with -DCMAKE_BUILD_TYPE=")
	endif()
    #set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_BUILD_TYPE})
	message(NOTICE "CMAKE_RUNTIME_OUTPUT_DIRECTORY is defined as ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}")
endif()

cmake_minimum_required(VERSION 3.16.4)

# Project configuration
project(ra2e3_ptx_Iot_fsp_reader
	VERSION 1.0.0
	LANGUAGES C CXX ASM)

set(CMAKE_CROSSCOMPILING "TRUE")
set(CMAKE_EXPORT_COMPILE_COMMANDS "TRUE")

include(${CMAKE_CURRENT_LIST_DIR}/Config.cmake)

include(${CMAKE_CURRENT_LIST_DIR}/cmake/GeneratedCfg.cmake)

# If required user can amend RASC generated flags here, e.g. list(REMOVE_ITEM RASC_CMAKE_C_FLAGS "-Wall")

include(${CMAKE_CURRENT_LIST_DIR}/cmake/GeneratedSrc.cmake)

# --------------------------------------------------------------------------
# User (application) additions
# --------------------------------------------------------------------------
# The RASC-generated GeneratedSrc.cmake globs sources from src/ but only adds
# the top-level src/ folder to the include path. The application headers live
# in sub-folders, so add them here so #include "rs_nfc_reader.h" etc. resolve.
target_include_directories(${PROJECT_NAME}.elf
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/src/app_nfc_reader
    ${CMAKE_CURRENT_SOURCE_DIR}/src/nfc_reader/include
    ${CMAKE_CURRENT_SOURCE_DIR}/src/nfc_reader/src
    ${CMAKE_CURRENT_SOURCE_DIR}/src/nfc_reader/src/ptx105r
)

# --------------------------------------------------------------------------
# pes-console-io stdio backend (picolibc retarget)
# --------------------------------------------------------------------------
# The LLVM/ATfE embedded C library (picolibc/tinystdio) requires the
# application to provide the FILE objects for stdin/stdout/stderr. Without
# them, printf/puts/putchar fail to link with:
#     ld.lld: error: undefined symbol: stdout
# These symbols (and the r_byteq queue used by the UART stdio backend) are
# provided by the pes-console-io git submodule at src/pes-console-io, which is
# sparse-checked-out to just the files listed below.
#
# GeneratedSrc.cmake GLOB_RECURSEs src/*.c, so it already picks these up; they
# are listed explicitly anyway so a missing/uninitialised submodule fails at
# configure time with a clear error instead of an obscure `undefined symbol:
# stdout` at link. CMake de-duplicates identical absolute source paths, so no
# object is compiled twice. Keep this list in sync with makefile.defs
# (PES_IO_OBJS), which is what the e2studio build uses.
set(PES_IO_SRCDIR
    ${CMAKE_CURRENT_SOURCE_DIR}/src/pes-console-io/examples/e2studio/stdio_uart_on_fpb_ra2e3/src)

target_sources(${PROJECT_NAME}.elf
    PRIVATE
    ${PES_IO_SRCDIR}/r_byteq.c
    ${PES_IO_SRCDIR}/syscalls_picolib_stdio_to_uart.c
)

# Let syscalls_picolib_stdio_to_uart.c find r_byteq.h next to it.
target_include_directories(${PROJECT_NAME}.elf
    PRIVATE
    ${PES_IO_SRCDIR}
)

# picolibc/tinystdio pulls in the full (float-capable) vfprintf by default,
# which does not fit in this part's 64 KB flash. The application only uses
# integer/string conversions, so redirect printf & friends to the
# integer-only (long) variant to reclaim several KB of flash. This mirrors the
# e2studio linker setting (Linker -> Other: -Wl,--defsym=vfprintf=__l_vfprintf).
target_link_options(${PROJECT_NAME}.elf
    PRIVATE
    -Wl,--defsym=vfprintf=__l_vfprintf
)

# --------------------------------------------------------------------------
# CMSIS-Zone secure bundle (.sbd) for the Renesas hardware debugger
# --------------------------------------------------------------------------
# The Renesas VS Code debugger (type "renesas-hardware") reads a
# "<elf-basename>.sbd" file next to the built .elf to obtain the device memory
# partition (CMSIS-Zone). e2 studio creates this during its build; the CMake
# build does not, so launching the debugger otherwise fails with
# "Invalid filename". Recreate it from the RASC-generated .secure_* files so
# F5 / the CMake Debug button work out of the box. (No-op if .secure_rzone is
# absent, e.g. a non-secure device variant.)
add_custom_command(TARGET ${PROJECT_NAME}.elf POST_BUILD
    COMMAND ${CMAKE_COMMAND}
        -DSRC_DIR=${CMAKE_CURRENT_SOURCE_DIR}
        -DOUT_SBD=$<TARGET_FILE_DIR:${PROJECT_NAME}.elf>/${PROJECT_NAME}.sbd
        -P ${CMAKE_CURRENT_SOURCE_DIR}/cmake/make_sbd.cmake
    COMMENT "Generating ${PROJECT_NAME}.sbd (CMSIS-Zone bundle for Renesas debugger)"
    VERBATIM)
