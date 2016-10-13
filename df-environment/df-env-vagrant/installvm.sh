#!/bin/bash
echo "************************************************************************"
echo "*******************Welcome DF Environment Setup Guide*******************"
echo "************************************************************************"
echo "Note: In order to run this guide, make sure following soft are installed"
echo "      1. vagrant   - https://www.vagrantup.com                          "
echo "      2. virtulbox - https://www.virtualbox.org                         "
echo "************************************************************************"
echo "* Please go through this guideline to complete the installation/setup. *"
echo "* You can exit by pressing 0 from any step.                            *"
echo "************************************************************************"

while true; do
    read -p "Q1. Do you have network proxy or firewall (y or n)?" q1
    case $q1 in
        [y]* ) break;;
        [n]* ) break;;       
        [0]* ) exit;;
        * ) echo "Please answer y|n or exit with 0.";;
    esac
done

echo "Q2. There are following installation profiles avaliable"
echo "******1. latest   - This is the latest stack used for development"
echo "******2. demo     - This is the stable stack for the demo purpose"

while true; do
    read -p "Do you wish to install which profile for VM setup (1 or 2)?" q2
    
    q12=$q1$q2

    case $q12 in
        [y1]* ) rm -f ./vagrant_shell/deb.sh; echo -e '#!/bin/bash\nproxy_enabled=true' > ./vagrant_shell/deb.sh; cat ./install_profiles/profile_dev.sh ./vagrant_shell/deb.part.sh >> ./vagrant_shell/deb.sh; break;;
        [y2]* ) rm -f ./vagrant_shell/deb.sh; echo -e '#!/bin/bash\nproxy_enabled=true' > ./vagrant_shell/deb.sh; cat ./install_profiles/profile_demo.sh ./vagrant_shell/deb.part.sh >> ./vagrant_shell/deb.sh; break;;       
        [n1]* ) rm -f ./vagrant_shell/deb.sh; echo -e '#!/bin/bash\nproxy_enabled=false' > ./vagrant_shell/deb.sh; cat ./install_profiles/profile_dev.sh ./vagrant_shell/deb.part.sh >> ./vagrant_shell/deb.sh; break;;
        [n2]* ) rm -f ./vagrant_shell/deb.sh; echo -e '#!/bin/bash\nproxy_enabled=false' > ./vagrant_shell/deb.sh; cat ./install_profiles/profile_demo.sh ./vagrant_shell/deb.part.sh >> ./vagrant_shell/deb.sh; break;;       
        [0]* ) exit;;
        * ) echo "Please answer 1|2 or exit with 0.";;
    esac
done

while true; do
    read -p "Q3. Do you wish to fresh install(i) or update (u) the VM (choose i or u)?" q3
    case $q3 in
        [iI]* ) vagrant up; break;;
        [uU]* ) vagrant provision; break;;       
        [0]* ) exit;;
        * ) echo "Please answer i|u or exit with 0.";;
    esac
done