# Preamble
cmake_minimum_required(VERSION 3.28)
list(APPEND CMAKE_MESSAGE_CONTEXT "price_comparator")
set(CMAKE_CXX_SCAN_FOR_MODULES OFF) # https://discourse.cmake.org/t/cmake-3-28-cmake-cxx-compiler-clang-scan-deps-notfound-not-found/9244
project(price_comparator VERSION 0.0.0 LANGUAGES CXX)

# Project wide setup
set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Dependencies
find_package(Qt6 6.5 REQUIRED COMPONENTS Core Widgets Quick WebView)

qt_standard_project_setup(REQUIRES 6.5)

# Targets
qt_add_executable(appprice_comparator
    main.cpp
)

qt_add_qml_module(appprice_comparator
    URI price_comparator
    VERSION 0.0.0
    QML_FILES Main.qml
    QML_FILES WebViewStore.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appprice_comparator PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appprice_comparator
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appprice_comparator
    PRIVATE Qt6::Widgets Qt6::Quick Qt6::WebView
)

include(GNUInstallDirs)
install(TARGETS appprice_comparator
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

add_library(price_comparator INTERFACE)

if (ANDROID)
    include(FetchContent)
    FetchContent_Declare(
      android_openssl
      DOWNLOAD_EXTRACT_TIMESTAMP true
      URL      https://github.com/KDAB/android_openssl/archive/refs/heads/master.zip
    )
    FetchContent_MakeAvailable(android_openssl)
    include(${android_openssl_SOURCE_DIR}/android_openssl.cmake)
endif()

if (ANDROID)
    add_android_openssl_libraries(appprice_comparator)
endif()
