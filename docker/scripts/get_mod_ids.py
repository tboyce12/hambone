import os
import sys
import yaml


def get_mod_ids(yaml_file):
    with open(yaml_file, "r") as file:
        data = yaml.safe_load(file)

    mods = [
        mod for mod in data["mod"] + data["serverMod"] + data["key"]
        if "id" in mod
    ]
    output = ""
    for mod in mods:
        output += f"{mod['id']} {mod['name']}\n"
    return output


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(
            f"Usage: python {os.path.basename(__file__)} YAML_FILE",
            file=sys.stderr
        )
        sys.exit(1)

    yaml_file = sys.argv[1]
    output = get_mod_ids(yaml_file)
    print(output, end="")
