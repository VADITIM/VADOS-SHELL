import QtQuick
import QtTest
import "../../shell/utils/Boot.js" as Boot

TestCase {
    name: "Boot"

    readonly property string presetPath: "/etc/mkinitcpio.d/linux.preset"
    readonly property string preset: "ALL_kver=\"/boot/vmlinuz-linux\"\n\nPRESETS=('default')\n#PRESETS=('default' 'fallback')\n\ndefault_uki=\"/boot/EFI/Linux/arch-linux.efi\"\ndefault_options=\"--splash /usr/share/systemd/bootctl/splash-arch.bmp\"\n\nfallback_uki=\"/boot/EFI/Linux/arch-linux-fallback.efi\"\n#fallback_options=\"-S autodetect\"\n"
    readonly property string mkinitcpio: "MODULES=()\n#HOOKS=(base udev)\nHOOKS=(base udev autodetect microcode modconf kms keyboard block filesystems fsck)\n"
    readonly property string cmdline: "root=PARTUUID=abc rw rootfstype=ext4\n"

    function current(overrides) {
        const presets = {}
        presets[presetPath] = preset
        return Object.assign({ hasMkinitcpio: true, hasPlymouth: true, hasRenderer: true, presets: presets, mkinitcpio: mkinitcpio, cmdline: cmdline, plymouth: "" }, overrides || {})
    }

    function applied(state, files) {
        const next = JSON.parse(JSON.stringify(state))
        for (const path of Object.keys(files)) {
            if (path === Boot.mkinitcpioPath)
                next.mkinitcpio = files[path]
            else if (path === Boot.cmdlinePath)
                next.cmdline = files[path]
            else if (path === Boot.plymouthPath)
                next.plymouth = files[path]
            else
                next.presets[path] = files[path]
        }
        return next
    }

    function test_onlyActivePresetsWithImagesCount() {
        compare(Boot.imagesOf(current().presets), ["/boot/EFI/Linux/arch-linux.efi"])
        verify(Boot.canSplash(current()))
        verify(!Boot.canSplash(current({ presets: { "/etc/mkinitcpio.d/linux.preset": "PRESETS=('default')\ndefault_image=\"/boot/initramfs-linux.img\"\n" } })))
        verify(!Boot.canSplash(current({ hasMkinitcpio: false })))
    }

    function test_plymouthNeedsItsHookAndTheCommandLine() {
        verify(Boot.canPlymouth(current()))
        verify(!Boot.canPlymouth(current({ hasPlymouth: false })))
        verify(!Boot.canPlymouth(current({ cmdline: null })))
    }

    function test_splashSwapsOnlyTheSplashOption() {
        const planned = Boot.plan(current(), Boot.emptyRecord(), { splash: true, plymouth: false })
        const text = planned.files[presetPath]
        verify(text.indexOf("default_options=\"--splash " + Boot.splashPath + "\"") >= 0)
        verify(text.indexOf("#fallback_options=\"-S autodetect\"") >= 0)
        compare(planned.record.splash[presetPath + ":default"], "/usr/share/systemd/bootctl/splash-arch.bmp")
        verify(Boot.isSplashOn(applied(current(), planned.files).presets))
    }

    function test_splashOffRestoresTheOriginalExactly() {
        const on = Boot.plan(current(), Boot.emptyRecord(), { splash: true, plymouth: false })
        const off = Boot.plan(applied(current(), on.files), on.record, { splash: false, plymouth: false })
        compare(off.files[presetPath], preset)
        compare(Object.keys(off.record.splash).length, 0)
    }

    function test_splashKeepsOtherOptions() {
        compare(Boot.withSplashIn("-S autodetect --splash /old.bmp", "/new.bmp"), "--splash /new.bmp -S autodetect")
        compare(Boot.withSplashIn("-S autodetect --splash=/old.bmp", ""), "-S autodetect")
    }

    function test_splashAddsTheMissingOptionsLineUnderTheImage() {
        const bare = "PRESETS=('default')\ndefault_uki=\"/boot/linux.efi\"\n"
        compare(Boot.withSplash(bare, "default", "/new.bmp"), "PRESETS=('default')\ndefault_uki=\"/boot/linux.efi\"\ndefault_options=\"--splash /new.bmp\"\n")
        compare(Boot.withSplash(bare, "default", ""), bare)
    }

    function test_plymouthGoesAfterKms() {
        compare(Boot.hooksOf(Boot.withHook(mkinitcpio, true)), ["base", "udev", "autodetect", "microcode", "modconf", "kms", "plymouth", "keyboard", "block", "filesystems", "fsck"])
        compare(Boot.hooksOf(Boot.withHook("HOOKS=(base systemd autodetect)\n", true)), ["base", "systemd", "plymouth", "autodetect"])
        compare(Boot.withHook(Boot.withHook(mkinitcpio, true), true), Boot.withHook(mkinitcpio, true))
        verify(Boot.withHook(mkinitcpio, true).indexOf("#HOOKS=(base udev)") >= 0)
    }

    function test_plymouthRoundTripLeavesEveryFileAsItWas() {
        const on = Boot.plan(current(), Boot.emptyRecord(), { splash: false, plymouth: true })
        const shown = applied(current(), on.files)
        verify(Boot.isPlymouthOn(shown))
        compare(Boot.wordsOf(shown.cmdline).slice(-2), ["quiet", "splash"])
        compare(Boot.themeOf(shown.plymouth), "vados")
        const off = Boot.plan(shown, on.record, { splash: false, plymouth: false })
        const back = applied(shown, off.files)
        compare(back.mkinitcpio, mkinitcpio)
        compare(back.cmdline, cmdline)
        compare(Boot.themeOf(back.plymouth), "")
        verify(!Boot.isPlymouthOn(back))
    }

    function test_plymouthOffKeepsWhatTheUserHadBefore() {
        const before = current({ mkinitcpio: Boot.withHook(mkinitcpio, true), cmdline: "root=abc quiet\n", plymouth: "[Daemon]\nTheme=spinner\n" })
        const on = Boot.plan(before, Boot.emptyRecord(), { splash: false, plymouth: true })
        compare(on.record.addedHook, false)
        compare(on.record.addedWords, ["splash"])
        compare(on.record.theme, "spinner")
        const shown = applied(before, on.files)
        const back = applied(shown, Boot.plan(shown, on.record, { splash: false, plymouth: false }).files)
        compare(back.mkinitcpio, before.mkinitcpio)
        compare(back.cmdline, "root=abc quiet\n")
        compare(Boot.themeOf(back.plymouth), "spinner")
    }

    function test_nothingToDoWritesNothing() {
        const planned = Boot.plan(current(), Boot.emptyRecord(), { splash: false, plymouth: false })
        compare(Object.keys(planned.files).length, 0)
    }

    function test_themeIsWrittenUnderDaemon() {
        compare(Boot.withTheme("", "vados"), "[Daemon]\nTheme=vados\n")
        compare(Boot.withTheme("[Daemon]\n#Theme=fade-in\nShowDelay=0\n", "vados"), "[Daemon]\nTheme=vados\n#Theme=fade-in\nShowDelay=0\n")
        compare(Boot.themeOf(Boot.withTheme("[Daemon]\nTheme=vados\n", "")), "")
    }
}
