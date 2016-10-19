if( NOT TARGET Cinder-Harfbuzz )
	
	get_filename_component( CINDER_PATH "${CMAKE_CURRENT_LIST_DIR}/../../../.." ABSOLUTE )
  get_filename_component( BLOCK_PATH "${CMAKE_CURRENT_LIST_DIR}/../.." ABSOLUTE )

	if( NOT TARGET cinder )
		include( "${CINDER_PATH}/proj/cmake/configure.cmake" )
		find_package( cinder REQUIRED PATHS
			"${CINDER_PATH}/${CINDER_LIB_DIRECTORY}"
			"$ENV{CINDER_PATH}/${CINDER_LIB_DIRECTORY}" )
	endif()
		
	string( TOLOWER "${CINDER_TARGET}" CINDER_TARGET_LOWER )
	
  get_filename_component( HARFBUZZ_LIBS_PATH "${BLOCK_PATH}/lib/${CINDER_TARGET_LOWER}" ABSOLUTE )
  set( Cinder-Harfbuzz_LIBRARIES ${HARFBUZZ_LIBS_PATH}/libharfbuzz.a )
	set( Cinder-Harfbuzz_INCLUDES ${BLOCK_PATH}/include/${CINDER_TARGET_LOWER}/harfbuzz ${CINDER_PATH}/include/freetype )

endif()
