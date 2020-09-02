cmake_minimum_required(VERSION 3.3 FATAL_ERROR)
add_executable(example example.cpp)

find_package(tensorflow_cpp REQUIRED)
target_link_libraries(example tensorflow_cpp::tensorflow_cpp)

# link cuda if it is available
find_package(CUDA)
if(CUDA_FOUND)
  target_link_libraries(example ${CUDA_LIBRARIES})
endif()
