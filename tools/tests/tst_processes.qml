import QtQuick
import QtTest
import "../../shell/utils/Processes.js" as ProcessTable

TestCase {
    name: "Processes"

    function sampleOf(time, ticks, processes) {
        return { time: time, ticks: ticks, hertz: 100, processes: processes }
    }

    ListModel {
        id: model
    }

    function test_measuresSharesAndRates() {
        const first = sampleOf(0, 1000, [[1, "firefox", "/usr/bin/firefox", 100, 500, 0], [2, "firefox", "/usr/bin/firefox", 50, 300, -1]])
        const second = sampleOf(2, 1400, [[1, "firefox", "/usr/bin/firefox", 200, 600, 4000], [2, "firefox", "/usr/bin/firefox", 70, 300, -1], [3, "kitty", "/usr/bin/kitty", 9, 100, 0]])
        compare(ProcessTable.measure(null, first), null, "the first sample has nothing to compare against")
        const rows = ProcessTable.measure(ProcessTable.remember(first), second)
        compare(rows.length, 3)
        compare(rows[0].cpu, 0.25)
        compare(rows[0].disk, 2000)
        compare(rows[1].disk, -1, "an unreadable io file stays unknown")
        compare(rows[2].cpu, 0, "a process born between samples has no share yet")
        compare(rows[0].cpuTotal, 2)
    }

    function test_groupsByNameAndKeepsUnknownApart() {
        const groups = ProcessTable.group([
            { pid: 1, name: "firefox", path: "/usr/bin/firefox", cpu: 0.1, memory: 10, disk: -1, network: -1 },
            { pid: 2, name: "firefox", path: "", cpu: 0.2, memory: 20, disk: 30, network: -1 },
            { pid: 3, name: "kitty", path: "/usr/bin/kitty", cpu: 0, memory: 5, disk: -1, network: -1 }
        ])
        compare(groups.length, 2)
        compare(groups[0].pids, [1, 2])
        fuzzyCompare(groups[0].cpu, 0.3, 1e-9)
        compare(groups[0].memory, 30)
        compare(groups[0].disk, 30)
        compare(groups[1].disk, -1)
        compare(groups[0].path, "/usr/bin/firefox")
    }

    function test_sortsAndFlipsDirection() {
        const rows = [{ name: "b", cpu: 0.2 }, { name: "a", cpu: 0.5 }, { name: "C", cpu: 0.2 }]
        compare(ProcessTable.sorted(rows, { key: "cpu", isDescending: true }).map(row => row.name), ["a", "b", "C"])
        compare(ProcessTable.sorted(rows, { key: "name", isDescending: false }).map(row => row.name), ["a", "b", "C"])
        compare(ProcessTable.nextSort({ key: "cpu", isDescending: true }, "cpu"), { key: "cpu", isDescending: false })
        compare(ProcessTable.nextSort({ key: "cpu", isDescending: true }, "name"), { key: "name", isDescending: false })
        compare(ProcessTable.nextSort({ key: "name", isDescending: false }, "memory"), { key: "memory", isDescending: true })
    }

    function test_historyKeepsTimeOfFinishedProcesses() {
        const row = (pid, cpuTotal, diskTotal, memory) => ({ pid: pid, name: "code", path: "/usr/bin/code", cpuTotal: cpuTotal, diskTotal: diskTotal, memory: memory })
        let history = ProcessTable.record({}, [row(1, 10, 100, 50), row(2, 5, 0, 70)])
        compare(ProcessTable.historyRows(history)[0].cpuTime, 15)
        compare(ProcessTable.historyRows(history)[0].memory, 120)
        history = ProcessTable.record(history, [row(1, 12, 150, 40)])
        const later = ProcessTable.historyRows(history)[0]
        compare(later.cpuTime, 17, "pid 2 ended: its 5 s stay")
        compare(later.disk, 150)
        compare(later.memory, 120, "memory is the peak")
        history = ProcessTable.record(history, [row(1, 1, 0, 10)])
        compare(ProcessTable.historyRows(history)[0].cpuTime, 18, "a reused pid closes the old process first")
        history = ProcessTable.record(history, [])
        compare(ProcessTable.historyRows(history)[0].cpuTime, 18, "an app with nothing running keeps its history")
    }

    function test_syncKeepsRowsAndReorders() {
        const rowOf = (key, cpu) => ({ key: key, name: key, pids: [1], cpu: cpu, memory: 1, disk: 0, network: -1 })
        ProcessTable.sync(model, [rowOf("a", 0.1), rowOf("b", 0.2), rowOf("c", 0.3)])
        compare(model.count, 3)
        ProcessTable.sync(model, [rowOf("c", 0.4), rowOf("a", 0.1)])
        compare(model.count, 2)
        compare(model.get(0).key, "c")
        compare(model.get(0).cpu, 0.4)
        compare(model.get(1).key, "a")
        ProcessTable.sync(model, [rowOf("d", 0), rowOf("c", 0.4), rowOf("a", 0.1)])
        compare([0, 1, 2].map(index => model.get(index).key), ["d", "c", "a"])
    }

    function test_formatsCells() {
        compare(ProcessTable.percent(0.034), "3.4%")
        compare(ProcessTable.percent(0.5), "50%")
        compare(ProcessTable.bytes(512), "512 B")
        compare(ProcessTable.bytes(1536), "1.5 KB")
        compare(ProcessTable.rate(-1), "--")
        compare(ProcessTable.duration(3725), "1:02:05")
        compare(ProcessTable.cell({ count: 0, disk: 2048 }, "disk"), "2.0 KB")
        compare(ProcessTable.cell({ count: 2, disk: 2048 }, "disk"), "2.0 KB/s")
        compare(ProcessTable.directory("/usr/bin/kitty"), "/usr/bin")
    }

    function test_stepsSelectionWithinBounds() {
        const rows = [{ key: "a" }, { key: "b" }, { key: "c" }]
        compare(ProcessTable.step(rows, "", 1), "a")
        compare(ProcessTable.step(rows, "", -1), "c")
        compare(ProcessTable.step(rows, "c", 1), "c")
        compare(ProcessTable.step(rows, "b", -1), "a")
        compare(ProcessTable.step([], "a", 1), "")
    }
}
