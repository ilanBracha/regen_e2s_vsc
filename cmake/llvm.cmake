# LLVM (LLVM-embedded-toolchain-for-Arm / ATfE) toolchain file.
# Hand-authored to mirror cmake/gcc.cmake but for clang.
# The actual compile/link/define flags come from cmake/GeneratedCfg.cmake
# (RASC_CMAKE_*_FLAGS), which already include --target=arm-none-eabi and
# -mcpu=cortex-m23. This file only locates the toolchain binaries.

# Toolchain binary directory.
# (Should avoid spaces in the path or have to escape them)
if(DEFINED ARM_TOOLCHAIN_PATH AND NOT ARM_TOOLCHAIN_PATH STREQUAL "")
  set(CMAKE_FIND_ROOT_PATH "${ARM_TOOLCHAIN_PATH}")
  message("Using ARM_TOOLCHAIN_PATH given with cmake settings -DARM_TOOLCHAIN_PATH=${ARM_TOOLCHAIN_PATH}")
elseif(DEFINED ENV{ARM_TOOLCHAIN_PATH} AND NOT ENV{ARM_TOOLCHAIN_PATH} STREQUAL "")
  message("Using ARM_TOOLCHAIN_PATH defined in environment: $ENV{ARM_TOOLCHAIN_PATH}")
  set(CMAKE_FIND_ROOT_PATH $ENV{ARM_TOOLCHAIN_PATH})
elseif(DEFINED ENV{ARM_LLVM_TOOLCHAIN_PATH} AND NOT ENV{ARM_LLVM_TOOLCHAIN_PATH} STREQUAL "")
  message("Using ARM_LLVM_TOOLCHAIN_PATH defined in environment: $ENV{ARM_LLVM_TOOLCHAIN_PATH}")
  set(CMAKE_FIND_ROOT_PATH $ENV{ARM_LLVM_TOOLCHAIN_PATH})
else ()
  message(FATAL_ERROR "Toolchain path not defined. Please set ARM_TOOLCHAIN_PATH variable to the LLVM (ATfE) 'bin' folder")
endif()

if(NOT EXISTS "${CMAKE_FIND_ROOT_PATH}" OR NOT IS_DIRECTORY "${CMAKE_FIND_ROOT_PATH}")
  message(FATAL_ERROR "Toolchain path does not exists: ${CMAKE_FIND_ROOT_PATH}")
endif()

if(NOT DEFINED CMAKE_SYSTEM_NAME)
  set(CMAKE_SYSTEM_NAME Generic)
endif()

if(NOT DEFINED CMAKE_SYSTEM_PROCESSOR)
  set(CMAKE_SYSTEM_PROCESSOR arm)
endif()

# Use add_library() with the STATIC option so the compiler check does not try to
# link (bare-metal clang cannot link without the FSP linker script).
if(NOT DEFINED CMAKE_TRY_COMPILE_TARGET_TYPE)
  set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)
endif()

# Propagate ARM_TOOLCHAIN_PATH into try_compile sub-projects
list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES ARM_TOOLCHAIN_PATH)

if (CMAKE_HOST_WIN32)
  set(BINARY_FILE_EXT ".exe")
else()
  set(BINARY_FILE_EXT "")
endif()

set(TARGET_TRIPLE arm-none-eabi)

# Make clang cross-compile for bare-metal Arm by default. The generated flag
# lists in GeneratedCfg.cmake also pass --target, but setting it here makes the
# CMake compiler identification / try-compile use the right target too.
set(CMAKE_C_COMPILER_TARGET ${TARGET_TRIPLE})
set(CMAKE_CXX_COMPILER_TARGET ${TARGET_TRIPLE})
set(CMAKE_ASM_COMPILER_TARGET ${TARGET_TRIPLE})

# CMake variables for compiler, assembler, and binary utilities (LLVM).
set(CMAKE_C_COMPILER   "${CMAKE_FIND_ROOT_PATH}/clang${BINARY_FILE_EXT}"   CACHE STRING "C Compiler")
set(CMAKE_CXX_COMPILER "${CMAKE_FIND_ROOT_PATH}/clang++${BINARY_FILE_EXT}" CACHE STRING "C++ Compiler")
set(CMAKE_ASM_COMPILER "${CMAKE_FIND_ROOT_PATH}/clang${BINARY_FILE_EXT}"   CACHE STRING "ASM Compiler")

set(CMAKE_OBJCOPY "${CMAKE_FIND_ROOT_PATH}/llvm-objcopy${BINARY_FILE_EXT}" CACHE STRING "objcopy tool")
set(CMAKE_SIZE    "${CMAKE_FIND_ROOT_PATH}/llvm-size${BINARY_FILE_EXT}"    CACHE STRING "size tool")

# Search for programs in the build host directories, but headers/libraries only
# in the target toolchain directories.
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
