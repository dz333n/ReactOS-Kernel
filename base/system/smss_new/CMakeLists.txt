
remove_definitions(-D_WIN32_WINNT=0x502 -DWINVER=0x502)
add_definitions(-D_WIN32_WINNT=0x300 -DWINVER=0x300)

include_directories(${REACTOS_SOURCE_DIR}/sdk/include/reactos/subsys)

list(APPEND SOURCE
    smss.c)

add_executable(smss WIN32 ${SOURCE} smss.rc)
target_link_libraries(smss nt ${PSEH_LIB})
set_module_type(smss nativecui)
add_importlibs(smss ntdll)
add_cd_file(TARGET smss DESTINATION reactos/system32 FOR all)
