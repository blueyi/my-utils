#! /bin/sh
#
# ascend_dev_env_init.sh
# Copyright (C) 2020 wangyulong <wangyulong@wyl-dev>
#
# Distributed under terms of the MIT license.
#

# Don't execut in root

# Modify source mirror for apt and pip
sudo cp -a /etc/apt/sources.list /etc/apt/sources.list.bak 
sudo sed -i "s@http://.*archive.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list
sudo sed -i "s@http://.*security.ubuntu.com@http://mirrors.huaweicloud.com@g" /etc/apt/sources.list

mkdir ~/.pip
echo "[global]
index-url = https://mirrors.huaweicloud.com/repository/pypi/simple
trusted-host = mirrors.huaweicloud.com
timeout = 120" > pip.conf

# Install package for python build
sudo apt update
sudo apt-get install -y build-essential libssl-dev zlib1g-dev libbz2-dev \
libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev \
xz-utils tk-dev libffi-dev liblzma-dev python-openssl git vim

# Install dependency of linux package for MindStudio
sudo apt install -y g++ firefox xdg-utils openjdk-8-jdk fonts-droid-fallback \
fonts-wqy-zenhei fonts-wqy-microhei fonts-arphic-ukai fonts-arphic-uming gnome-keyring \
zlib1g-dev libbz2-dev libsqlite3-dev libssl-dev libxslt1-dev libffi-dev

# Build python and install python3.7.5
wget --no-check-certificate https://cdn.npm.taobao.org/dist/python/3.7.5/Python-3.7.5.tgz
tar -zxvf Python-3.7.5.tgz
PY_PATH=/usr/local/python3.7.5
cd Python-3.7.5
./configure --prefix=${PY_PATH} --enable-shared
make -j4 && sudo make install
cd ..

cp ${PY_PATH}/lib/libpython3.7m.so.1.0 /usr/lib/

# sudo rm -rf /usr/bin/python3 /usr/local/bin/python3
# sudo ln -s ${PY_PATH}/bin/python3 /usr/bin/python3
# sudo rm -rf /usr/bin/python3.7 /usr/local/bin/python3.7
# sudo ln -s ${PY_PATH}/bin/python3 /usr/bin/python3.7
# sudo rm -rf /usr/bin/pip3 /usr/local/bin/pip3
# sudo ln -s ${PY_PATH}/bin/pip3 /usr/bin/pip3
# sudo rm -rf /usr/bin/pip3.7 /usr/local/bin/pip3.7
# sudo ln -s ${PY_PATH}/bin/pip3 /usr/bin/pip3.7

# Install dependency of python package for MindStudio
sudo /usr/local/python3.7.5/bin/pip3.7 install numpy decorator sympy cffi coverage pylint gnureadline \
matplotlib psutil attrs grpcio protobuf requests scipy PyQt5==5.14.0 xlrd absl-py Pillow

# Install ascend Run package
wget --no-check-certificate https://public-download.obs.cn-east-2.myhuaweicloud.com/MindStudio_2.4.3_linux-x86_64.zip
unzip MindStudio_2.4.3_linux-x86_64.zip
sh Ascend-Toolkit-20.10.0.B023-x86_64-linux_gcc7.3.0_toDC.run --install
tar -zxvf MindStudio_2.4.3_linux-x86_64.tar.gz -C ~/

echo "######################"
echo "MindStudio is installed in $HOME/MindStudio-ubuntu"
echo "######################"

# set env for Asecne toolkit
echo "
export TOOLKIT_PATH=\$HOME/Ascend/ascend-toolkit/20.10.0.B023/x86_64-linux_gcc7.3.0
export ACL_SO_PATH=\$TOOLKIT_PATH/pyACL/python/site-packages/acl
export ATC_CCE_BIN_PATH=\$TOOLKIT_PATH/atc/ccec_compiler/bin:\$TOOLKIT_PATH/atc/bin
export ATC_PY_PATH=\$TOOLKIT_PATH/atc/python/site-packages:\$TOOLKIT_PATH/atc/python/site-packages/auto_tune.egg/auto_tune:\$TOOLKIT_PATH/atc/python/site-packages/schedule_search.egg
export ATC_LIB_PATH=\$TOOLKIT_PATH/atc/lib64
export ADC_BIN_PATH=\$TOOLKIT_PATH/toolkit/bin
export OP_TEST_PY_PATH=\$TOOLKIT_PATH/toolkit/python/site-packages

export PYTHONPATH=\${PYTHONPATH}:\$ACL_SO_PATH:\$ATC_PY_PATH:\$OP_TEST_PY_PATH
export PATH=\${PATH}:\$ATC_CCE_BIN_PATH:\$ADC_BIN_PATH
export LD_LIBRARY_PATH=\$LD_LIBRARY_PATH:\$ATC_LIB_PATH
" >> ~/.bashrc
