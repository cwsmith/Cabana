configure_file(CabanaCore_config.hpp.cmakein CabanaCore_config.hpp)

#-----------------------------------------------------------------------------

file(GLOB HEADERS_PUBLIC *.hpp)
file(GLOB SOURCES *.cpp)

#-----------------------------------------------------------------------------

file(GLOB HEADERS_IMPL impl/*.hpp)
file(GLOB SOURCES_IMPL impl/*.cpp)

install(FILES ${HEADERS_PUBLIC} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}) 
install(FILES ${HEADERS_IMPL} DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/impl/)
install(FILES ${CMAKE_CURRENT_BINARY_DIR}/CabanaCore_config.hpp DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}) 

#-----------------------------------------------------------------------------

add_library(cabanacore ${SOURCES} ${SOURCES} ${SOURCES_IMPL})
target_include_directories(cabanacore PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
target_include_directories(cabanacore PUBLIC
  $<BUILD_INTERFACE:${CMAKE_CURRENT_BINARY_DIR}>
  $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)
message(STATUS "Kokkos_INCLUDE_DIRS ${Kokkos_INCLUDE_DIRS}")
target_include_directories(cabanacore INTERFACE ${Kokkos_INCLUDE_DIRS})
target_link_libraries(cabanacore PUBLIC ${Kokkos_LIBRARIES})

cabana_export_lib(cabanacore "${HEADERS_PUBLIC}")

bob_end_subdir()
