
#if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    # no optimization
    add_compile_flags("/Ob0 /Od")
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_flags("/Ox /Ob2 /Ot /Oy /GT")
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /OPT:REF /OPT:ICF")
elseif(OPTIMIZE STREQUAL "1")
    add_compile_flags("/O1")
elseif(OPTIMIZE STREQUAL "2")
    add_compile_flags("/O2")
elseif(OPTIMIZE STREQUAL "3")
    add_compile_flags("/Ot /Ox /GS-")
elseif(OPTIMIZE STREQUAL "4")
    add_compile_flags("/Os /Ox /GS-")
elseif(OPTIMIZE STREQUAL "5")
    add_compile_flags("/Gy /Ob2 /Os /Ox /GS-")
endif()

# Always use string pooling: this helps reducing the binaries size since a lot
# of redundancy come from the usage of __FILE__ / __RELFILE__ in the debugging
# helper macros. Note also that GCC builds use string pooling by default.
add_compile_flags("/GF")

# Enable function level linking and comdat folding
add_compile_flags("/Gy")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /OPT:REF /OPT:ICF")
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /OPT:REF /OPT:ICF")
set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /OPT:REF /OPT:ICF")

if(ARCH STREQUAL "i386")
    add_definitions(/DWIN32 /D_WINDOWS)
endif()

add_definitions(/Dinline=__inline /D__STDC__=1)

# Ignore any "standard" include paths, and do not use any default CRT library.
if(NOT USE_CLANG_CL)
    add_compile_flags("/X /Zl")
endif()

# Disable RTTI, exception handling and buffer security checks by default.
# These require run-time support that may not always be available.
add_compile_flags("/GR- /EHs-c- /GS-")

if(USE_CLANG_CL)
    set(CMAKE_CL_SHOWINCLUDES_PREFIX "Note: including file: ")
endif()

# HACK: for VS 11+ we need to explicitly disable SSE, which is off by
# default for older compilers. See CORE-6507
if(ARCH STREQUAL "i386")
    add_compile_flags("/arch:IA32")
endif()

# VS 12+ requires /FS when used in parallel compilations
if(NOT MSVC_IDE)
    add_compile_flags("/FS")
endif()

# VS14+ tries to use thread-safe initialization
add_compile_flags("/Zc:threadSafeInit-")

# HACK: Disable use of __CxxFrameHandler4 on VS 16.3+ (x64 only)
# See https://developercommunity.visualstudio.com/content/problem/746534/visual-c-163-runtime-uses-an-unsupported-api-for-u.html
if(ARCH STREQUAL "amd64" AND MSVC_VERSION GREATER 1922)
    add_compile_flags("/d2FH4-")
    add_link_options("/d2:-FH4-")
endif()

# Generate Warnings Level 3
add_compile_flags("/W3")

# Disable overly sensitive warnings as well as those that generally aren't
# useful to us.
# - C4244: implicit integer truncation
# - C4290: C++ exception specification ignored
# - C4800: forcing value to bool 'true' or 'false' (performance warning)
# - C4200: nonstandard extension used : zero-sized array in struct/union
# - C4214: nonstandard extension used : bit field types other than int
add_compile_flags("/wd4244 /wd4290 /wd4800 /wd4200 /wd4214")

# FIXME: Temporarily disable C4018 until we fix more of the others. CORE-10113
add_compile_flags("/wd4018")

# The following warnings are treated as errors:
# - C4013: implicit function declaration
# - C4020: too many actual parameters
# - C4022: pointer type mismatch for parameter
# - C4028: formal parameter different from declaration
# - C4047: different level of indirection
# - TODO: C4090: different 'modifier' qualifiers (for C programs only;
#          for C++ programs, the compiler error C2440 is issued)
# - C4098: void function returning a value
# - C4101: unreferenced local variable
# - C4113: parameter lists differ
# - C4129: unrecognized escape sequence
# - C4133: incompatible types - from '<x> *' to '<y> *'
# - C4163: 'identifier': not available as an intrinsic function
# - C4229: modifiers on data are ignored
# - C4311: pointer truncation from '<pointer>' to '<integer>'
# - C4312: conversion from '<integer>' to '<pointer>' of greater size
# - C4313: 'fprintf': '%x' in format string conflicts with argument n of type 'HANDLE'
# - C4477: '_snprintf' : format string '%ld' requires an argument of type 'long', but variadic argument 1 has type 'DWORD_PTR'
# - C4603: macro is not defined or definition is different after precompiled header use
# - C4700: uninitialized variable usage
# - C4715: 'function': not all control paths return a value
# - C4716: function must return a value
add_compile_flags("/we4013 /we4020 /we4022 /we4028 /we4047 /we4098 /we4101 /we4113 /we4129 /we4133 /we4163 /we4229 /we4311 /we4312 /we4313 /we4477 /we4603 /we4700 /we4715 /we4716")

# - C4189: local variable initialized but not referenced
# Not in Release mode
if(NOT CMAKE_BUILD_TYPE STREQUAL "Release")
    add_compile_flags("/we4189")
endif()

# Enable warnings above the default level, but don't treat them as errors:
# - C4115: named type definition in parentheses
add_compile_flags("/w14115")

if(USE_CLANG_CL)
    add_compile_flags_language("-nostdinc -Wno-multichar -Wno-char-subscripts -Wno-microsoft-enum-forward-reference -Wno-pragma-pack -Wno-microsoft-anon-tag -Wno-parentheses-equality -Wno-unknown-pragmas" "C")
    add_compile_flags_language("-nostdinc -Wno-multichar -Wno-char-subscripts -Wno-microsoft-enum-forward-reference -Wno-pragma-pack -Wno-microsoft-anon-tag -Wno-parentheses-equality -Wno-unknown-pragmas" "CXX")
endif()

# Debugging
#if(${CMAKE_BUILD_TYPE} STREQUAL "Debug")
if(CMAKE_BUILD_TYPE STREQUAL "Debug")
    if(NOT (_PREFAST_ OR _VS_ANALYZE_))
        add_compile_flags("/Zi")
    endif()
#elseif(${CMAKE_BUILD_TYPE} STREQUAL "Release")
elseif(CMAKE_BUILD_TYPE STREQUAL "Release")
    add_definitions("/D NDEBUG")
endif()

# Hotpatchable images
if(ARCH STREQUAL "i386")
    if(NOT USE_CLANG_CL)
        add_compile_flags("/hotpatch")
    endif()
    set(_hotpatch_link_flag "/FUNCTIONPADMIN:5")
elseif(ARCH STREQUAL "amd64")
    set(_hotpatch_link_flag "/FUNCTIONPADMIN:6")
endif()

if(MSVC_IDE AND (NOT DEFINED USE_FOLDER_STRUCTURE))
    set(USE_FOLDER_STRUCTURE TRUE)
endif()

if(RUNTIME_CHECKS)
    add_definitions(-D__RUNTIME_CHECKS__)
    add_compile_flags("/RTC1")
endif()

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} /MANIFEST:NO /INCREMENTAL:NO /SAFESEH:NO /NODEFAULTLIB /RELEASE ${_hotpatch_link_flag} /IGNORE:4039")
set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} /MANIFEST:NO /INCREMENTAL:NO /SAFESEH:NO /NODEFAULTLIB /RELEASE ${_hotpatch_link_flag} /IGNORE:4104 /IGNORE:4039")
set(CMAKE_MODULE_LINKER_FLAGS "${CMAKE_MODULE_LINKER_FLAGS} /MANIFEST:NO /INCREMENTAL:NO /SAFESEH:NO /NODEFAULTLIB /RELEASE ${_hotpatch_link_flag} /IGNORE:4039")

# HACK: Remove the /implib argument, implibs are generated separately
string(REPLACE "/implib:<TARGET_IMPLIB>" "" CMAKE_C_LINK_EXECUTABLE "${CMAKE_C_LINK_EXECUTABLE}")
string(REPLACE "/implib:<TARGET_IMPLIB>" "" CMAKE_CXX_LINK_EXECUTABLE "${CMAKE_CXX_LINK_EXECUTABLE}")
string(REPLACE "/implib:<TARGET_IMPLIB>" "" CMAKE_C_CREATE_SHARED_LIBRARY "${CMAKE_C_CREATE_SHARED_LIBRARY}")
string(REPLACE "/implib:<TARGET_IMPLIB>" "" CMAKE_CXX_CREATE_SHARED_LIBRARY "${CMAKE_CXX_CREATE_SHARED_LIBRARY}")
string(REPLACE "/implib:<TARGET_IMPLIB>" "" CMAKE_C_CREATE_SHARED_MODULE "${CMAKE_C_CREATE_SHARED_MODULE}")
string(REPLACE "/implib:<TARGET_IMPLIB>" "" CMAKE_CXX_CREATE_SHARED_MODULE "${CMAKE_CXX_CREATE_SHARED_MODULE}")

if(CMAKE_DISABLE_NINJA_DEPSLOG)
    set(cl_includes_flag "")
else()
    set(cl_includes_flag "/showIncludes")
endif()

if(MSVC_IDE AND (CMAKE_VERSION MATCHES "ReactOS"))
    # For VS builds we'll only have en-US in resource files
    add_definitions(/DLANGUAGE_EN_US)
else()
    if(CMAKE_VERSION VERSION_LESS 3.4.0)
        set(CMAKE_RC_COMPILE_OBJECT "<CMAKE_RC_COMPILER> /nologo <FLAGS> <DEFINES> ${I18N_DEFS} /fo<OBJECT> <SOURCE>")
        if(ARCH STREQUAL "arm")
            set(CMAKE_ASM_COMPILE_OBJECT
                "cl ${cl_includes_flag} /nologo /X /I${REACTOS_SOURCE_DIR}/sdk/include/asm /I${REACTOS_BINARY_DIR}/sdk/include/asm <FLAGS> <DEFINES> /D__ASM__ /D_USE_ML /EP /c <SOURCE> > <OBJECT>.tmp"
                "<CMAKE_ASM_COMPILER> -nologo -o <OBJECT> <OBJECT>.tmp")
        else()
            set(CMAKE_ASM_COMPILE_OBJECT
                "cl ${cl_includes_flag} /nologo /X /I${REACTOS_SOURCE_DIR}/sdk/include/asm /I${REACTOS_BINARY_DIR}/sdk/include/asm <FLAGS> <DEFINES> /D__ASM__ /D_USE_ML /EP /c <SOURCE> > <OBJECT>.tmp"
                "<CMAKE_ASM_COMPILER> /nologo /Cp /Fo<OBJECT> /c /Ta <OBJECT>.tmp")
        endif()
    else()
        set(CMAKE_RC_COMPILE_OBJECT "<CMAKE_RC_COMPILER> /nologo <INCLUDES> <FLAGS> <DEFINES> ${I18N_DEFS} /fo<OBJECT> <SOURCE>")
        if(ARCH STREQUAL "arm")
            set(CMAKE_ASM_COMPILE_OBJECT
                "cl ${cl_includes_flag} /nologo /X /I${REACTOS_SOURCE_DIR}/sdk/include/asm /I${REACTOS_BINARY_DIR}/sdk/include/asm <INCLUDES> <FLAGS> <DEFINES> /D__ASM__ /D_USE_ML /EP /c <SOURCE> > <OBJECT>.tmp"
                "<CMAKE_ASM_COMPILER> -nologo -o <OBJECT> <OBJECT>.tmp")
        else()
            set(CMAKE_ASM_COMPILE_OBJECT
                "cl ${cl_includes_flag} /nologo /X /I${REACTOS_SOURCE_DIR}/sdk/include/asm /I${REACTOS_BINARY_DIR}/sdk/include/asm <INCLUDES> <FLAGS> <DEFINES> /D__ASM__ /D_USE_ML /EP /c <SOURCE> > <OBJECT>.tmp"
                "<CMAKE_ASM_COMPILER> /nologo /Cp /Fo<OBJECT> /c /Ta <OBJECT>.tmp")
        endif()
    endif()
endif()

if(_VS_ANALYZE_)
    message("VS static analysis enabled!")
    add_compile_flags("/analyze")
elseif(_PREFAST_)
    message("PREFAST enabled!")
    if(CMAKE_VERSION VERSION_LESS 3.4.0)
        set(CMAKE_C_COMPILE_OBJECT "prefast <CMAKE_C_COMPILER> ${CMAKE_START_TEMP_FILE} ${CMAKE_CL_NOLOGO} <FLAGS> <DEFINES> /Fo<OBJECT> -c <SOURCE>${CMAKE_END_TEMP_FILE}"
        "prefast LIST")
        set(CMAKE_CXX_COMPILE_OBJECT "prefast <CMAKE_CXX_COMPILER> ${CMAKE_START_TEMP_FILE} ${CMAKE_CL_NOLOGO} <FLAGS> <DEFINES> /TP /Fo<OBJECT> -c <SOURCE>${CMAKE_END_TEMP_FILE}"
        "prefast LIST")
        set(CMAKE_C_LINK_EXECUTABLE
        "<CMAKE_C_COMPILER> ${CMAKE_CL_NOLOGO} <OBJECTS> ${CMAKE_START_TEMP_FILE} <FLAGS> /Fe<TARGET> -link /implib:<TARGET_IMPLIB> /version:<TARGET_VERSION_MAJOR>.<TARGET_VERSION_MINOR> <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <LINK_LIBRARIES>${CMAKE_END_TEMP_FILE}")
        set(CMAKE_CXX_LINK_EXECUTABLE
        "<CMAKE_CXX_COMPILER> ${CMAKE_CL_NOLOGO} <OBJECTS> ${CMAKE_START_TEMP_FILE} <FLAGS> /Fe<TARGET> -link /implib:<TARGET_IMPLIB> /version:<TARGET_VERSION_MAJOR>.<TARGET_VERSION_MINOR> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <LINK_LIBRARIES>${CMAKE_END_TEMP_FILE}")
    else()
        set(CMAKE_C_COMPILE_OBJECT "prefast <CMAKE_C_COMPILER> ${CMAKE_START_TEMP_FILE} ${CMAKE_CL_NOLOGO} <INCLUDES> <FLAGS> <DEFINES> /Fo<OBJECT> -c <SOURCE>${CMAKE_END_TEMP_FILE}"
        "prefast LIST")
        set(CMAKE_CXX_COMPILE_OBJECT "prefast <CMAKE_CXX_COMPILER> ${CMAKE_START_TEMP_FILE} ${CMAKE_CL_NOLOGO} <INCLUDES> <FLAGS> <DEFINES> /TP /Fo<OBJECT> -c <SOURCE>${CMAKE_END_TEMP_FILE}"
        "prefast LIST")
        set(CMAKE_C_LINK_EXECUTABLE
        "<CMAKE_C_COMPILER> ${CMAKE_CL_NOLOGO} <OBJECTS> ${CMAKE_START_TEMP_FILE} <INCLUDES> <FLAGS> /Fe<TARGET> -link /implib:<TARGET_IMPLIB> /version:<TARGET_VERSION_MAJOR>.<TARGET_VERSION_MINOR> <CMAKE_C_LINK_FLAGS> <LINK_FLAGS> <LINK_LIBRARIES>${CMAKE_END_TEMP_FILE}")
        set(CMAKE_CXX_LINK_EXECUTABLE
        "<CMAKE_CXX_COMPILER> ${CMAKE_CL_NOLOGO} <OBJECTS> ${CMAKE_START_TEMP_FILE} <INCLUDES> <FLAGS> /Fe<TARGET> -link /implib:<TARGET_IMPLIB> /version:<TARGET_VERSION_MAJOR>.<TARGET_VERSION_MINOR> <CMAKE_CXX_LINK_FLAGS> <LINK_FLAGS> <LINK_LIBRARIES>${CMAKE_END_TEMP_FILE}")
    endif()
endif()

set(CMAKE_RC_CREATE_SHARED_LIBRARY ${CMAKE_C_CREATE_SHARED_LIBRARY})
set(CMAKE_ASM_CREATE_SHARED_LIBRARY ${CMAKE_C_CREATE_SHARED_LIBRARY})
set(CMAKE_RC_CREATE_SHARED_MODULE ${CMAKE_C_CREATE_SHARED_MODULE})
set(CMAKE_ASM_CREATE_SHARED_MODULE ${CMAKE_C_CREATE_SHARED_MODULE})
set(CMAKE_ASM_CREATE_STATIC_LIBRARY ${CMAKE_C_CREATE_STATIC_LIBRARY})

if(PCH)
    macro(add_pch _target _pch _sources)

        # Workaround for the MSVC toolchain (MSBUILD) /MP bug
        set(_temp_gch ${CMAKE_CURRENT_BINARY_DIR}/${_target}.pch)
        if(MSVC_IDE)
            file(TO_NATIVE_PATH ${_temp_gch} _gch)
        else()
            set(_gch ${_temp_gch})
        endif()

        if(IS_CPP)
            set(_pch_language CXX)
            if(NOT USE_CLANG_CL)
                set(_cl_lang_flag "/TP")
            endif()
        else()
            set(_pch_language C)
            set(_cl_lang_flag "/TC")
        endif()

        if(MSVC_IDE)
            set(_pch_path_name_flag "/Fp${_gch}")
        endif()

        if(USE_CLANG_CL)
            set(_pch_compile_flags "${_cl_lang_flag} /Yc${_pch} /FI${_pch} /Fp${_gch}")
        else()
            set(_pch_compile_flags "${_cl_lang_flag} /Yc /Fp${_gch}")
        endif()

        # Build the precompiled header
        # HEADER_FILE_ONLY FALSE: force compiling the header
        set_source_files_properties(${_pch} PROPERTIES
            HEADER_FILE_ONLY FALSE
            LANGUAGE ${_pch_language}
            COMPILE_FLAGS ${_pch_compile_flags}
            OBJECT_OUTPUTS ${_gch})

        # Prevent a race condition related to writing to the PDB files between the PCH and the excluded list of source files
        get_target_property(_target_sources ${_target} SOURCES)
        list(REMOVE_ITEM _target_sources ${_pch})
        foreach(_target_src ${_target_sources})
            set_property(SOURCE ${_target_src} APPEND PROPERTY OBJECT_DEPENDS ${_gch})
        endforeach()

        # Use the precompiled header with the specified source files, skipping the pch itself
        list(REMOVE_ITEM ${_sources} ${_pch})
        foreach(_src ${${_sources}})
            set_property(SOURCE ${_src} APPEND_STRING PROPERTY COMPILE_FLAGS " /FI${_gch} /Yu${_gch} ${_pch_path_name_flag}")
        endforeach()
    endmacro()
else()
    macro(add_pch _target _pch _sources)
    endmacro()
endif()

function(set_entrypoint _module _entrypoint)
    if(${_entrypoint} STREQUAL "0")
        add_target_link_flags(${_module} "/NOENTRY")
    elseif(ARCH STREQUAL "i386")
        set(_entrysymbol ${_entrypoint})
        if(${ARGC} GREATER 2)
            set(_entrysymbol ${_entrysymbol}@${ARGV2})
        endif()
        add_target_link_flags(${_module} "/ENTRY:${_entrysymbol}")
    else()
        add_target_link_flags(${_module} "/ENTRY:${_entrypoint}")
    endif()
endfunction()

function(set_subsystem MODULE SUBSYSTEM)
    string(TOUPPER ${SUBSYSTEM} _subsystem)
    if(ARCH STREQUAL "amd64")
        add_target_link_flags(${MODULE} "/SUBSYSTEM:${_subsystem},5.02")
    elseif(ARCH STREQUAL "arm")
        add_target_link_flags(${MODULE} "/SUBSYSTEM:${_subsystem},6.02")
    else()
        add_target_link_flags(${MODULE} "/SUBSYSTEM:${_subsystem},5.01")
    endif()
endfunction()

function(set_image_base MODULE IMAGE_BASE)
    add_target_link_flags(${MODULE} "/BASE:${IMAGE_BASE}")
endfunction()

function(set_module_type_toolchain MODULE TYPE)
    if(CPP_USE_STL)
        if((${TYPE} STREQUAL "kernelmodedriver") OR (${TYPE} STREQUAL "wdmdriver"))
            message(FATAL_ERROR "Use of STL in kernelmodedriver or wdmdriver type module prohibited")
        endif()
        target_link_libraries(${MODULE} cpprt stlport oldnames)
    elseif(CPP_USE_RT)
        target_link_libraries(${MODULE} cpprt)
    endif()
    if((${TYPE} STREQUAL "win32dll") OR (${TYPE} STREQUAL "win32ocx") OR (${TYPE} STREQUAL "cpl"))
        add_target_link_flags(${MODULE} "/DLL")
    elseif(${TYPE} STREQUAL "kernelmodedriver")
        # Disable linker warning 4078 (multiple sections found with different attributes) for INIT section use
        add_target_link_flags(${MODULE} "/DRIVER /IGNORE:4078 /SECTION:INIT,D")
    elseif(${TYPE} STREQUAL "wdmdriver")
        add_target_link_flags(${MODULE} "/DRIVER:WDM /IGNORE:4078 /SECTION:INIT,D")
    endif()

    if(RUNTIME_CHECKS)
        target_link_libraries(${MODULE} runtmchk)
    endif()

endfunction()

# Define those for having real libraries
set(CMAKE_IMPLIB_CREATE_STATIC_LIBRARY "LINK /LIB /NOLOGO <LINK_FLAGS> /OUT:<TARGET> <OBJECTS>")

if(ARCH STREQUAL "arm")
    set(CMAKE_STUB_ASM_COMPILE_OBJECT "<CMAKE_ASM_COMPILER> -nologo -o <OBJECT> <SOURCE>")
else()
    set(CMAKE_STUB_ASM_COMPILE_OBJECT "<CMAKE_ASM_COMPILER> /nologo /Cp /Fo<OBJECT> /c /Ta <SOURCE>")
endif()

function(add_delay_importlibs _module)
    get_target_property(_module_type ${_module} TYPE)
    if(_module_type STREQUAL "STATIC_LIBRARY")
        message(FATAL_ERROR "Cannot add delay imports to a static library")
    endif()
    foreach(_lib ${ARGN})
        get_filename_component(_basename "${_lib}" NAME_WE)
        get_filename_component(_ext "${_lib}" EXT)
        if(NOT _ext)
            set(_ext ".dll")
        endif()
        add_target_link_flags(${_module} "/DELAYLOAD:${_basename}${_ext}")
        target_link_libraries(${_module} "lib${_basename}")
    endforeach()
    target_link_libraries(${_module} delayimp)
endfunction()

function(fixup_load_config _target)
    # msvc knows how to generate a load_config so no hacks here
endfunction()

function(generate_import_lib _libname _dllname _spec_file)

    set(_def_file ${CMAKE_CURRENT_BINARY_DIR}/${_libname}_exp.def)
    set(_asm_stubs_file ${CMAKE_CURRENT_BINARY_DIR}/${_libname}_stubs.asm)

    # Generate the asm stub file and the def file for import library
    add_custom_command(
        OUTPUT ${_asm_stubs_file} ${_def_file}
        COMMAND native-spec2def --ms -a=${SPEC2DEF_ARCH} --implib -n=${_dllname} -d=${_def_file} -l=${_asm_stubs_file} ${CMAKE_CURRENT_SOURCE_DIR}/${_spec_file}
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${_spec_file} native-spec2def)

    if(MSVC_IDE)
        # Compile the generated asm stub file
        if(ARCH STREQUAL "arm")
            set(_asm_stub_command ${CMAKE_ASM_COMPILER} -nologo -o ${_asm_stubs_file}.obj ${_asm_stubs_file})
        else()
            set(_asm_stub_command ${CMAKE_ASM_COMPILER} /Cp /Fo${_asm_stubs_file}.obj /c /Ta ${_asm_stubs_file})
        endif()
        add_custom_command(
            OUTPUT ${_asm_stubs_file}.obj
            COMMAND ${_asm_stub_command}
            DEPENDS ${_asm_stubs_file})
    else()
        # Be clear about the "language"
        # Thanks MS for creating a stupid linker
        set_source_files_properties(${_asm_stubs_file} PROPERTIES LANGUAGE "STUB_ASM")
    endif()

    # Add our library
    if(MSVC_IDE)
        add_library(${_libname} STATIC EXCLUDE_FROM_ALL ${_asm_stubs_file}.obj)
        set_source_files_properties(${_asm_stubs_file}.obj PROPERTIES EXTERNAL_OBJECT TRUE)
        set_target_properties(${_libname} PROPERTIES LINKER_LANGUAGE "C")
    else()
        # NOTE: as stub file and def file are generated in one pass, depending on one is like depending on the other
        add_library(${_libname} STATIC EXCLUDE_FROM_ALL ${_asm_stubs_file})
        # set correct "link rule"
        set_target_properties(${_libname} PROPERTIES LINKER_LANGUAGE "IMPLIB")
    endif()
    set_target_properties(${_libname} PROPERTIES STATIC_LIBRARY_FLAGS "/DEF:${_def_file}")
endfunction()

if(ARCH STREQUAL "amd64")
    # This is NOT a typo.
    # See https://software.intel.com/en-us/forums/topic/404643
    add_definitions(/D__x86_64)
    set(SPEC2DEF_ARCH x86_64)
elseif(ARCH STREQUAL "arm")
    add_definitions(/D__arm__)
    set(SPEC2DEF_ARCH arm)
else()
    set(SPEC2DEF_ARCH i386)
endif()
function(spec2def _dllname _spec_file)

    cmake_parse_arguments(__spec2def "ADD_IMPORTLIB;NO_PRIVATE_WARNINGS;WITH_RELAY" "VERSION" "" ${ARGN})

    # Get library basename
    get_filename_component(_file ${_dllname} NAME_WE)

    # Error out on anything else than spec
    if(NOT ${_spec_file} MATCHES ".*\\.spec")
        message(FATAL_ERROR "spec2def only takes spec files as input.")
    endif()

    if(__spec2def_WITH_RELAY)
        set(__with_relay_arg "--with-tracing")
    endif()

    if(__spec2def_VERSION)
        set(__version_arg "--version=0x${__spec2def_VERSION}")
    endif()

    # Generate exports def and C stubs file for the DLL
    add_custom_command(
        OUTPUT ${CMAKE_CURRENT_BINARY_DIR}/${_file}.def ${CMAKE_CURRENT_BINARY_DIR}/${_file}_stubs.c
        COMMAND native-spec2def --ms -a=${SPEC2DEF_ARCH} -n=${_dllname} -d=${CMAKE_CURRENT_BINARY_DIR}/${_file}.def -s=${CMAKE_CURRENT_BINARY_DIR}/${_file}_stubs.c ${__with_relay_arg} ${__version_arg} ${CMAKE_CURRENT_SOURCE_DIR}/${_spec_file}
        DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/${_spec_file} native-spec2def)

    if(__spec2def_ADD_IMPORTLIB)
        generate_import_lib(lib${_file} ${_dllname} ${_spec_file})
        if(__spec2def_NO_PRIVATE_WARNINGS)
            add_target_property(lib${_file} STATIC_LIBRARY_FLAGS "/ignore:4104")
        endif()
    endif()
endfunction()

macro(macro_mc FLAG FILE)
    set(COMMAND_MC ${CMAKE_MC_COMPILER} -u ${FLAG} -b -h ${CMAKE_CURRENT_BINARY_DIR}/ -r ${CMAKE_CURRENT_BINARY_DIR}/ ${FILE})
endmacro()

# PSEH workaround
set(PSEH_LIB "pseh")

# Use a full path for the x86 version of ml when using x64 VS.
# It's not a problem when using the DDK/WDK because, in x64 mode,
# both the x86 and x64 versions of ml are available.
if((ARCH STREQUAL "amd64") AND (DEFINED ENV{VCToolsInstallDir}))
    set(CMAKE_ASM16_COMPILER $ENV{VCToolsInstallDir}/bin/HostX86/x86/ml.exe)
elseif((ARCH STREQUAL "amd64") AND (DEFINED ENV{VCINSTALLDIR}))
    set(CMAKE_ASM16_COMPILER $ENV{VCINSTALLDIR}/bin/ml.exe)
elseif(ARCH STREQUAL "arm")
    set(CMAKE_ASM16_COMPILER armasm.exe)
else()
    set(CMAKE_ASM16_COMPILER ml.exe)
endif()

function(CreateBootSectorTarget _target_name _asm_file _binary_file _base_address)
    set(_object_file ${_binary_file}.obj)
    set(_temp_file ${_binary_file}.tmp)

    get_defines(_defines)
    get_includes(_includes)

    if(USE_CLANG_CL)
        set(_no_std_includes_flag "-nostdinc")
    else()
        set(_no_std_includes_flag "/X")
    endif()

    add_custom_command(
        OUTPUT ${_temp_file}
        COMMAND ${CMAKE_C_COMPILER} /nologo ${_no_std_includes_flag} /I${REACTOS_SOURCE_DIR}/sdk/include/asm /I${REACTOS_BINARY_DIR}/sdk/include/asm ${_includes} ${_defines} /D__ASM__ /D_USE_ML /EP /c ${_asm_file} > ${_temp_file}
        DEPENDS ${_asm_file})

    if(ARCH STREQUAL "arm")
        set(_asm16_command ${CMAKE_ASM16_COMPILER} -nologo -o ${_object_file} ${_temp_file})
    else()
        set(_asm16_command ${CMAKE_ASM16_COMPILER} /nologo /Cp /Fo${_object_file} /c /Ta ${_temp_file})
    endif()

    add_custom_command(
        OUTPUT ${_object_file}
        COMMAND ${_asm16_command}
        DEPENDS ${_temp_file})

    add_custom_command(
        OUTPUT ${_binary_file}
        COMMAND native-obj2bin ${_object_file} ${_binary_file} ${_base_address}
        DEPENDS ${_object_file} native-obj2bin)

    set_source_files_properties(${_object_file} ${_temp_file} ${_binary_file} PROPERTIES GENERATED TRUE)

    add_custom_target(${_target_name} ALL DEPENDS ${_binary_file})
endfunction()

function(allow_warnings __module)
endfunction()

macro(add_asm_files _target)
    if(MSVC_IDE AND (CMAKE_VERSION MATCHES "ReactOS"))
        get_defines(_directory_defines)
        get_includes(_directory_includes)
        get_directory_property(_defines COMPILE_DEFINITIONS)
        foreach(_source_file ${ARGN})
            get_filename_component(_source_file_base_name ${_source_file} NAME_WE)
            get_filename_component(_source_file_full_path ${_source_file} ABSOLUTE)
            set(_preprocessed_asm_file ${CMAKE_CURRENT_BINARY_DIR}/asm/${_source_file_base_name}_${_target}.tmp)
            set(_object_file ${CMAKE_CURRENT_BINARY_DIR}/asm/${_source_file_base_name}_${_target}.obj)
            get_source_file_property(_defines_semicolon_list ${_source_file_full_path} COMPILE_DEFINITIONS)
            unset(_source_file_defines)
            foreach(_define ${_defines_semicolon_list})
                if(NOT ${_define} STREQUAL "NOTFOUND")
                    list(APPEND _source_file_defines -D${_define})
                endif()
            endforeach()
            if(ARCH STREQUAL "arm")
                set(_pp_asm_compile_command ${CMAKE_ASM_COMPILER} -nologo -o ${_object_file} ${_preprocessed_asm_file})
            else()
                set(_pp_asm_compile_command ${CMAKE_ASM_COMPILER} /nologo /Cp /Fo${_object_file} /c /Ta ${_preprocessed_asm_file})
            endif()
            add_custom_command(
                OUTPUT ${_preprocessed_asm_file} ${_object_file}
                COMMAND cl /nologo /X /I${REACTOS_SOURCE_DIR}/sdk/include/asm /I${REACTOS_BINARY_DIR}/sdk/include/asm ${_directory_includes} ${_source_file_defines} ${_directory_defines} /D__ASM__ /D_USE_ML /EP /c ${_source_file_full_path} > ${_preprocessed_asm_file} && ${_pp_asm_compile_command}
                DEPENDS ${_source_file_full_path})
            set_source_files_properties(${_object_file} PROPERTIES EXTERNAL_OBJECT TRUE)
            list(APPEND ${_target} ${_object_file})
        endforeach()
    else()
        list(APPEND ${_target} ${ARGN})
    endif()
endmacro()

function(add_linker_script _target _linker_script_file)
    get_filename_component(_file_full_path ${_linker_script_file} ABSOLUTE)
    get_filename_component(_file_name ${_linker_script_file} NAME)
    set(_generated_file_path_prefix "${CMAKE_CURRENT_BINARY_DIR}${CMAKE_FILES_DIRECTORY}/${_target}.dir/${_file_name}")

    # Generate the ASM module containing sections specifications and layout.
    set(_generated_file "${_generated_file_path_prefix}.S")
    add_custom_command(
        OUTPUT ${_generated_file}
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_file_full_path}" "${_generated_file}"
        DEPENDS ${_file_full_path})
    set_source_files_properties(${_generated_file} PROPERTIES LANGUAGE "ASM" GENERATED TRUE)
    add_asm_files(${_target}_linker_file ${_generated_file})

    # Generate the C module containing extra sections specifications and layout,
    # as well as comment-type linker #pragma directives.
    set(_generated_file "${_generated_file_path_prefix}.c")
    add_custom_command(
        OUTPUT ${_generated_file}
        COMMAND "${CMAKE_COMMAND}" -E copy_if_different "${_file_full_path}" "${_generated_file}"
        DEPENDS ${_file_full_path})
    set_source_files_properties(${_generated_file} PROPERTIES LANGUAGE "C" GENERATED TRUE)
    list(APPEND ${_target}_linker_file ${_generated_file})

    # Add both files to the sources of the target.
    target_sources(${_target} PRIVATE "${${_target}_linker_file}")

    # Create the additional linker response file.
    set(_generated_file "${_generated_file_path_prefix}.rsp")
    if(USE_CLANG_CL)
        set(_no_std_includes_flag "-nostdinc")
    else()
        set(_no_std_includes_flag "/X")
    endif()
    if(MSVC_IDE AND (CMAKE_VERSION MATCHES "ReactOS"))
        # MSBuild, via the VS IDE, uses response files when calling CL or LINK.
        # We cannot specify a custom response file on the linker command-line,
        # since specifying response files from within response files is forbidden.
        # We therefore have to pre-process, at configuration time, the linker
        # script so as to retrieve the custom linker options to be appended
        # to the linker command-line.
        execute_process(
            COMMAND ${CMAKE_C_COMPILER} /nologo ${_no_std_includes_flag} /D__LINKER__ /EP /c "${_file_full_path}"
            # OUTPUT_FILE "${_generated_file}"
            OUTPUT_VARIABLE linker_options
            ERROR_QUIET
            WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
            RESULT_VARIABLE linker_rsp_result
            OUTPUT_STRIP_TRAILING_WHITESPACE)
        if(NOT linker_rsp_result EQUAL 0)
            message(FATAL_ERROR "Generating pre-processed linker options for target '${_target}' failed with error ${linker_rsp_result}.")
        endif()
        # file(STRINGS ${_generated_file} linker_options NEWLINE_CONSUME)
        string(REGEX REPLACE "[\r\n]+" " " linker_options "${linker_options}")
        add_target_link_flags(${_target} ${linker_options})
    else()
        # Generate at compile-time a linker response file and append it
        # to the linker command-line.
        add_custom_command(
            # OUTPUT ${_generated_file}
            TARGET ${_target} PRE_LINK # PRE_BUILD
            COMMAND ${CMAKE_C_COMPILER} /nologo ${_no_std_includes_flag} /D__LINKER__ /EP /c "${_file_full_path}" > "${_generated_file}"
            DEPENDS ${_file_full_path}
            VERBATIM)
        set_source_files_properties(${_generated_file} PROPERTIES GENERATED TRUE)
        # add_custom_target("${_target}_${_file_name}" ALL DEPENDS ${_generated_file})
        # add_dependencies(${_target} "${_target}_${_file_name}")
        add_target_link_flags(${_target} "@${_generated_file}")
        add_target_property(${_target} LINK_DEPENDS ${_file_full_path})
    endif()
endfunction()
