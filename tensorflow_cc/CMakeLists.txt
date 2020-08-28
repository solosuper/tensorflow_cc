cmake_minimum_required(VERSION 3.13 FATAL_ERROR)

if(DEFINED ENV{TENSORFLOW_TAG})
  set(version "$ENV{TENSORFLOW_TAG}")
else()
  file(STRINGS "${CMAKE_CURRENT_SOURCE_DIR}/PROJECT_VERSION" version)
endif()

project(
  "tensorflow_cc"
  VERSION "${version}"
)

# If enabled, bazel has to be installed.
option(ALLOW_CUDA "Try to find and use CUDA." ON)
option(REQUIRE_CUDA "Make sure to find and use CUDA (implies ALLOW_CUDA)." OFF)
set(TENSORFLOW_TAG "v${version}" CACHE STRING "The tensorflow release tag to be checked out (default v${version}).")
set(TARGET_CXX_STANDARD "cxx_std_11" CACHE STRING "C++ standard to be enforced when linking to TensorflowCC targets (e.g., cxx_std_11).")

set_property(CACHE TARGET_CXX_STANDARD PROPERTY STRINGS
    "cxx_std_11" "cxx_std_14" "cxx_std_17" "cxx_std_20")

# ----------------------------------------------
# Include External Projects for Tensorflow Build
# ----------------------------------------------
# Configure the build_tensorflow script.
configure_file("cmake/build_tensorflow.sh.in" "build_tensorflow.sh" @ONLY)

if(DEFINED ENV{TF_CUDA_COMPUTE_CAPABILITIES})
  message(STATUS "TF_CUDA_COMPUTE_CAPABILITIES: $ENV{TF_CUDA_COMPUTE_CAPABILITIES}")
endif()

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/cmake")
include(TensorflowBase)

# ------------------------------
# Define Tensorflow_CC Interface
# ------------------------------

add_library(${PROJECT_NAME} INTERFACE)
target_compile_features(${PROJECT_NAME} INTERFACE ${TARGET_CXX_STANDARD})

target_include_directories(
  ${PROJECT_NAME} INTERFACE
  $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/tensorflow/bazel-bin/tensorflow/include>
  $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/tensorflow/bazel-bin/tensorflow/include/src>
  $<INSTALL_INTERFACE:include>
  $<INSTALL_INTERFACE:include/src>
)

target_link_directories( # CMake 3.13
  ${PROJECT_NAME} INTERFACE
  $<BUILD_INTERFACE:${CMAKE_BINARY_DIR}/lib>
  $<INSTALL_INTERFACE:lib>
)

target_link_libraries(
  ${PROJECT_NAME} INTERFACE
  libtensorflow_cc.so
  dl pthread
)

# ----------------------------------------
# Configure CMake Config and Version Files
# ----------------------------------------

set(project_targets ${PROJECT_NAME})

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# 1) Set variables that will be used below.
string(TOLOWER ${PROJECT_NAME} package_name)
set(config_install_dir  "share/cmake/${PROJECT_NAME}/")
set(include_install_dir "include")
set(namespace           "${PROJECT_NAME}::")
set(project_config_in   "${CMAKE_CURRENT_LIST_DIR}/cmake/config.cmake.in")
set(project_config      "${package_name}-config.cmake")
set(targets_export_name "${package_name}-targets")
set(version_config      "${package_name}-config-version.cmake")

# 3) Create file '<project>-config.cmake'
# Should be used instead of the plain 'configure_file'-command.
# This command needs the file generated in step 2.
configure_package_config_file(
  ${CMAKE_CURRENT_SOURCE_DIR}/cmake/config.cmake.in # input
  ${CMAKE_BINARY_DIR}/${project_config}             # output
  INSTALL_DESTINATION ${config_install_dir}         # has no visible effect, but must match
                                                    # destination in install commands below
  NO_CHECK_REQUIRED_COMPONENTS_MACRO                # Enabled since this library has no components
  NO_SET_AND_CHECK_MACRO
)

# 4) Create file '<project>-config-version.cmake'
write_basic_package_version_file(
  ${CMAKE_BINARY_DIR}/${version_config}
  COMPATIBILITY SameMajorVersion
)

# 5) Generate an export file for the **build tree**
export(
  TARGETS ${project_targets}
  NAMESPACE ${namespace}
  FILE ${CMAKE_BINARY_DIR}/${targets_export_name}.cmake
)

# --- INSTALL --- #
# What comes below applies to when the 'install' target is built,
# e.g. when you run 'make install'.

# 6) Install the config-, version- and license files.
install(FILES
  ${CMAKE_BINARY_DIR}/${project_config}
  ${CMAKE_BINARY_DIR}/${version_config}
  DESTINATION ${config_install_dir}
)

install(FILES
  ${CMAKE_SOURCE_DIR}/../LICENSE
  DESTINATION "${CMAKE_INSTALL_DOCDIR}"
)

# 7) COPY header files to installation tree
install(
  DIRECTORY   "${CMAKE_CURRENT_BINARY_DIR}/tensorflow/bazel-bin/tensorflow/include/"
  DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}/"
  FILES_MATCHING PATTERN "*.h"
                 PATTERN "*.inc"
                 REGEX ".*Eigen.*"
)

set(_LIBDIR "${CMAKE_CURRENT_BINARY_DIR}/tensorflow/bazel-bin/tensorflow")

install(
  FILES
    "${_LIBDIR}/libtensorflow_cc.so"
    "${_LIBDIR}/libtensorflow_cc.so.${PROJECT_VERSION_MAJOR}"
    "${_LIBDIR}/libtensorflow_cc.so.${PROJECT_VERSION}"
  TYPE LIB
)
unset(_LIBDIR)

# 8) Associate the target (i.e. the library) with an export.
# An export is a CMake entity, just like targets,
# and is not to be confused with the exported FILE in step 5.
install(
  TARGETS ${project_targets}
  EXPORT  ${targets_export_name} # associates the target with the named export.
  LIBRARY DESTINATION  ${CMAKE_INSTALL_LIBDIR}
  ARCHIVE DESTINATION  ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION  ${CMAKE_INSTALL_BINDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)

# 9) Generate and install an export file for the **installation tree**
# Must match the export created in step 8.
install(
  EXPORT      ${targets_export_name}
  NAMESPACE   ${namespace}
  DESTINATION ${config_install_dir}
)

# 10) CPack
include(cmake/packaging.cmake)

# A target called 'package' is automaitcally created. It makes a .deb.
# Create additional target to compress as tar.bz2.
add_custom_target(compress
  COMMAND ${CMAKE_CPACK_COMMAND} "-G" "TBZ2"
  COMMENT "Running CPack. Please wait..."
  DEPENDS ${CPACK_COMPONENTS_ALL}
  WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
)
