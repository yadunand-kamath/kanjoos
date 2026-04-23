cmake_minimum_required(VERSION 3.16)

project(kanjoos VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Core Gui Qml Charts Widgets QuickControls2)

qt_standard_project_setup(REQUIRES 6.10)

qt_add_executable(appkanjoos
    main.cpp
)

qt_add_qml_module(appkanjoos
    URI kanjoos
    QML_FILES
        Main.qml
        qml/TitleBar.qml
        qml/page/CashFlow.qml
        qml/page/Overview.qml
        qml/page/Planning.qml
        qml/page/Portfolio.qml
        qml/page/SafetyNet.qml
    RESOURCES
        assets/fonts/BJCree-Bold.ttf
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(appkanjoos PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.appkanjoos
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appkanjoos PRIVATE
    Qt6::Charts
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
)

install(TARGETS appkanjoos
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
