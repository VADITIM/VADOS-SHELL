import QtQuick
import QtTest
import "../../shell/utils/Controls.js" as Controls

TestCase {
    name: "Controls"

    function test_profilesAreReadInOrderWithTheActiveOne() {
        const text = "  performance:\n      CpuDriver:  amd_pstate\n\n* balanced:\n      CpuDriver:  amd_pstate\n\n  power-saver:\n      Degraded:  no\n"
        const read = Controls.parseProfiles(text)
        compare(read.keys, ["performance", "balanced", "power-saver"])
        compare(read.active, "balanced")
    }

    function test_noDaemonMeansNoProfiles() {
        compare(Controls.parseProfiles("").keys, [])
        compare(Controls.parseProfiles("").active, "")
    }

    function test_brightnessReadsTheBacklight() {
        const read = Controls.parseBrightness("intel_backlight,backlight,4800,50%,9600\n")
        compare(read.device, "intel_backlight")
        compare(read.level, 0.5)
        compare(Controls.parseBrightness("tpacpi::kbd_backlight,leds,0,0%,2\n"), null, "only a backlight counts")
        compare(Controls.parseBrightness(""), null)
    }

    function test_brightnessNeverReachesBlack() {
        compare(Controls.brightnessArgument(0), "1%")
        compare(Controls.brightnessArgument(0.456), "46%")
        compare(Controls.brightnessArgument(3), "100%")
    }

    function test_fontFamiliesAreUniqueSortedAndWithoutHiddenOnes() {
        const text = "Noto Sans,Noto Sans Light\nDejaVu Sans\nNoto Sans\n.Hidden UI\nFoo\\-Bar\n\n"
        compare(Controls.parseFamilies(text), ["DejaVu Sans", "Foo-Bar", "Noto Sans"])
        compare(Controls.parseFamilies(""), [])
    }

    function test_labelsFallBack() {
        compare(Controls.deviceLabel("", "Nick", "alsa.node"), "Nick")
        compare(Controls.deviceLabel("", "", ""), "UNKNOWN")
        compare(Controls.streamLabel({ "application.name": "Spotify" }, "x", "y"), "Spotify")
        compare(Controls.streamLabel(null, "", "node"), "node")
    }

    function test_sectionsSkipEmptyGroups() {
        const rows = Controls.sectionRows([{ key: "1" }], [], [{ key: "2" }, { key: "3" }])
        compare(rows.map(row => row.key), ["header-output", "1", "header-stream", "2", "3"])
        compare(rows[1].kind, "output")
        compare(rows[3].kind, "stream")
    }

    function test_iwdStationAndNetworksAreRead() {
        const escape = String.fromCharCode(27)
        const list = "  Name                  State            Scanning\n" + "-".repeat(20) + "\n  wlan0                 connected\n"
        compare(Controls.parseStationName(list), "wlan0")
        compare(Controls.parseStationName(""), "")
        const show = "            State                 connected   \n            Connected network     Vodafone-AF28    \n"
        compare(Controls.parseStationShow(show).ssid, "Vodafone-AF28")
        compare(Controls.parseStationShow("            State                 disconnected\n").isConnected, false)
        const table = escape + "[0m  " + escape + "[1;90m> " + escape + "[0m  Vodafone-AF28                     psk                 ****    \n      Cafe Free                         open                **      \n"
        const networks = Controls.parseIwdNetworks(table)
        compare(networks.length, 2)
        compare(networks[0].ssid, "Vodafone-AF28")
        verify(networks[0].isActive)
        compare(networks[0].strength, 1)
        compare(networks[1].isSecured, false)
        compare(networks[1].ssid, "Cafe Free")
        compare(networks[0].isEnterprise, false)
        compare(Controls.parseIwdNetworks("      Campus                            8021x               ****    \n")[0].isEnterprise, true)
        compare(Controls.securityOf({ isSecured: true, isEnterprise: true }), "enterprise")
        compare(Controls.securityOf({ isSecured: true, isEnterprise: false }), "secured")
        compare(Controls.securityOf({ isSecured: false }), "open")
        compare(Controls.securityOf(undefined), "secured", "a hidden network is asked for a password")
        compare(Controls.parsePowered("         *  Powered               off  \n"), false)
    }

    function test_joinLinesAreRead() {
        compare(Controls.parseJoinLine("ask passphrase").ask, "passphrase")
        compare(Controls.parseJoinLine("ask identity\n").ask, "identity")
        compare(Controls.parseJoinLine("connected").result, "connected")
        compare(Controls.parseJoinLine("failed wrong").result, "wrong")
        compare(Controls.parseJoinLine("failed").result, "error")
        compare(Controls.parseJoinLine("cancel").kind, "cancel")
        compare(Controls.parseJoinLine("noise"), null)
        compare(Controls.joinMessage("wrong"), "WRONG PASSWORD")
        compare(Controls.joinMessage("admin"), "NO POLKIT AGENT RUNNING")
        compare(Controls.joinMessage("connected"), "")
    }

    function test_knownNetworksAreRead() {
        const escape = String.fromCharCode(27)
        const table = "                                 Known Networks" + escape + "[1;90m  " + escape + "[0m\n" + escape + "[0m" + escape + "[1;90m  Name                              Security     Hidden     Last connected     \n" + escape + "[0m  AP410                             psk                     Nov 14, 11:07 AM     \n  Cafe Free Wifi                    open         *          Nov 13,  6:44 AM     \n"
        compare(Controls.parseIwdKnown(table), ["AP410", "Cafe Free Wifi"])
        compare(Controls.parseNmcliKnown("Home\\:5G:802-11-wireless\nWired:802-3-ethernet\nlo:loopback\n"), ["Home:5G"])
    }

    function test_chargeLimitOnlyOnAcer() {
        compare(Controls.parseChargeLimit("LENOVO\n/sys/class/power_supply/BAT0/charge_control_end_threshold w 80\n"), null, "another vendor never gets the limit")
        compare(Controls.parseChargeLimit("Acer\n"), null, "an Acer without the driver has no limit")
        compare(Controls.parseChargeLimit(""), null)
    }

    function test_chargeLimitReadsTheHealthMode() {
        const read = Controls.parseChargeLimit("Acer\n/sys/bus/wmi/drivers/acer-wmi-battery/health_mode w 1\n")
        compare(read.kind, "health")
        verify(read.isWritable)
        verify(read.isLimited)
        compare(read.cap, 0.8)
        verify(!Controls.parseChargeLimit("Acer\n/sys/bus/wmi/drivers/acer-wmi-battery/health_mode r 0\n").isLimited)
        compare(Controls.chargeLimitValue("health", true), "1")
        compare(Controls.chargeLimitValue("health", false), "0")
    }

    function test_chargeLimitReadsTheThreshold() {
        const read = Controls.parseChargeLimit("Acer\n/sys/class/power_supply/BAT1/charge_control_end_threshold r 100\n")
        compare(read.kind, "threshold")
        verify(!read.isWritable)
        verify(!read.isLimited)
        compare(read.cap, 1)
        compare(Controls.chargeLimitValue("threshold", true), "80")
        compare(Controls.chargeLimitValue("threshold", false), "100")
    }
}
