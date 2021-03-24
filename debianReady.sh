#!/bin/bash
#1.通过阿里云后台VNC登录，运行本bash
#2.完成后本地运行sshlogin.sh
#if debian runs unstable, use this sh to reinstall system, compare to full-install, it's skip
#1. create disk
#2. create folders

#Backup /etc/safe-rm.conf, docker container, /etc/logrotate.d, /etc/nginx, /etc/passwd, /etc/ssh, /etc/letsencrypt
# /root/.ssh/authorized_keys, /home
# crontab -e
#0 2 * * * /bin/bash /dskr/bak/db/mysql/byboat/task/buadt.sh
#0 2 * * * /bin/bash /dskr/bak/git/erp.dev/task/crona.sh
#0 2 * * * /bin/bash /dskr/bak/git/erpapp/task/crona.sh

#check user
if [ `whoami` = "root" ];then
	echo "Start"
else
	echo "Please switch to 'root'"
	exit
fi
LOG_FILE="/var/log/oise_debian_install.log"
>"${LOG_FILE}"
exec &> >(tee "$LOG_FILE")
set -x

echo -e "\033[43;30m -------------Setup Swap------------- \033[0m"

swapoff -a
dd if=/dev/zero of=/var/.swap bs=4k count=1048576
chmod 0600 /var/.swap
mkswap /var/.swap
echo "/var/.swap none swap sw 0 0" >> /etc/fstab
swapon -a
#echo "/root/swapfile swap swap defaults 0 0" >> /etc/fstab

echo -e "\033[42;30m -------------Setup Swap Done------------- \033[0m \n"
#1. mount dska dskr
echo -e "\033[43;30m -------------Remount Disk------------- \033[0m"

mkdir /dska
mount /dev/vdb /dska
echo "$(blkid /dev/vdb | awk '{print $2}' | sed 's/\"//g') /dska ext4 defaults 0 0" >> /etc/fstab

mkdir /dskr
mount /dev/vdc /dskr
echo "$(blkid /dev/vdc | awk '{print $2}' | sed 's/\"//g') /dskr ext4 defaults 0 0" >> /etc/fstab

echo -e "\033[43;30m -------------Remount Disk Done------------- \033[0m"
#2.clear /dskr/tmp

echo -e "\033[43;30m -------------Prepare------------- \033[0m"
#mv /dskr/tmp /dskr/tmp_a
mkdir /dskr/tmp

mv /etc/apt/sources.list /dskr/tmp
mv /etc/ssh/sshd_config /dskr/tmp
mv /etc/sysctl.conf /dskr/tmp
mv /etc/security/limits.conf /dskr/tmp

wget -O /etc/apt/sources.list https://raw.githubusercontent.com/gitlun/oise_debian/master/sources_list
wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/gitlun/oise_debian/master/sshd_config_default
wget -O /etc/sysctl.conf https://raw.githubusercontent.com/gitlun/oise_debian/master/sysctl_default.conf
wget -O /etc/security/limits.conf https://raw.githubusercontent.com/gitlun/oise_debian/master/limits_default.conf
echo -e "\033[43;30m -------------Prepare Disk------------- \033[0m"

echo -e "\033[43;30m -------------Update Debian------------- \033[0m"
apt update
export DEBIAN_FRONTEND=noninteractive
apt -y full-upgrade

echo -e "\033[43;30m -------------Update Debian Done------------- \033[0m \n"

echo -e "\033[43;30m -------------reconfig locales------------- \033[0m"
echo "zh_CN.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
echo -e "\033[42;30m -------------reconfig locales done------------- \033[0m \n"

#wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/gitlun/oise_debian/master/sshd_config_new
#service sshd restart
#mkdir /dskr/tmp/defaultsysctl
#mv /etc/sysctl.conf /dskr/tmp/defaultsysctl
wget -O /etc/sysctl.conf https://raw.githubusercontent.com/gitlun/oise_debian/master/sysctl.conf_new
sysctl -p
#echo "root soft nofile 65535" >> /etc/security/limits.conf
#echo "* soft nofile 65535" >> /etc/security/limits.conf
#echo "* hard nofile 65535" >> /etc/security/limits.conf

echo -e "\033[43;30m -------------Install sudo and safe-rm ------------- \033[0m"
apt -y install sudo safe-rm
wget -O /etc/safe-rm.conf https://raw.githubusercontent.com/gitlun/oise_debian/master/safe-rm.conf
echo -e "\033[42;30m -------------Install sudo and safe-rm done------------- \033[0m \n"

echo -e "\033[43;30m -------------Install nginx docker------------- \033[0m"

apt -y install apt-transport-https ca-certificates curl gnupg2 software-properties-common lsb-release

echo "deb http://nginx.org/packages/mainline/debian buster nginx" \
    | sudo tee /etc/apt/sources.list.d/nginx.list
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
    | sudo tee /etc/apt/preferences.d/99nginx
curl -o /tmp/nginx_signing.key https://nginx.org/keys/nginx_signing.key
gpg --dry-run --quiet --import --import-options import-show /tmp/nginx_signing.key
mv /tmp/nginx_signing.key /etc/apt/trusted.gpg.d/nginx_signing.asc
#curl -fsSL https://nginx.org/keys/nginx_signing.key | sudo apt-key add -
#curl -fsSL https://mirrors.163.com/nginx/keys/nginx_signing.key | sudo apt-key add -

curl -fsSL https://mirrors.cloud.aliyuncs.com/linux/debian/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://mirrors.cloud.aliyuncs.com/linux/debian \
  buster stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
#add-apt-repository "deb [arch=amd64] http://mirrors.cloud.aliyuncs.com/docker-ce/linux/debian buster stable"
apt update
apt -y install nginx
apt -y install docker-ce docker-ce-cli containerd.io

# install docker compose
curl -L "https://github.com/docker/compose/releases/download/1.28.5/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo -e "\033[42;30m -------------Install nginx docker done------------- \033[0m \n"

echo -e "\033[43;30m -------------Install nvm node------------- \033[0m"
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.37.2/install.sh | bash
source /root/.bashrc
nvm install 14
npm install pm2 -g
npm install -g npm-check-updates
#pm2 install pm2-logrotate
echo -e "\033[42;30m -------------Install nvm node done------------- \033[0m \n"

echo -e "\033[43;30m -------------Install need------------- \033[0m"
apt -y install certbot
echo -e "\033[42;30m -------------Install need done------------- \033[0m \n"

echo -e "\033[43;30m -------------Install xfce4------------- \033[0m"
apt -y install xfce4 xfce4-goodies lightdm-gtk-greeter-settings
systemctl set-default multi-user.target
echo -e "\033[42;30m -------------Install xfce4 done------------- \033[0m \n"

echo -e "\033[43;30m -------------Install font------------- \033[0m"
apt -y install fonts-wqy-microhei fonts-wqy-zenhei xfonts-wqy
echo -e "\033[42;30m -------------Install font done------------- \033[0m \n"

echo -e "\033[43;30m -------------Install fcitx------------- \033[0m"
apt -y install fcitx fcitx-sunpinyin
echo -e "\033[42;30m -------------Install fcitx done------------- \033[0m \n"

echo -e "\033[43;30m -------------Install extr------------- \033[0m"
apt -y install firefox-esr default-jre-headless
echo -e "\033[42;30m -------------Install extr done------------- \033[0m \n"

echo -e "\033[43;30m -------------Install netdata------------- \033[0m"
#apt -y install netdata --no-install-recommends
apt -y install tigervnc-standalone-server
echo -e "\033[42;30m -------------Install netdata done------------- \033[0m \n"

echo -e "\033[43;30m -------------Clean------------- \033[0m"
apt -y autoremove
apt -y autoclean
echo -e "\033[42;30m -------------Clean Done------------- \033[0m \n"

echo -e "\033[43;30m -------------Add user------------- \033[0m"
#begin with 1010
#group
groupadd -g 1010 ssher
groupadd -g 1011 sftper
groupadd -g 1012 giter
groupadd -g 1013 devr
groupadd -g 1014 devper
groupadd -g 1015 porter

wget -O /dskr/tmp https://raw.githubusercontent.com/gitlun/oise_debian/master/users-list.txt
cd /dskr/tmp
newusers users-list.txt

useradd -G ssher porter
useradd -G devper devr
useradd -G devper porter


echo -e "\033[42;30m -------------Add user Done------------- \033[0m \n"

#update ssh_config for sshlogin
wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/gitlun/oise_debian/master/sshd_config_ready
service sshd restart


#wget -O /etc/ssh/sshd_config https://raw.githubusercontent.com/gitlun/oise_debian/master/sshd_config_new
#service sshd restart