import os
import sys
import yaml


def generate_steamcmd_script(
        yaml_file, install_dir, server_id, game_id, username, password
):
    with open(yaml_file, "r") as file:
        data = yaml.safe_load(file)

    output = (
        f"force_install_dir {install_dir}\n"
        f"login {username} {password}\n"
        f"app_update {server_id} -beta creatordlc validate\n"
    )
    mod_ids = [
        mod["id"] for mod in data["mod"] + data["serverMod"] + data["key"]
        if "id" in mod
    ]
    for mod_id in mod_ids:
        output += f"workshop_download_item {game_id} {mod_id}\n"

    output += "quit\n"
    return output


if __name__ == "__main__":
    if len(sys.argv) != 7:
        print(
            f"Usage: python {os.path.basename(__file__)} "
            "YAML_FILE INSTALL_DIR SERVER_ID GAME_ID USERNAME PASSWORD",
            file=sys.stderr
        )
        sys.exit(1)

    yaml_file, install_dir, server_id, game_id, username, password = \
        sys.argv[1:]
    output = generate_steamcmd_script(
        yaml_file, install_dir, server_id, game_id, username, password
    )
    print(output, end="")
