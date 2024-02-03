# comment with #
# git configure
git config --global user.name "blueyi"
git config --global user.email "blueyiniu@qq.com"

# fonts
# git clone https://github.com/blueyi/myfonts.git ~/.fonts
# sudo fc-cache -f -v

# some useful ppa
# sudo add-apt-repository -y ppa:wiznote-team/ppa   # wiznote client for ubuntu
# sudo add-apt-repository -y ppa:graphics-drivers/ppa  # nvidia graphic drivers
# sudo add-apt-repository -y ppa:webupd8team/java  # Oracle JAVA
# sudo add-apt-repository -y ppa:hzwhuang/ss-qt5  # shadowsocks-qt5 client

# Another soft

# hexo install
# curl https://raw.githubusercontent.com/creationix/nvm/master/install.sh | sh
# nvm install stable
# npm install -g hexo-cli

# my hexo blog
# git clone git@github.com:blueyi/hexoblog.git ~/blog

# Oh My Zsh install
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# pyenv install
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
cd ~/.pyenv && src/configure && make -C src

