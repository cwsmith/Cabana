# copied from github.com/SCOREC/core/cmake/bob.cmake
macro(bob_begin_package)
  message(STATUS "CMAKE_VERSION: ${CMAKE_VERSION}")
  if (${PROJECT_NAME}_VERSION)
    message(STATUS "${PROJECT_NAME}_VERSION: ${${PROJECT_NAME}_VERSION}")
  endif()
endmacro(bob_begin_package)

macro(bob_private_dep pkg_name)
  option(${PROJECT_NAME}_USE_${pkg_name} "Whether to use ${pkg_name}"
         ${${PROJECT_NAME}_USE_${pkg_name}_DEFAULT})
  message(STATUS "${PROJECT_NAME}_USE_${pkg_name}: ${${PROJECT_NAME}_USE_${pkg_name}}")
  if(${PROJECT_NAME}_USE_${pkg_name})
    set(${pkg_name}_PREFIX "${${pkg_name}_PREFIX_DEFAULT}"
        CACHE PATH "${pkg_name} install directory")
    if (${pkg_name}_PREFIX)
      message(STATUS "${pkg_name}_PREFIX ${${pkg_name}_PREFIX}")
      #if ${pkg_name}_PREFIX is set, don't find it anywhere else:
      find_package(${pkg_name} ${${pkg_name}_REQUIRED_VERSION}
                   REQUIRED PATHS ${${pkg_name}_PREFIX} NO_DEFAULT_PATH)
    else()
      #allow CMake to search other prefixes if ${pkg_name}_PREFIX is not set
      find_package(${pkg_name} ${${pkg_name}_REQUIRED_VERSION} REQUIRED)
    endif()
    if(${pkg_name}_CONFIG)
      message(STATUS "${pkg_name}_CONFIG: ${${pkg_name}_CONFIG}")
    endif()
    if(${pkg_name}_VERSION)
      message(STATUS "${pkg_name}_VERSION: ${${pkg_name}_VERSION}")
    endif()
  endif()
endmacro(bob_private_dep)

macro(bob_public_dep pkg_name)
  bob_private_dep(${pkg_name} "${version}" ${on_default})
  if(${PROJECT_NAME}_USE_${pkg_name})
    if (${pkg_name}_PREFIX)
      set(${PROJECT_NAME}_DEP_PREFIXES ${${PROJECT_NAME}_DEP_PREFIXES}
          ${${pkg_name}_PREFIX})
    endif()
    set(${PROJECT_NAME}_DEPS ${${PROJECT_NAME}_DEPS} ${pkg_name})
  endif()
endmacro(bob_public_dep)

function(bob_export_target tgt_name)
  install(TARGETS ${tgt_name} EXPORT ${tgt_name}-target
      RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
      ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
      LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
  install(EXPORT ${tgt_name}-target NAMESPACE ${PROJECT_NAME}::
      DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})
  set(${PROJECT_NAME}_EXPORTED_TARGETS
      ${${PROJECT_NAME}_EXPORTED_TARGETS} ${tgt_name} PARENT_SCOPE)
endfunction(bob_export_target)

macro(bob_end_subdir)
  set(${PROJECT_NAME}_EXPORTED_TARGETS
      ${${PROJECT_NAME}_EXPORTED_TARGETS} PARENT_SCOPE)
  set(${PROJECT_NAME}_DEPS ${${PROJECT_NAME}_DEPS} PARENT_SCOPE)
  set(${PROJECT_NAME}_DEP_PREFIXES ${${PROJECT_NAME}_DEP_PREFIXES} PARENT_SCOPE)
endmacro(bob_end_subdir)

function(bob_end_package)
  include(CMakePackageConfigHelpers)
  set(INCLUDE_INSTALL_DIR ${CMAKE_INSTALL_INCLUDEDIR})
  set(LIB_INSTALL_DIR ${CMAKE_INSTALL_LIBDIR})
  set(CONFIG_CONTENT "
set(${PROJECT_NAME}_VERSION ${${PROJECT_NAME}_VERSION})
include(CMakeFindDependencyMacro)
# we will use find_dependency, but we don't want to force
# our users to have to specify where all of our dependencies
# were installed; that defeats the whole point of automatically
# importing dependencies.
# since the documentation for find_dependency() doesn't mention
# a PATHS argument, we'll temporarily add the prefixes to
# CMAKE_PREFIX_PATH.
set(${PROJECT_NAME}_DEPS \"${${PROJECT_NAME}_DEPS}\")
set(${PROJECT_NAME}_DEP_PREFIXES \"${${PROJECT_NAME}_DEP_PREFIXES}\")
set(${PROJECT_NAME}_BACKUP_PREFIX_PATH \"\${CMAKE_PREFIX_PATH}\")
set(CMAKE_PREFIX_PATH \"\${${PROJECT_NAME}_DEP_PREFIXES};\${CMAKE_PREFIX_PATH}\")
foreach(dep IN LISTS ${PROJECT_NAME}_DEPS)
  find_dependency(\${dep})
endforeach()
set(CMAKE_PREFIX_PATH \"\${${PROJECT_NAME}_BACKUP_PREFIX_PATH}\")
set(${PROJECT_NAME}_EXPORTED_TARGETS \"${${PROJECT_NAME}_EXPORTED_TARGETS}\")
foreach(tgt IN LISTS ${PROJECT_NAME}_EXPORTED_TARGETS)
  include(\${CMAKE_CURRENT_LIST_DIR}/\${tgt}-target.cmake)
endforeach()
foreach(_comp \${${PROJECT_NAME}_FIND_COMPONENTS})
  if (NOT \";\${${PROJECT_NAME}_EXPORTED_TARGETS};\" MATCHES \${_comp})
    set(${PROJECT_NAME}_\${_comp}_FOUND False)
    if ( ${PROJECT_NAME}_FIND_REQUIRED_\${_comp} )
      MESSAGE(SEND_ERROR \"Required ${PROJECT_NAME} component not found: \${_comp}\")
    endif()
  else()
    set(${PROJECT_NAME}_\${_comp}_FOUND True)
  endif()
  MESSAGE(STATUS \"${PROJECT_NAME} component \${_comp} found: \${${PROJECT_NAME}_\${_comp}_FOUND}\")
endforeach()
set(${PROJECT_NAME}_COMPILER \"${CMAKE_CXX_COMPILER}\")
set(${PROJECT_NAME}_CXX_FLAGS \"${CMAKE_CXX_FLAGS}\")
")
  install(FILES
    "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})
  if(PROJECT_VERSION)
    file(WRITE
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake
        "${CONFIG_CONTENT}")
    write_basic_package_version_file(
        ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake
        VERSION ${PROJECT_VERSION}
        COMPATIBILITY SameMajorVersion)
    install(FILES
      "${PROJECT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
      DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/${PROJECT_NAME})
  endif()
endfunction(bob_end_package)
