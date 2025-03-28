import os
import sys
import yaml


def generate_par_file(yaml_file, mods_dir):
    with open(yaml_file, "r") as file:
        data = yaml.safe_load(file)

    mods = "".join([
        f'{os.path.join(mods_dir, mod["name"])};'.lower()
        for mod in data["mod"]
    ])
    server_mods = "".join([
        f'{os.path.join(mods_dir, mod["name"])};'.lower()
        for mod in data["serverMod"]
    ])
    output = (
        'class Arg {\n'
        f'    serverMod="-serverMod={server_mods}";\n'
        f'    mod="-mod={mods}";\n'
        '};\n'
    )
    return output


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print(
            f"Usage: python {os.path.basename(__file__)} YAML_FILE MODS_DIR",
            file=sys.stderr
        )
        sys.exit(1)

    yaml_file, mods_dir = sys.argv[1:]
    output = generate_par_file(yaml_file, mods_dir)
    print(output, end="")
