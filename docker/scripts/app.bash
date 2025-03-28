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
dir_data=/data
dir_userdata=/userdata
dir_userdata_mods=/userdata/mods
dir_userdata_mpmissions=/userdata/mpmissions
dir_userdata_profiles=/userdata/profiles
dir_userdata_server=/userdata/server
dir_home=/home/server
dir_keys=/data/keys
dir_keys_vanilla=/data/keys-vanilla
dir_mods=/data/mods
dir_workshop=/data/steamapps/workshop/content/107410
id_game=107410
id_server=233780
path_mods_yaml=/userdata/server/mods.yaml

# Activate python venv
source ~/.venv/bin/activate

# Run steamcmd
if [ -z $fast_mode ]; then
    python generate_steamcmd_script.py          \
           $path_mods_yaml $dir_data             \
           $id_server $id_game                  \
           "$STEAM_USERNAME" "$STEAM_PASSWORD"  \
           > $dir_home/steamcmd.txt
    /usr/bin/steamcmd +runscript $dir_home/steamcmd.txt
fi

# Gather mods
rm -rf $dir_mods
mkdir -p $dir_mods
python get_mod_ids.py $path_mods_yaml | \
    while read id name; do
        ln -s $dir_workshop/"$id" $dir_mods/"$name"
    done
python get_mod_paths.py $path_mods_yaml | \
    while read path name; do
        cp -r $dir_userdata_mods/"$path" $dir_mods/"$name"
    done

# Gather keys
if [ ! -d $dir_keys_vanilla ]; then
    cp -r $dir_keys $dir_keys_vanilla
fi
rm -rf $dir_keys
cp -r $dir_keys_vanilla $dir_keys
python get_mod_ids.py $path_mods_yaml | \
    while read id name; do
        find -L $dir_mods/"$name"/key* -iname "*.bikey" -exec \
             cp {} $dir_keys/ \;
    done
python get_mod_paths.py $path_mods_yaml | \
    while read path name; do
        find -L $dir_mods/"$name"/key* -iname "*.bikey" -exec \
             cp {} $dir_keys/ \;
    done

# Lowercase files
./lowercase-file-paths.bash $dir_mods
./lowercase-file-paths.bash $dir_keys

# Gather server files
python generate_par_file.py $path_mods_yaml mods > $dir_data/arma.par
cp $dir_userdata_server/server.cfg $dir_data/server.cfg
cp $dir_userdata_server/arma3-server.sh $dir_data/arma3-server.sh
if [ -d $dir_userdata_profiles ] && [ "$(ls -A $dir_userdata_profiles)" ]
then
    mkdir -p $dir_data/profiles/home
    cp -r $dir_userdata_profiles/* $dir_data/profiles/home/
fi
if [ -d $dir_userdata_mpmissions ] && [ "$(ls -A $dir_userdata_mpmissions)" ]
then
    mkdir -p $dir_data/mpmissions
    cp -r $dir_userdata_mpmissions/* $dir_data/mpmissions/
fi

# Run arma server
cd $dir_data
./arma3-server.sh
