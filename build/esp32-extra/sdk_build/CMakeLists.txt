cmake_minimum_required(VERSION 3.5)

list(APPEND EXTRA_COMPONENT_DIRS
    "${CMAKE_CURRENT_SOURCE_DIR}/managed_components/joltwallet__littlefs"
 )

include($ENV{IDF_PATH}/tools/cmake/project.cmake)

# Partition table configuratie (optioneel)
idf_build_set_property(PARTITION_TABLE_CUSTOM 1)
idf_build_set_property(PARTITION_TABLE_FILENAME "partitions.csv")

project(forth)
