import re

GROUP_TYPES = {"SequentialAnimation", "ParallelAnimation", "Transition", "Behavior"}
HELD_LINE = "paused: Motion.isHeld && running"

OPENER = re.compile(
    r"^(?P<indent>\s*)(?:(?:readonly\s+)?property\s+\S+\s+\w+:\s*|[a-z][\w.]*:\s*)?(?P<type>[A-Z]\w*)(?:\s+on\s+[\w.]+)?\s*\{(?P<rest>.*)$"
)


def is_animation(type_name):
    return type_name.endswith("Animation") and type_name != "PauseAnimation"


def braces_in(text):
    cleaned = re.sub(r'"(?:\\.|[^"\\])*"', '""', text)
    return cleaned.count("{"), cleaned.count("}")


def declarations(lines):
    stack = []
    found = []
    for number, line in enumerate(lines):
        match = OPENER.match(line)
        if match:
            type_name = match.group("type")
            rest = match.group("rest")
            opened, closed = braces_in(rest)
            parent = stack[-1] if stack else ""
            if is_animation(type_name) and parent not in GROUP_TYPES:
                found.append({
                    "line": number,
                    "indent": match.group("indent"),
                    "is_single": closed > opened,
                    "is_held": HELD_LINE in held_scope(lines, number, rest, closed > opened),
                })
            if closed > opened:
                continue
            stack.append(type_name)
            for _ in range(opened - closed):
                stack.append("block")
            continue
        opened, closed = braces_in(line)
        for _ in range(opened):
            stack.append("block")
        for _ in range(closed):
            if stack:
                stack.pop()
    return found


def held_scope(lines, number, rest, is_single):
    if is_single:
        return rest
    depth = 1
    scope = [rest]
    for line in lines[number + 1:]:
        opened, closed = braces_in(line)
        if depth == 1:
            scope.append(line)
        depth += opened - closed
        if depth <= 0:
            break
    return "\n".join(scope)


def hold(text):
    lines = text.split("\n")
    for declaration in sorted(declarations(lines), key=lambda item: -item["line"]):
        if declaration["is_held"]:
            continue
        number = declaration["line"]
        indent = declaration["indent"]
        if declaration["is_single"]:
            head, _, tail = lines[number].partition("{")
            body = tail.rsplit("}", 1)[0].strip()
            replacement = [head.rstrip() + " {", indent + "    " + HELD_LINE]
            if body:
                replacement.append(indent + "    " + body)
            replacement.append(indent + "}")
            lines[number:number + 1] = replacement
        else:
            lines.insert(number + 1, indent + "    " + HELD_LINE)
    return "\n".join(lines)
