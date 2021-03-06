# Copyright (C) 2014-2015 ARM Limited. All rights reserved. 

if(TARGET_MBED_ARMCC_TOOLCHAIN_INCLUDED)
    return()
endif()
set(TARGET_MBED_ARMCC_TOOLCHAIN_INCLUDED 1)

# search path for included .cmake files (set this as early as possible, so that
# indirect includes still use it)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")

include(CMakeForceCompiler)

set(CMAKE_SYSTEM_NAME mbedOS)
set(CMAKE_SYSTEM_VERSION 1)
set(CMAKE_SYSTEM_PROCESSOR "armv7-m")

# required for -include yotta_config.h
set(YOTTA_FORCE_INCLUDE_FLAG "--preinclude")

# legacy definitions for building mbed 2.0 modules with a retrofitted build
# system:
set(MBED_LEGACY_TOOLCHAIN "ARM_STD")
# provide compatibility definitions for compiling with this target: these are
# definitions that legacy code assumes will be defined. 
add_definitions("-DTOOLCHAIN_ARM -DTOOLCHAIN_ARM_STD -DMBED_OPERATORS")


# find the compiler and associated tools that we need:
find_program(ARMCC_PROGRAM armcc)
find_program(ARMCC_FROMELF_PROGRAM fromelf)
find_program(ARMCC_ARMLINK_PROGRAM armlink)
find_program(ARMCC_AR_PROGRAM armar)
macro(arm_toolchain_program_notfound progname)
    message("**************************************************************************\n")
    message(" ERROR: the arm toolchain program ${progname} could not be found.\n")
    if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
        message(" Note that the armcc toolchain is not available for Max OS X.")
    else()
        message(" Please check that your arm compiler installation directory is in")
        message(" the PATH for this shell")
    endif()
    message("\n**************************************************************************")
    message(FATAL_ERROR "missing program prevents build")
    return()
endmacro()

if(NOT ARMCC_PROGRAM)
    arm_toolchain_program_notfound("armcc")
endif()
if(NOT ARMCC_FROMELF_PROGRAM)
    arm_toolchain_program_notfound("fromelf")
endif()
if(NOT ARMCC_ARMLINK_PROGRAM)
    arm_toolchain_program_notfound("armlink")
endif()
if(NOT ARMCC_AR_PROGRAM)
    arm_toolchain_program_notfound("armar")
endif()

# post-process elf files into .bin files (deprecated backwards-compatible
# version):
set(YOTTA_POSTPROCESS_COMMAND "\"${ARMCC_FROMELF_PROGRAM}\" --bin YOTTA_CURRENT_EXE_NAME --output YOTTA_CURRENT_EXE_NAME.bin")

# set default compilation flags
set(_C_FAMILY_FLAGS_INIT "--split_sections --apcs=interwork --restrict --no_rtti --multibyte-chars")
set(CMAKE_C_FLAGS_INIT   "--c99 ${_C_FAMILY_FLAGS_INIT}")
set(CMAKE_ASM_FLAGS_INIT "--gnu --split_sections --apcs=interwork --restrict --no_rtti")
set(CMAKE_CXX_FLAGS_INIT "${_C_FAMILY_FLAGS_INIT} --no_exceptions --gnu")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "")
set(CMAKE_EXE_LINKER_FLAGS_INIT "${CMAKE_MODULE_LINKER_FLAGS_INIT}") 

# Set the compiler to ARMCC
include(CMakeForceCompiler)

cmake_force_c_compiler("${ARMCC_PROGRAM}" ARMCC)
cmake_force_cxx_compiler("${ARMCC_PROGRAM}" ARMCC)
set(CMAKE_LINKER "${ARMCC_ARMLINK_PROGRAM}" CACHE FILEPATH "linker")
set(CMAKE_AR "${ARMCC_AR_PROGRAM}" CACHE FILEPATH "archiver")


# post-process elf files into .bin files (new version):
function(yotta_apply_target_rules target_type target_name)
    if(${target_type} STREQUAL "EXECUTABLE")
        add_custom_command(TARGET ${target_name}
            POST_BUILD
            COMMAND "${ARMCC_FROMELF_PROGRAM}" --bin ${target_name} --output ${target_name}.bin
            COMMENT "converting to .bin"
            VERBATIM
        )
    endif()
endfunction()

