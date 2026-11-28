#!/bin/bash
set -e

while getopts "f" opt; do
    case $opt in
        f)
            fast_mode=true
            ;;
        *)
            echo "Invalid option"
            ;;
    esac
done

# Variables
dir_workshop=/data/steamapps/workshop/content/107410
id_game=107410
id_server=233780

# Activate python venv
source ~/.venv/bin/activate

# Run steamcmd
echo "hambone: Running Steamcmd..."
if [ -z "$fast_mode" ] || [ ! -f /data/arma3server_x64 ]; then
    python generate_steamcmd_script.py         \
           /userdata/server/mods.yaml /data    \
           $id_server $id_game                 \
           "$STEAM_USERNAME" "$STEAM_PASSWORD" \
           > /home/server/steamcmd.txt
    /usr/bin/steamcmd +runscript /home/server/steamcmd.txt
fi

# Gather mods
echo "hambone: Gathering mods..."
rm -rf /data/mods
mkdir -p /data/mods
python get_mod_ids.py /userdata/server/mods.yaml | \
    while read id name; do
        ln -s $dir_workshop/"$id" /data/mods/"$name"
    done
python get_mod_paths.py /userdata/server/mods.yaml | \
    while read path name; do
        cp -r /userdata/mods/"$path" /data/mods/"$name"
    done

# Gather keys
echo "hambone: Gathering keys..."
if [ ! -d /data/keys-vanilla ]; then
    cp -r /data/keys /data/keys-vanilla
fi
rm -rf /data/keys
cp -r /data/keys-vanilla /data/keys
python get_mod_ids.py /userdata/server/mods.yaml | \
    while read id name; do
        find -L /data/mods/"$name" -iname "*.bikey" -exec \
             cp {} /data/keys/ \;
    done
python get_mod_paths.py /userdata/server/mods.yaml | \
    while read path name; do
        find -L /data/mods/"$name" -iname "*.bikey" -exec \
             cp {} /data/keys/ \;
    done

# Lowercase files
echo "hambone: Lowercasing files..."
./lowercase-file-paths.bash /data/mods
./lowercase-file-paths.bash /data/keys

# Gather server files
echo "hambone: Gathering server files..."
python generate_par_file.py /userdata/server/mods.yaml mods > /data/arma.par
cp /userdata/server/server.cfg /data/server.cfg
cp /userdata/server/arma3-server.sh /data/arma3-server.sh
if [ -d /userdata/profiles ] && [ "$(ls -A /userdata/profiles)" ]
then
    mkdir -p /data/profiles/home
    cp -r /userdata/profiles/* /data/profiles/home/
fi
if [ -d /userdata/mpmissions ] && [ "$(ls -A /userdata/mpmissions)" ]
then
    mkdir -p /data/mpmissions
    cp -r /userdata/mpmissions/* /data/mpmissions/
fi

# Run arma server
echo "hambone: Running arma server..."
cd /data
./arma3-server.sh
