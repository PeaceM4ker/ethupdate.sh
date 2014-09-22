#!/bin/bash
##
## Made by Nick Kallechy
##

ubu_install () {
        a=`modinfo e1000e | grep version | sed 's|.*version:        \([0-9\.]*\).*|\1|' | grep -v -e srcversion -e vermagic`
        echo "Current Driver version is:"$a
        echo "Is the version: "$a" out of date?"
        select begin in yes no
        do
                if [ $begin == yes ]; then
                        sleep 1
                        cd /usr/src
                        echo "Downloading New Driver Package"
                        wget http://dcops-ops.chi02.singlehop.net/drivers/e1000e-3.0.4.1-dkms.tar.gz
                        echo "Unpacking Driver Package"
                        tar xzvf e1000e-3.0.4.1-dkms.tar.gz
                        echo "Removing Old Driver from DKM"
                        dkms remove -m e1000e -v $a --all
                        echo "Adding New driver to DKM"
                        dkms add -m e1000e -v 3.0.4.1
                        echo "Building New Driver Set"
                        dkms build -m e1000e -v 3.0.4.1
                        echo "Installing Drivers"
                        dkms install -m e1000e -v 3.0.4.1
                        echo "Removing Old e1000e module and Probing for New One"
                        rmmod e1000e && modprobe e1000e
                        echo "Checking New Driver Version"
                        modinfo e1000e | grep version
                        echo "Is the Current Installed Driver Version Correct?"
                        select shutdown in yes no
                        do
                                if [ $shutdown == yes ]; then
                                        echo "Removing scripts and rebooting down"
                                        rm ethupdate.sh -y
                                        sudo shutdown now -rf
                                elif [ $shutdown == no ]; then
                                        rm ethupdate.sh -y
                                        echo "Driver install not successful, Try again, or update Manually"
                                        exit
                                fi
                        done
                elif [ $begin == no ]; then
                        echo "Driver Version is Up-to-Date Enough"
                        rm ethupdate.sh -y
                        exit
                fi
        done
}

cent5-6.5_install () {
        dkms status | grep -i e1000e
        dkms remove -m e1000e -v 2.5.4 --all
        rpm --import http://elrepo.org/RPM-GPG-KEY-elrepo.org
        rpm -Uvh http://elrepo.org/elrepo-release-6-5.el6.elrepo.noarch.rpm
        yum list|grep -i e1000
        yum -y install kmod-e1000e.x86_64
        modinfo e1000e | grep -w version
        rm -f /etc/yum.repos.d/elrepo.repo
        sudo shutdown now -rf
}

cent6.x_install () {
        cd /usr/src
        wget http://downloadmirror.intel.com/15817/eng/e1000e-2.5.4.tar.gz
        tar xzf e1000e-2.5.4.tar.gz
        cd e1000e-2.5.4/src/
        make CFLAGS_EXTRA=-DDISABLE_PCI_MSI CFLAGS_EXTRA=-DE1000E_NO_NAPI install
        nano /boot/grub/menu.lst
        pcie_aspm=off e1000e.IntMode=1,1
        echo "continue and change the dkms.conf?"
        select dkm in yes no
        do
                if [ $dkm == "yes"  ]; then
                        echo "instructions: change autoinstall=yes to no"
                        sleep 5
                        nano /var/lib/dkms/e1000e/1.9.5/build/dkms.conf
                elif [ $dkm == "no" ]; then
                        echo "Ok then"
                        exit
                fi
        done
        sudo shutdown now -rf
}
text_yes () {
        echo "you have choosen to begin the driver install for "$choice
}
text_no () {
        echo "cancelled, i didnt want to update e1000e drivers anyways :("
        exit
}

echo "!!THIS SCRIPT REINSTALLS THE DRIVERS ON ALL e1000e BASED SYSTEMS!!"
echo "!!IF THE DRIVER IS 2.5.4-k OR ABOVE YOU PROBABLY DON'T NEED TO RUN IT!!"
echo "!!PLEASE REFER TO THE FOLLOWING WIKI FOR ISSUES OR CONSULTATION!!"
sleep 1
echo "https://portal.singlehop.net/wiki/index.php?title=X9scm_drivers"
sleep 2
echo "please choose the OS of the system you are on"
select choice in ubu cent5-6.5 cent6.x nevermind;
do
        if [ $choice == "ubu" ]; then
                echo "ubu choosen"
                select final in yes no;
                        do
                                if [ $final == "yes" ]; then
                                        text_yes
                                        ubu_install
                                elif [ $final == "no" ]; then
                                        text_no
                                fi
                        done
        elif [ $choice == "cent5-6.5" ]; then
                echo "cent5-6.5 choosen"
                                select final in yes no;
                        do
                                if [ $final == "yes" ]; then
                                        text_yes
                                        cent5-6.5_instll
                                elif [ $final == "no" ]; then
                                        text_no
                                fi
                        done
        elif [ $choice == "cent6.x" ]; then
                echo "cent6.x choosen"
                                select final in yes no;
                        do
                                if [ $final == "yes" ]; then
                                        text_yes
                                        cent6.x_install
                                elif [ $final == "no" ]; then
                                        text_no
                                fi
                        done
        elif [ $choice == "nevermind" ]; then
                echo "well alright then"
                exit
        fi
done
