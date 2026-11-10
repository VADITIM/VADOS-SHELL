import os
import sys
import xml.etree.ElementTree as ElementTree

here = os.path.dirname(os.path.abspath(__file__))
source = os.path.join(here, "source")
target = os.path.join(here, "..", "..", "shell", "utils", "IconPaths.js")
canvas = 24
namespace = "{http://www.w3.org/2000/svg}"
skipped = {"defs", "clipPath", "title", "desc", "metadata"}
counts = {"M": 2, "L": 2, "H": 1, "V": 1, "C": 6, "S": 4, "Q": 4, "T": 2, "A": 7, "Z": 0}
commands = set("MLHVCSQTAZmlhvcsqtaz")
number_characters = set("0123456789.-+eE")


def tokens_of(path):
    tokens = []
    index = 0
    while index < len(path):
        character = path[index]
        if character in commands:
            tokens.append(character)
            index += 1
        elif character in number_characters:
            start = index
            index += 1
            has_dot = character == "."
            while index < len(path):
                character = path[index]
                if character.isdigit():
                    index += 1
                elif character == "." and not has_dot:
                    has_dot = True
                    index += 1
                elif character in "eE":
                    index += 1
                    if index < len(path) and path[index] in "+-":
                        index += 1
                else:
                    break
            tokens.append(float(path[start:index]))
        else:
            index += 1
    return tokens


def written(value):
    text = ("%.2f" % value).rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def transformed(path, offset_x, offset_y, scale):
    tokens = tokens_of(path)
    output = []
    index = 0
    command = None
    while index < len(tokens):
        if isinstance(tokens[index], str):
            command = tokens[index]
            index += 1
            output.append(command)
            if command in "Zz":
                continue
        elif command in "Mm":
            command = "L" if command == "M" else "l"
            output.append(command)
        size = counts[command.upper()]
        values = tokens[index:index + size]
        index += size
        is_absolute = command.isupper()
        upper = command.upper()
        result = []
        for position, value in enumerate(values):
            if upper == "A" and position in (2, 3, 4):
                result.append(written(value))
                continue
            if upper == "A" and position in (0, 1):
                result.append(written(value * scale))
                continue
            if upper == "H":
                result.append(written((value + offset_x) * scale if is_absolute else value * scale))
                continue
            if upper == "V":
                result.append(written((value + offset_y) * scale if is_absolute else value * scale))
                continue
            offset = offset_x if position % 2 == 0 else offset_y
            result.append(written((value + offset) * scale if is_absolute else value * scale))
        output.append(" ".join(result))
    return " ".join(part for part in output if part)


def circle_path(element):
    center_x = float(element.get("cx", 0))
    center_y = float(element.get("cy", 0))
    radius = float(element.get("r", 0))
    return "M%s %s A%s %s 0 1 0 %s %s A%s %s 0 1 0 %s %s Z" % (
        center_x - radius, center_y, radius, radius, center_x + radius, center_y,
        radius, radius, center_x - radius, center_y)


def translation_of(element):
    transform = element.get("transform", "")
    if not transform.startswith("translate("):
        return 0.0, 0.0
    numbers = transform[len("translate("):transform.index(")")].replace(",", " ").split()
    return float(numbers[0]), float(numbers[1]) if len(numbers) > 1 else 0.0


def paint_of(chain, attribute, fallback):
    for element in reversed(chain):
        value = element.get(attribute)
        if value is not None:
            return value
    return fallback


def walk(element, chain, found):
    name = element.tag.replace(namespace, "")
    if name in skipped:
        return
    chain = chain + [element]
    if name in ("path", "circle"):
        path = element.get("d") if name == "path" else circle_path(element)
        offset_x = sum(translation_of(item)[0] for item in chain)
        offset_y = sum(translation_of(item)[1] for item in chain)
        is_stroked = paint_of(chain, "stroke", "none") != "none"
        is_filled = paint_of(chain, "fill", "black") != "none"
        found.append((path, offset_x, offset_y, is_stroked, is_filled))
    for child in element:
        walk(child, chain, found)


def icon_of(file):
    root = ElementTree.parse(file).getroot()
    view = [float(value) for value in root.get("viewBox").split()]
    scale = canvas / view[2]
    found = []
    walk(root, [], found)
    stroke = []
    fill = []
    for path, offset_x, offset_y, is_stroked, is_filled in found:
        drawn = transformed(path, offset_x - view[0], offset_y - view[1], scale)
        if is_stroked:
            stroke.append(drawn)
        elif is_filled:
            fill.append(drawn)
    return " ".join(stroke), " ".join(fill)


def main():
    names = sorted(name[:-4] for name in os.listdir(source) if name.endswith(".svg"))
    lines = [".pragma library", "", "const paths = {"]
    for position, name in enumerate(names):
        stroke, fill = icon_of(os.path.join(source, name + ".svg"))
        ending = "," if position < len(names) - 1 else ""
        lines.append('    "%s": { stroke: "%s", fill: "%s" }%s' % (name, stroke, fill, ending))
    lines.append("}")
    with open(target, "w", encoding="utf-8", newline="\n") as output:
        output.write("\n".join(lines) + "\n")
    print("wrote", len(names), "icons to", os.path.normpath(target))


if __name__ == "__main__":
    sys.exit(main())
