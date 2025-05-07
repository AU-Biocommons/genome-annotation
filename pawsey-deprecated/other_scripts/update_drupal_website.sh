#!/bin/bash

# copy website from old drupal core version and rebuild website with newer drupal core version
# takes 2 parameters: old.drupal.version new.drupal.version
#                 eg: 9.0.0 9.1.0
#
# NOTE: this script needs to be run as root
#
# Author j.lee@qcif.edu.au, 21/1/2021

# THIS needs to be edited to match the website being updated
website="apollo-portal"
#website="drupal-sandpit"

if [ $# -ne 2 ]; then
    echo "Usage: $(basename $0) old.drupal.version new.drupal.version" 2>&1
    echo "Example: $(basename $0) 9.0.0 9.1.0" 2>&1
    echo "" 2>&1
    exit 1
fi

oldver="$1"
newver="$2"

if [ ! -e drupal-${newver}.tar.gz ]; then
    echo "drupal-${newver}.tar.gz not found!" 2>&1
    echo "" 2>&1
    read -p "Do you wish to download the drupal tarball from drupal.org (y/N)? " -r choice
    case "$choice" in
        y|Y ) # download
            wget https://ftp.drupal.org/files/projects/drupal-${newver}.tar.gz || exit 1
            echo "drupal-${newver}.tar.gz successfully downloaded" 2>&1
            ;;
	* ) # don't continue
            echo "The drupal tarball can be manually downloaded with:" 2>&1
            echo "    wget https://ftp.drupal.org/files/projects/drupal-${newver}.tar.gz" 2>&1
            echo "" 2>&1
            echo "Exiting..." 2>&1
            echo "" 2>&1
            exit 1
            ;;
    esac
fi

echo "Extracting drupal-${newver}.tar.gz to /var/www/"
read -p "Press enter to continue (Ctrl-C to abort)"
tar -zxvf drupal-${newver}.tar.gz -C /var/www/ || exit 1
cd /var/www/
ls -l /var/www/
echo ""

echo "copy existing drupal website ${website}_${oldver} into new website ${website}_${newver}"
read -p "Press enter to continue (Ctrl-C to abort)"
cp -prd ${website}_${oldver} ${website}_${newver} || exit 1
# and visually verify copy is same size
du -sh ${website}_${oldver} ${website}_${newver}
echo ""

echo "copy drupal updates (drupal-${newver}) into new website ${website}_${newver}"
read -p "Press enter to continue (Ctrl-C to abort)"
cd ${website}_${newver} || exit 1
cp -Rf ../drupal-${newver}/* ./ || exit 1
cd ..
ls -l /var/www/${website}_${newver}
echo ""

echo "change website ownership to www-data"
#read -p "Press enter to continue (Ctrl-C to abort)"
chown -R www-data:www-data ${website}_${newver} || exit 1
ls -l /var/www/
echo ""

echo "update symlinks: "
echo "                  ${website}.old -> ${website}_${oldver}"
echo "                  ${website} -> ${website}_${newver}"
#read -p "Press enter to continue (Ctrl-C to abort)"
rm -f ${website}.old
mv -f ${website}{,.old} && ln -s ${website}_${newver} ${website}
ls -l /var/www/
echo ""

echo "delete temp extracted drupal update directory drupal-${newver}"
#read -p "Press enter to continue (Ctrl-C to abort)"
rm -rdf drupal-${newver}
ls -l /var/www/
echo ""

echo ""
echo "Completed Drupal website update to version ${newver}"
echo "Check version of Drupal core is correct from website admin -> reports -> updates"
echo ""

