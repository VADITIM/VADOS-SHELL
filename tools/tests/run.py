import os
import shutil
import sys
import tempfile
import time

TESTS = os.path.dirname(os.path.abspath(__file__))
PROJECT = os.path.dirname(os.path.dirname(TESTS))
sys.path.insert(0, os.path.join(PROJECT, "tools", "preview"))
sys.dont_write_bytecode = True

import play


def disk_setup():
    from PySide6.QtCore import QObject, Slot
    from PySide6.QtQml import qmlRegisterSingletonInstance

    class Disk(QObject):
        @Slot(str, result=str)
        def read(self, path):
            try:
                with open(path, encoding="utf-8") as handle:
                    return handle.read()
            except OSError:
                return ""

        @Slot(str, str)
        def write(self, path, text):
            with open(path, "w", encoding="utf-8", newline="\n") as handle:
                handle.write(text)

    class Clock(QObject):
        @Slot(result=float)
        def now(self):
            return time.perf_counter() * 1000

    class Setup(QObject):
        def __init__(self):
            super().__init__()
            self.disk = Disk()
            self.clock = Clock()
            qmlRegisterSingletonInstance(Disk, "VadosTest", 1, 0, "Disk", self.disk)
            qmlRegisterSingletonInstance(Clock, "VadosTest", 1, 0, "Clock", self.clock)

    return Setup


def fake(name):
    return os.path.join(TESTS, "fakes", name), None


def build(root):
    play.BUILD = os.path.join(root, "build")
    play.build()
    home = os.path.join(root, "home")
    os.makedirs(os.path.join(home, ".cache", "vados"), exist_ok=True)
    with open(os.path.join(TESTS, "fakes", "Quickshell.qml"), encoding="utf-8") as handle:
        shell = handle.read().replace("HOME_DIRECTORY", home.replace(os.sep, "/"))
    play.write_module("Quickshell", [fake("Singleton.qml"), fake("Scope.qml"), ("Quickshell.qml", shell)])
    play.write_module("Quickshell.Io", [fake("FileView.qml"), fake("Process.qml")])
    services = os.path.join(play.BUILD, "qs", "services")
    for name in ("StateFile.qml", "Confinement.qml", "Supervisor.qml", "Supervision.qml"):
        shutil.copy(os.path.join(play.SHELL, "services", name), services)
    with open(os.path.join(services, "qmldir"), "a", encoding="utf-8", newline="\n") as handle:
        handle.write("StateFile 1.0 StateFile.qml\nSupervisor 1.0 Supervisor.qml\n")


def main():
    root = tempfile.mkdtemp(prefix="vados-tests-")
    try:
        build(root)
        os.environ["QT_QPA_PLATFORM"] = "offscreen"
        from PySide6.QtQuickTest import QUICK_TEST_MAIN_WITH_SETUP
        arguments = [sys.argv[0], "-import", play.BUILD, "-input", TESTS] + sys.argv[1:]
        return QUICK_TEST_MAIN_WITH_SETUP("vados", disk_setup(), arguments)
    finally:
        shutil.rmtree(root, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
