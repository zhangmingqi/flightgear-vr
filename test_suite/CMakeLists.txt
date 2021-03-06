# CMake module includes.
include(SetupFGFSEmbeddedResources)
include(SetupFGFSIncludes)
include(SetupFGFSLibraries)
include(SetupMSVCGrouping)

# Add each test suite category.
foreach(test_category
        gui_tests
        simgear_tests
        system_tests
        unit_tests
    )
    add_subdirectory(${test_category})
endforeach(test_category)

# Add the helpers.
add_subdirectory(helpers)

# Add all test suite sources and headers.
set(TESTSUITE_SOURCES
    ${TESTSUITE_SOURCES}
    bootstrap.cxx
    dataStore.cxx
    fgCompilerOutputter.cxx
    fgTestListener.cxx
    fgTestRunner.cxx
    formatting.cxx
    logging.cxx
    testSuite.cxx
)
set(TESTSUITE_HEADERS
    ${TESTSUITE_HEADERS}
    dataStore.hxx
    fgCompilerOutputter.hxx
    fgTestListener.hxx
    fgTestRunner.hxx
    formatting.hxx
    logging.hxx
)

# The test suite output directory.
set(TESTSUITE_OUTPUT_DIR "${CMAKE_CURRENT_BINARY_DIR}")

# Get the CppUnit sources and headers to be built into the test suite.
if (NOT SYSTEM_CPPUNIT)
    message(STATUS "CppUnit: Building the FlightGear supplied CppUnit library")

    get_property(CPPUNIT_SOURCES GLOBAL PROPERTY CPPUNIT_SOURCES)
    get_property(CPPUNIT_HEADERS GLOBAL PROPERTY CPPUNIT_HEADERS)

    include_directories("${PROJECT_SOURCE_DIR}/3rdparty/cppunit/include")

    add_library(CppUnitLib STATIC ${CPPUNIT_SOURCES} ${CPPUNIT_HEADERS})
    set(CPPUNIT_LIBRARIES CppUnitLib)
else()
    message(STATUS "CppUnit: Linking to the system supplied CppUnit library")
endif()

#-----------------------------------------------------------------------------
# Set up all test suites as CTests.

# System test suites.

# Unit test suites.
add_test(AddonManagementUnitTests ${TESTSUITE_OUTPUT_DIR}/run_test_suite --ctest -u AddonManagementTests)
add_test(FlightplanUnitTests ${TESTSUITE_OUTPUT_DIR}/run_test_suite --ctest -u FlightplanTests)
add_test(LaRCSimMatrixUnitTests ${TESTSUITE_OUTPUT_DIR}/run_test_suite --ctest -u LaRCSimMatrixTests)
add_test(MktimeUnitTests ${TESTSUITE_OUTPUT_DIR}/run_test_suite --ctest -u MktimeTests)
add_test(NasalSysUnitTests ${TESTSUITE_OUTPUT_DIR}/run_test_suite --ctest -u NasalSysTests)
add_test(PosInitUnitTests ${TESTSUITE_OUTPUT_DIR}/run_test_suite --ctest -u PosInitTests)

# GUI test suites.

# Simgear unit test suites.
add_test(MathGeodesySimgearUnitTests ${TESTSUITE_OUTPUT_DIR}/run_test_suite --ctest -m MathGeodesyTests)
add_test(SimgearPropsSimgearUnitTests ${TESTSUITE_OUTPUT_DIR}/run_test_suite --ctest -m SimgearPropsTests)

#-----------------------------------------------------------------------------
# Set up the binary.

# Set up the embedded resources.
setup_fgfs_embedded_resources()

# Sort the sources and headers for MSVC.
setup_msvc_grouping()

# Additional search paths for includes.
setup_fgfs_includes()

# All sources and headers to be built into the test suite.
get_property(FG_SOURCES GLOBAL PROPERTY FG_SOURCES)
get_property(FG_HEADERS GLOBAL PROPERTY FG_HEADERS)
get_property(EMBEDDED_RESOURCE_SOURCES GLOBAL PROPERTY EMBEDDED_RESOURCE_SOURCES)
get_property(EMBEDDED_RESOURCE_HEADERS GLOBAL PROPERTY EMBEDDED_RESOURCE_HEADERS)

# Set up the separate executable for running the test suite.
add_executable(run_test_suite
    ${FG_SOURCES}
    ${FG_HEADERS}
    ${EMBEDDED_RESOURCE_SOURCES}
    ${EMBEDDED_RESOURCE_HEADERS}
    ${TESTSUITE_SOURCES}
    ${TESTSUITE_HEADERS}
)
set_target_properties(run_test_suite
    PROPERTIES
    RUNTIME_OUTPUT_DIRECTORY "${TESTSUITE_OUTPUT_DIR}"
)
if(ENABLE_AUTOTESTING)
    set(TEST_SUITE_COMMENT "Running the full FlightGear test suite.")
    if(WIN32)
        set(TEST_SUITE_COMMAND "run_test_suite.exe")
        set(TEST_SUITE_WORKING_DIRECTORY "${TESTSUITE_OUTPUT_DIR}/${CMAKE_BUILD_TYPE}")
    else()
        set(TEST_SUITE_COMMAND "run_test_suite")
        set(TEST_SUITE_WORKING_DIRECTORY "${TESTSUITE_OUTPUT_DIR}")
    endif(WIN32)
else()
    set(TEST_SUITE_COMMENT "Building the FlightGear test suite.")
endif(ENABLE_AUTOTESTING)

add_custom_target(test_suite
    ${TEST_SUITE_COMMAND}
    DEPENDS run_test_suite
    WORKING_DIRECTORY ${TEST_SUITE_WORKING_DIRECTORY}
    COMMENT ${TEST_SUITE_COMMENT}
)

# Set up the target links.
setup_fgfs_libraries(run_test_suite)

# Additional libraries just for the test suite.
target_link_libraries(run_test_suite ${CPPUNIT_LIBRARIES})
