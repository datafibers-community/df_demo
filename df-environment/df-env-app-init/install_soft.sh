#!/bin/bash
set -e

install_flag=${1:-false}
install_soft_link_name=$2
install_folder_name=$3
dl_link=$4

install_soft_base=/opt
install_soft_link=$install_soft_base/$install_soft_link_name
install_folder=$install_soft_base/$install_folder_name

if [ "$install_flag" = true ]; then
	file_name=`basename $dl_link`

	if [ ! -e $install_folder ]; then
	    if [ ! -d /tmp/vagrant-downloads ]; then
            mkdir -p /tmp/vagrant-downloads
            sudo chmod a+rw /tmp/vagrant-downloads
        fi
		cd /tmp/vagrant-downloads
		if [ ! -e $file_name ]; then
			wget --progress=bar:force $dl_link --no-check-certificate
		fi
		mkdir -p $install_folder && tar xf /tmp/vagrant-downloads/$file_name -C $install_folder

		ln -sfn $install_folder $install_soft_link
		cd $install_soft_link
		# Following 3 steps mv all stuff from subfolder to upper folder and delete it
		mv * delete
		mv */* .
		rm -rf delete
	else
		echo "[INFO] Found $install_folder, ignore installation. "
	fi
	echo "[INFO] Installed ${file_name}"
fi

