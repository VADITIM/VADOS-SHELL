import QtQuick
import QtTest
import "../../shell/utils/Family.js" as Family

TestCase {
    name: "Family"

    function test_everyAppHasWhatAPageNeeds() {
        verify(Family.apps.length > 0)
        const keys = {}
        for (const app of Family.apps) {
            verify(!keys[app.key], "keys are unique: " + app.key)
            keys[app.key] = true
            verify(app.label.length > 0 && app.role.length > 0 && app.entry.length > 0)
            compare(Family.releasesLink(app), "https://github.com/" + app.repository + "/releases")
        }
    }

    function test_installedIsReadFromDesktopEntryIdsWithOrWithoutTheSuffix() {
        const files = Family.byKey("files")
        verify(Family.isInstalled(files, ["firefox", "vados-files"]))
        verify(Family.isInstalled(files, ["vados-files.desktop"]))
        verify(!Family.isInstalled(files, ["vados-gallery"]))
    }

    function test_aRowIsDefaultOnlyWhenItsLeadTypeOpensWithIt() {
        const rows = Family.resolve(["vados-files", "vados-gallery"], { "inode/directory": "vados-files.desktop", "image/jpeg": "org.gnome.Loupe.desktop" })
        const files = rows.find(row => row.key === "files")
        const gallery = rows.find(row => row.key === "gallery")
        const notes = rows.find(row => row.key === "notes")
        verify(files.isInstalled && files.canBeDefault && files.isDefault)
        verify(gallery.isInstalled && gallery.canBeDefault && !gallery.isDefault)
        verify(!notes.isInstalled && !notes.canBeDefault && !notes.isDefault, "a missing app is never the default")
        compare(Family.statusOf(files), "DEFAULT APP")
        compare(Family.statusOf(gallery), "INSTALLED")
        compare(Family.statusOf(notes), "NOT INSTALLED")
    }

    function test_anAppWithoutFileTypesCannotBecomeTheDefault() {
        const terminal = Family.byKey("terminal")
        compare(Family.defaultCommand(terminal), [])
        const row = Family.resolve(["vados-terminal"], {}).find(candidate => candidate.key === "terminal")
        verify(row.isInstalled && !row.canBeDefault)
    }

    function test_theDefaultCommandNamesTheDesktopFileAndEveryType() {
        const files = Family.byKey("files")
        compare(Family.defaultCommand(files), ["xdg-mime", "default", "vados-files.desktop", "inode/directory"])
        const gallery = Family.byKey("gallery")
        compare(Family.defaultCommand(gallery).length, 3 + gallery.mimes.length)
    }

    function test_theQueryAsksOneLeadTypePerAppAndItsAnswerIsRead() {
        const command = Family.queryCommand()
        compare(command.slice(0, 2), ["sh", "-c"])
        verify(command.indexOf("inode/directory") > 3)
        verify(command.indexOf("image/jpeg") > 3)
        verify(command.indexOf("image/png") < 0, "only the lead type is asked")
        const read = Family.parseDefaults("inode/directory=vados-files.desktop\nimage/jpeg=\n\nnoise\n")
        compare(read["inode/directory"], "vados-files.desktop")
        compare(read["image/jpeg"], "")
        compare(Object.keys(read).length, 2)
    }
}
