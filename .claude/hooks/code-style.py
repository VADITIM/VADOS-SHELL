import importlib.util
import os
import sys

script = os.path.join(os.path.expanduser("~"), "source", "VADOS-APPLICATION-SYSTEMS", "hooks", "enforce-code-style.py")
if not os.path.isfile(script):
    sys.exit(0)
specification = importlib.util.spec_from_file_location("enforce_code_style", script)
module = importlib.util.module_from_spec(specification)
specification.loader.exec_module(module)
module.SLASH_LANGUAGES.add("qml")
module.SCRIPT_LANGUAGES.add("qml")
module.main()
