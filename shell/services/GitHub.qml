pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "../utils/GitHub.js" as Hub
import "../utils/Log.js" as Log

Singleton {
    id: hub

    property bool isActive: false
    property string detected: ""
    property string status: "idle"
    property string source: ""
    property var days: []
    property var pinned: []
    property var repositories: []
    property var pushes: []
    property real fetchedAt: 0
    property bool hasCommandLine: true
    readonly property string typed: Config.data.profile.github.trim()
    readonly property string login: typed.length > 0 ? typed : detected
    readonly property var chosen: Config.data.profile.favorites
    readonly property var favorites: Hub.favoritesOf(repositories, pinned, chosen)
    readonly property bool isBusy: status === "loading"
    readonly property bool isSignedIn: source === "gh"
    readonly property bool isConnecting: signIn.running

    function connect() {
        if (!signIn.running)
            signIn.running = true
    }

    function refresh() {
        if (!isActive || isBusy)
            return
        if (login.length === 0) {
            if (!hasCommandLine) {
                status = "missing"
                return
            }
            status = "loading"
            whoami.running = true
            return
        }
        if (!Hub.isLogin(login)) {
            status = "missing"
            return
        }
        status = "loading"
        if (hasCommandLine) {
            calendar.command = Hub.graphCommand(login)
            calendar.running = true
        } else {
            fetchPublic()
        }
    }

    function finish(foundSource) {
        source = foundSource
        status = "ready"
        fetchedAt = Date.now()
        supervisor.succeed()
    }

    function fail(reason) {
        status = "failed"
        supervisor.fail(reason)
    }

    function request(url, onReady) {
        const call = new XMLHttpRequest()
        call.onreadystatechange = () => {
            if (call.readyState !== XMLHttpRequest.DONE)
                return
            if (call.status !== 200) {
                hub.fail("api.github.com answered with status " + call.status)
                return
            }
            try {
                onReady(JSON.parse(call.responseText))
            } catch (error) {
                hub.fail("api.github.com sent an unreadable answer: " + error)
            }
        }
        call.open("GET", url)
        call.send()
    }

    function fetchPublic() {
        request(Hub.reposLink(login), repos => {
            hub.pinned = []
            hub.repositories = Hub.readRepos(repos)
            hub.request(Hub.eventsLink(hub.login), answer => {
                const found = Hub.readPushes(answer)
                hub.pushes = found
                hub.days = Hub.calendarFromPushes(found, Appearance.settings.profile.weeks * Appearance.settings.profile.days, Date.now())
                hub.finish("public")
            })
        })
    }

    function open(url) {
        if (url.startsWith("https://github.com/"))
            Quickshell.execDetached(["xdg-open", url])
    }

    onLoginChanged: {
        days = []
        pinned = []
        repositories = []
        pushes = []
        fetchedAt = 0
        if (status !== "loading")
            refresh()
    }
    onIsActiveChanged: if (isActive && Date.now() - fetchedAt > Motion.settings.githubFresh) refresh()

    Supervisor {
        id: supervisor
        name: "github"
        isActive: hub.isActive
        onRestarted: {
            hub.status = "idle"
            hub.refresh()
        }
    }

    Process {
        id: signIn
        command: Hub.connectCommand()
        onExited: code => {
            if (code === 127)
                Log.warn("github", "no terminal found to run gh auth login; install one or set TERMINAL")
            hub.hasCommandLine = true
            hub.detected = ""
            hub.status = "idle"
            hub.fetchedAt = 0
            hub.refresh()
        }
    }

    Process {
        id: whoami
        command: Hub.loginCommand()
        stdout: StdioCollector {
            id: whoamiText
        }
        onExited: code => {
            hub.status = "idle"
            const found = whoamiText.text.trim()
            if (code === 0 && Hub.isLogin(found)) {
                hub.detected = found
                return
            }
            Log.info("github", "gh is not signed in; type a GitHub name in settings to read public activity")
            hub.hasCommandLine = false
            hub.status = "missing"
        }
    }

    Process {
        id: calendar
        stdout: StdioCollector {
            id: calendarText
        }
        onExited: code => {
            if (code !== 0) {
                Log.info("github", "gh exited with code " + code + "; reading public activity instead")
                hub.hasCommandLine = false
                hub.fetchPublic()
                return
            }
            try {
                const answer = JSON.parse(calendarText.text)
                hub.days = Hub.readCalendar(answer)
                hub.pinned = Hub.readPinned(answer)
                hub.repositories = Hub.readRepositories(answer)
                events.command = Hub.eventsCommand(hub.login)
                events.running = true
            } catch (error) {
                hub.fail("gh sent an unreadable answer: " + error)
            }
        }
    }

    Process {
        id: events

        property var found: []

        stdout: StdioCollector {
            id: eventsText
        }
        onExited: code => {
            if (code !== 0) {
                hub.pushes = []
                hub.finish("gh")
                return
            }
            try {
                events.found = Hub.readPushes(JSON.parse(eventsText.text))
            } catch (error) {
                hub.fail("gh sent unreadable events: " + error)
                return
            }
            const query = Hub.headlineQuery(events.found)
            if (query.length === 0) {
                hub.pushes = events.found
                hub.finish("gh")
                return
            }
            headlines.command = Hub.headlineCommand(query)
            headlines.running = true
        }
    }

    Process {
        id: headlines
        stdout: StdioCollector {
            id: headlinesText
        }
        onExited: code => {
            let answer = null
            try {
                answer = code === 0 ? JSON.parse(headlinesText.text) : null
            } catch (error) {
                answer = null
            }
            hub.pushes = Hub.withHeadlines(events.found, answer)
            hub.finish("gh")
        }
    }
}
