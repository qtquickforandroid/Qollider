cmake_minimum_required(VERSION 3.22)
project(dpr_fix)

add_library(dpr_fix SHARED dpr_fix.cpp)
target_link_libraries(dpr_fix log)
