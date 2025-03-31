set (CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)
cmake_minimum_required(VERSION 3.5)

project(m5_manager C CXX)

# set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -lnuma")
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

set(CMAKE_CXX_FLAGS "-Wall -Wextra")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -march=native")
set(CMAKE_CXX_FLAGS_DEBUG "-g")
set(CMAKE_CXX_FLAGS_RELEASE "-O2")

set(PCM_DIR /home/zeduoyu2/pcm)

# file(GLOB SOURCES "src/*.c")

add_executable(${PROJECT_NAME} 
    src/util.cpp
    src/csr.cpp
    src/worker.cpp
    src/algo.cpp
    src/main.cpp
)
target_include_directories(${PROJECT_NAME} 
    PRIVATE
    ${PROJECT_SOURCE_DIR}/include
)
target_compile_options(${PROJECT_NAME} PRIVATE -g)

# target_link_libraries(${PROJECT_NAME} numa pthread ${PCM_DIR}/build/src/libpcm.a)
#target_link_libraries(${PROJECT_NAME} numa pthread ${PCM_DIR}/build/src/libpcm.a)
target_link_libraries(${PROJECT_NAME} numa pthread)

## Link intel pcm library
# add_executable(pcm-memory src/pcm-memory.cpp)
# target_include_directories(pcm-memory 
#     PRIVATE
#     ${PROJECT_SOURCE_DIR}/include-pcm
# )
# target_link_libraries(pcm-memory ${PCM_DIR}/build/src/libpcm.a pthread)
# target_include_directories(${PROJECT_NAME} PRIVATE ${PCM_DIR}/src)
# target_link_libraries(${PROJECT_NAME} ${PCM_DIR}/build/src/libpcm.a)
# target_link_libraries(${PROJECT_NAME} ${PCM_DIR}/build/lib/libpcm.so)
