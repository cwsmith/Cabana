##---------------------------------------------------------------------------##
## Cabana/CMakeLists.txt
##---------------------------------------------------------------------------##
cmake_minimum_required(VERSION 3.9)

##---------------------------------------------------------------------------##
# Define your project name and set up major project options
##---------------------------------------------------------------------------##
project(Cabana LANGUAGES CXX VERSION 0.1.0)

include(cmake/bob.cmake)
bob_begin_package()


if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CXX_FLAGS)
  #release comes with -O3 by default
  set(CMAKE_BUILD_TYPE Release CACHE STRING "Choose the type of build, options are: None Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CXX_FLAGS)

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF) #...without compiler extensions like gnu++11

option(CMAKE_VERBOSE_MAKEFILE "Generate verbose Makefiles" OFF)
include(GNUInstallDirs)

find_package(Kokkos REQUIRED)
message(STATUS "Kokkos enabled - Overriding compiler selection for consistency
with Kokkos install")
set(CMAKE_CXX_COMPILER ${KokkosCore_CXX_COMPILER})
set(CMAKE_C_COMPILER ${KokkosCore_C_COMPILER})
set(CMAKE_FORTRAN_COMPILER ${KokkosCore_FORTRAN_COMPILER})
message(STATUS "Kokkos CMAKE_CXX_COMPILER ${KokkosCore_CXX_COMPILER}")
message(STATUS "Kokkos CMAKE_C_COMPILER ${KokkosCore_C_COMPILER}")
message(STATUS "Kokkos CMAKE_FORTRAN_COMPILER
${KokkosCore_FORTRAN_COMPILER}")

message(STATUS "Kokkos enabled - Overriding compiler flags for
consistency with Kokkos install")
set(CMAKE_CXX_FLAGS ${KokkosCore_CXX_FLAGS})
set(CMAKE_C_FLAGS ${KokkosCore_C_FLAGS})
set(CMAKE_FORTRAN_FLAGS ${KokkosCore_FORTRAN_FLAGS})
message(STATUS "Kokkos CMAKE_CXX_FLAGS ${KokkosCore_CXX_FLAGS}")
message(STATUS "Kokkos CMAKE_C_FLAGS ${KokkosCore_C_FLAGS}")
message(STATUS "Kokkos CMAKE_FORTRAN_FLAGS ${KokkosCore_FORTRAN_FLAGS}")

option(Cabana_ENABLE_Serial "Build Cabana with Serial support" ON)

option(Cabana_ENABLE_Pthread "Build Cabana with Pthread support" OFF)
if( Cabana_ENABLE_Pthread )
  find_package(Threads)
endif()

option(Cabana_ENABLE_OpenMP "Build Cabana with OpenMP support" OFF)
if( Cabana_ENABLE_OpenMP )
  find_package(OpenMP)
endif()

option(Cabana_ENABLE_Cuda "Build Cabana with Cuda support" OFF)
if( Cabana_ENABLE_Cuda )
  enable_language( CUDA )
endif()

option(Cabana_ENABLE_TESTING "Build tests" OFF)
if(Cabana_ENABLE_TESTING)
  enable_testing()
endif()

find_package(Doxygen)
if(Doxygen_FOUND)
  doxygen_add_docs(doxygen core)
endif()

option(Cabana_ENABLE_MPI "Build Cabana with MPI support" OFF)
if(Cabana_ENABLE_MPI)
  find_package(MPI REQUIRED)
endif()

#------------------------------------------------------------------------------#
# Architecture
#------------------------------------------------------------------------------#
if(CMAKE_BUILD_TYPE STREQUAL "Release")
  set(Cabana_BUILD_MARCH "" CACHE STRING "Arch to use with -march= (if empty CMake will try to use 'native') in release build and only release build")

  # Try -march first. On platforms that don't support it, GCC will issue
  # a hard error, so we'll know not to use it.
  if(Cabana_BUILD_MARCH)
    set(INTERNAL_Cabana_BUILD_MARCH ${Cabana_BUILD_MARCH})
  else()
    set(INTERNAL_Cabana_BUILD_MARCH "native")
  endif()

  include(CheckCXXCompilerFlag)
  check_cxx_compiler_flag("-march=${INTERNAL_Cabana_BUILD_MARCH}" COMPILER_SUPPORTS_MARCH)
  if(COMPILER_SUPPORTS_MARCH)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=${INTERNAL_Cabana_BUILD_MARCH}")
  elseif(Cabana_BUILD_MARCH)
    message(FATAL_ERROR "The flag -march=${INTERNAL_Cabana_BUILD_MARCH} is not supported by the compiler")
  else()
    unset(INTERNAL_Cabana_BUILD_MARCH)
  endif()

  option(Cabana_ENABLE_COVERAGE_BUILD "Do a coverage build" OFF)
  if(Cabana_ENABLE_COVERAGE_BUILD)
      message(STATUS "Enabling coverage build")
      set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} --coverage -O0")
      set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} --coverage")
      set(CMAKE_SHARED_LINKER_FLAGS "${CMAKE_SHARED_LINKER_FLAGS} --coverage")
  endif()
endif()

##---------------------------------------------------------------------------##
## Print the revision number to stdout
##---------------------------------------------------------------------------##

FIND_PACKAGE(Git)
IF(GIT_FOUND AND IS_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/.git)
    EXECUTE_PROCESS(
        COMMAND           ${GIT_EXECUTABLE} log --pretty=format:%H -n 1
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        OUTPUT_VARIABLE   Cabana_GIT_COMMIT_HASH
        )
ELSE()
    SET(Cabana_GIT_COMMIT_HASH "Not a git repository")
ENDIF()
MESSAGE(STATUS "Cabana Revision = '${Cabana_GIT_COMMIT_HASH}'")

macro(cabana_export_lib target headers)
  bob_export_target(${target})
  install(FILES ${headers} DESTINATION include)
endmacro()

add_subdirectory(core)

# this INTERFACE target bundles all the enabled libraries together
add_library(cabana INTERFACE)
target_link_libraries(cabana INTERFACE ${Cabana_EXPORTED_TARGETS})
cabana_export_lib(cabana "")

configure_file(cmake/Cabana.pc.cmakein Cabana.pc @ONLY)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/Cabana.pc DESTINATION ${CMAKE_INSTALL_LIBDIR}/pkgconfig)

bob_end_package()
