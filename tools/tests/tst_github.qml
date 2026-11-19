import QtQuick
import QtTest
import "../../shell/utils/GitHub.js" as Hub

TestCase {
    name: "GitHub"

    readonly property var graphAnswer: ({ data: { user: {
        contributionsCollection: { contributionCalendar: { weeks: [
            { contributionDays: [{ date: "2026-11-15", contributionCount: 0 }, { date: "2026-11-16", contributionCount: 4 }] },
            { contributionDays: [{ date: "2026-11-17", contributionCount: 2 }] }
        ] } },
        pinnedItems: { nodes: [
            { nameWithOwner: "someone/shell", url: "https://github.com/someone/shell", description: "A shell", stargazerCount: 2, pushedAt: "2026-11-17T10:00:00Z", primaryLanguage: { name: "QML" } },
            {}
        ] },
        repositories: { nodes: [
            { nameWithOwner: "someone/notes", url: "https://github.com/someone/notes", description: null, stargazerCount: 0, pushedAt: "2026-11-16T10:00:00Z", primaryLanguage: null },
            { nameWithOwner: "someone/shell", url: "https://github.com/someone/shell", description: "A shell", stargazerCount: 2, pushedAt: "2026-11-17T10:00:00Z", primaryLanguage: { name: "QML" } }
        ] }
    } } })

    readonly property var events: [
        { type: "WatchEvent", repo: { name: "someone/shell" }, created_at: "2026-11-17T09:00:00Z" },
        { type: "PushEvent", repo: { name: "someone/shell" }, payload: { ref: "refs/heads/main", head: "abc" }, created_at: "2026-11-16T09:00:00Z" },
        { type: "PushEvent", repo: { name: "someone/notes" }, payload: { ref: "refs/heads/master", head: "def", commits: [{ sha: "def", message: "Fix notes\n\nbody" }] }, created_at: "2026-11-17T08:00:00Z" },
        { type: "PushEvent", repo: { name: "someone/a" }, payload: { head: "1" }, created_at: "2026-11-10T08:00:00Z" },
        { type: "PushEvent", repo: { name: "someone/b" }, payload: { head: "2" }, created_at: "2026-11-09T08:00:00Z" }
    ]

    function test_theCalendarFlattensWeeksIntoDays() {
        const days = Hub.readCalendar(graphAnswer)
        compare(days.length, 3)
        compare(days[1].count, 4)
        compare(Hub.lastDays(days, 2)[0].date, "2026-11-16")
        compare(Hub.readCalendar(null).length, 0)
    }

    function test_repositoriesAreReadFromPinnedAndOwned() {
        const pinned = Hub.readPinned(graphAnswer)
        compare(pinned.length, 1)
        compare(pinned[0].language, "QML")
        const owned = Hub.readRepositories(graphAnswer)
        compare(owned[0].description, "")
        compare(owned[0].language, "")
        compare(Hub.readRepos([{ full_name: "a/b", html_url: "https://github.com/a/b", stargazers_count: 4 }])[0].stars, 4)
    }

    function test_favoritesImportPinnedUntilChosen() {
        const pinned = Hub.readPinned(graphAnswer)
        const owned = Hub.readRepositories(graphAnswer)
        compare(Hub.favoritesOf(owned, pinned, []).map(entry => entry.name), ["someone/shell"])
        compare(Hub.favoritesOf(owned, [], []).length, 2)
        compare(Hub.favoritesOf(owned, pinned, ["someone/notes", "gone/away"]).map(entry => entry.name), ["someone/notes"])
    }

    function test_choosingStopsAtFive() {
        compare(Hub.toggled(["a/1"], "a/1"), [])
        compare(Hub.toggled(["a/1"], "a/2"), ["a/1", "a/2"])
        const full = ["a/1", "a/2", "a/3", "a/4", "a/5"]
        compare(Hub.toggled(full, "a/6"), full)
    }

    function test_pushesAreNewestFirstWithAMessageOrTheirBranch() {
        const pushes = Hub.readPushes(events)
        compare(pushes.length, 4)
        compare(pushes[0].title, "Fix notes")
        compare(pushes[0].url, "https://github.com/someone/notes/commit/def")
        compare(pushes[1].title, "pushed to main")
        compare(pushes[1].hash, "abc")
    }

    function test_headlinesReplaceTheBranchLine() {
        const pushes = Hub.readPushes(events)
        verify(Hub.headlineQuery(pushes).indexOf("push1: repository(owner: \"someone\", name: \"shell\")") > 0)
        compare(Hub.headlineQuery([]), "")
        const named = Hub.withHeadlines(pushes, { data: { push1: { object: { messageHeadline: "Ship it" } } } })
        compare(named[1].title, "Ship it")
        compare(named[0].title, "Fix notes")
        compare(Hub.withHeadlines(pushes, null)[1].title, "pushed to main")
    }

    function test_theArrowCyclesThreeSlides() {
        compare(Hub.slides, ["history", "favorites", "pushes"])
        compare(Hub.nextIndex(0, 3), 1)
        compare(Hub.nextIndex(2, 3), 0)
        compare(Hub.nextIndex(0, 0), 0)
        compare(Hub.stepIndex(0, 3, -1), 2)
        compare(Hub.stepIndex(2, 3, -1), 1)
    }

    function test_pushesStopAtFifteen() {
        const many = Array.from({ length: 20 }, (unused, index) => ({ type: "PushEvent", repo: { name: "a/b" }, payload: { head: "h" + index }, created_at: "2026-11-01T00:00:00Z" }))
        compare(Hub.readPushes(many).length, Hub.pushLimit)
    }

    function test_loginsFollowGitHubsRules() {
        verify(Hub.isLogin("VADITIM"))
        verify(Hub.isLogin("some-one"))
        verify(!Hub.isLogin(""))
        verify(!Hub.isLogin("-lead"))
        verify(!Hub.isLogin("double--dash"))
        verify(!Hub.isLogin("has space"))
        verify(!Hub.isLogin("a".repeat(40)))
    }

    function test_levelsAndAges() {
        compare(Hub.levelOf(0, 10), 0)
        compare(Hub.levelOf(10, 10), 4)
        compare(Hub.levelOf(1, 10), 1)
        const now = Date.parse("2026-11-17T12:00:00Z")
        compare(Hub.ageOf("2026-11-17T11:30:00Z", now), "30M")
        compare(Hub.ageOf("2026-11-17T09:00:00Z", now), "3H")
        compare(Hub.ageOf("2026-11-15T12:00:00Z", now), "2D")
        compare(Hub.ageOf("not a date", now), "")
    }

    function test_publicActivityFillsTheCalendarFromPushes() {
        const days = Hub.calendarFromPushes(Hub.readPushes(events), 3, Date.parse("2026-11-17T12:00:00Z"))
        compare(days.map(day => day.count), [0, 1, 1])
    }
}
