cmake_minimum_required(VERSION 3.21)
project(Sukoon VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

# Qt 6.5+ is required for QtQuick.Effects (MultiEffect: blur, glow, shadow).
set(SUKOON_QT_MIN 6.5 CACHE STRING "Minimum Qt version")
find_package(Qt6 ${SUKOON_QT_MIN} REQUIRED COMPONENTS Core Gui Network Qml Quick QuickControls2 WebSockets)

if(SUKOON_QT_MIN VERSION_GREATER_EQUAL 6.5)
    qt_standard_project_setup(REQUIRES 6.5)
else()
    qt_standard_project_setup()
endif()

qt_add_executable(sukoon
    src/main.cpp
)

# Must be set before qt_add_qml_module or the singleton isn't registered.
set_source_files_properties(qml/Theme.qml PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(sukoon
    URI Sukoon
    VERSION 1.0
    SOURCES
        src/apiclient.h      src/apiclient.cpp
        src/session.h        src/session.cpp
        src/appsettings.h    src/appsettings.cpp
        src/breathcontroller.h src/breathcontroller.cpp
        src/roomsocket.h     src/roomsocket.cpp
        src/catalog.h        src/catalog.cpp
    QML_FILES
        qml/Main.qml
        qml/Theme.qml
        qml/components/AuroraBackground.qml
        qml/components/GradientOrb.qml
        qml/components/GlassCard.qml
        qml/components/GradientButton.qml
        qml/components/Chip.qml
        qml/components/Header.qml
        qml/components/TabBar.qml
        qml/components/Sheet.qml
        qml/components/Field.qml
        qml/components/Toast.qml
        qml/sheets/ConsentSheet.qml
        qml/sheets/SosSheet.qml
        qml/sheets/SettingsSheet.qml
        qml/pages/OnboardingPage.qml
        qml/pages/HomePage.qml
        qml/pages/RoomsPage.qml
        qml/pages/RoomPage.qml
        qml/pages/BreathePage.qml
        qml/pages/BuddyPage.qml
        qml/pages/CirclePage.qml
)


target_link_libraries(sukoon PRIVATE
    Qt6::Core Qt6::Gui Qt6::Network Qt6::Qml Qt6::Quick Qt6::QuickControls2 Qt6::WebSockets)

set_target_properties(sukoon PROPERTIES
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE)

install(TARGETS sukoon BUNDLE DESTINATION . RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})
