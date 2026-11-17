import QtQuick

QtObject {
    readonly property var byKey: ({
            "clock": clock,
            "profile": profile,
            "login": login,
            "weather": weather,
            "music": music,
            "dashboard": dashboard,
            "notifications": notifications
        })

    readonly property Component clock: Component {
        ClockModule {}
    }
    readonly property Component profile: Component {
        ProfileModule {}
    }
    readonly property Component login: Component {
        LoginModule {}
    }
    readonly property Component weather: Component {
        WeatherModule {}
    }
    readonly property Component music: Component {
        MusicModule {}
    }
    readonly property Component dashboard: Component {
        DashboardModule {}
    }
    readonly property Component notifications: Component {
        NotificationsModule {}
    }
}
