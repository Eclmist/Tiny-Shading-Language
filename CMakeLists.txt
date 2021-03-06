#
#   This file is a part of Tiny-Shading-Language or TSL, an open-source cross
#   platform programming shading language.
#
#   Copyright (c) 2020-2020 by Jiayin Cao - All rights reserved.
#
#   TSL is a free software written for educational purpose. Anyone can distribute
#   or modify it under the the terms of the GNU General Public License Version 3 as
#   published by the Free Software Foundation. However, there is NO warranty that
#   all components are functional in a perfect manner. Without even the implied
#   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
#   General Public License for more details.
#
#   You should have received a copy of the GNU General Public License along with
#   this program. If not, see <http://www.gnu.org/licenses/gpl-3.0.html>.
#

cmake_minimum_required (VERSION 3.1)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set_property(GLOBAL PROPERTY USE_FOLDERS ON)

# this will avoid generate ZERO_CHECK project
# set(CMAKE_SUPPRESS_REGENERATION true)

# define platform
if (WIN32)
    set(TSL_PLATFORM_WIN true)
    set(TSL_PLATFORM_MAC false)
    set(TSL_PLATFORM_LINUX false)
    set(TSL_PLATFORM_NAME "Windows" )
elseif(APPLE)
    set(TSL_PLATFORM_WIN false)
    set(TSL_PLATFORM_MAC true)
    set(TSL_PLATFORM_LINUX false)
    set(TSL_PLATFORM_NAME "Mac OS" )
elseif(UNIX)
    set(TSL_PLATFORM_WIN false)
    set(TSL_PLATFORM_MAC false)
    set(TSL_PLATFORM_LINUX true)
    set(TSL_PLATFORM_NAME "Linux" )
endif()

project (TSL)

# make sure it looks for a local llvm library
set(LLVM_DIR ${TSL_SOURCE_DIR}/dependencies/llvm/lib/cmake/llvm)

# find llvm library
find_package(LLVM REQUIRED CONFIG)

# output some information to make sure llvm is correctly located
message(STATUS "Found LLVM ${LLVM_PACKAGE_VERSION}")
message(STATUS "Using LLVMConfig.cmake in: ${LLVM_DIR}")

set (PROJ_NAME ${PROJECT_NAME})
set (TSL_LIBRARY_VERSION_MAJOR 0)
set (TSL_LIBRARY_VERSION_MINOR 0)
set (TSL_LIBRARY_VERSION_PATCH 0)

set (versionfile tslversion.h)
message (STATUS "Create ${versionfile} from ${versionfile}.in")
configure_file (${TSL_SOURCE_DIR}/src/include/${versionfile}.in "${TSL_SOURCE_DIR}/src/include/${versionfile}" @ONLY)
list (APPEND version_head "${TSL_SOURCE_DIR}/src/include/${versionfile}")

macro(source_group_by_dir source_files)
    set(sgbd_cur_dir ${CMAKE_CURRENT_SOURCE_DIR}/src)
    foreach(sgbd_file ${${source_files}})
        string(REGEX REPLACE ${sgbd_cur_dir}/\(.*\) \\1 sgbd_fpath ${sgbd_file})
        string(REGEX REPLACE "\(.*\)/.*" \\1 sgbd_group_name ${sgbd_fpath})
        string(COMPARE EQUAL ${sgbd_fpath} ${sgbd_group_name} sgbd_nogroup)
        string(REPLACE "/" "\\" sgbd_group_name ${sgbd_group_name})
        if(sgbd_nogroup)
            set(sgbd_group_name "\\")
        endif(sgbd_nogroup)
        source_group(${sgbd_group_name} FILES ${sgbd_file})
    endforeach(sgbd_file)
endmacro(source_group_by_dir)

file(GLOB_RECURSE project_headers src/*.h src/*.hpp)
file(GLOB_RECURSE project_cpps src/*.cpp)
file(GLOB_RECURSE project_cs src/*.c)
file(GLOB_RECURSE project_ccs src/*.cc)

set(all_files ${project_headers} ${project_cpps} ${project_cs} ${project_ccs} ${version_head})
source_group_by_dir(all_files)

set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${TSL_SOURCE_DIR}/bin")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_RELEASE "${TSL_SOURCE_DIR}/bin")
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY_DEBUG "${TSL_SOURCE_DIR}/bin")

# default including folders
include_directories( "${TSL_SOURCE_DIR}/src" ${LLVM_INCLUDE_DIR} )

# this is to avoid compilation issue in the file generated by flex
add_definitions( -DYY_NO_UNISTD_H )

# make sure bison tells what is wrong
add_definitions( -DYYERROR_VERBOSE )

# Generated source code
set(generated_src ${TSL_SOURCE_DIR}/generated_src/compiled_lex.cpp ${TSL_SOURCE_DIR}/generated_src/compiled_grammer.cpp ${TSL_SOURCE_DIR}/generated_src/compiled_grammer.hpp)

add_executable(TSL ${all_files} ${generated_src})
add_custom_command( OUTPUT ${generated_src}
                    COMMAND make generate_src
                    WORKING_DIRECTORY ${TSL_SOURCE_DIR})

# Separate folder for the generated files
source_group( "generated src" FILES ${generated_src} )

# Setup correct output name for different configurations
set_target_properties( TSL PROPERTIES RELEASE_OUTPUT_NAME "tsl_r" )
set_target_properties( TSL PROPERTIES DEBUG_OUTPUT_NAME "tsl_d" )

if (TSL_PLATFORM_MAC OR TSL_PLATFORM_LINUX)
   set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -pthread -O3")
endif()

if (TSL_PLATFORM_WIN)
    set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /wd4244 /wd4146 /wd4267 /wd4141 /wd4624 /wd4005 /MD" )
    set_target_properties( TSL PROPERTIES COMPILE_FLAGS "${COMPILE_FLAGS} /MD" )
endif()

# specify the llvm library to link
llvm_map_components_to_libnames(llvm_libs core)

# link llvm libaries
target_link_libraries(TSL ${llvm_libs})

# hide the llvm generated project
set_target_properties (intrinsics_gen PROPERTIES FOLDER LLVM_Generated)