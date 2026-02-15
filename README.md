# My-Utils

一键初始化个人 Linux / macOS 开发环境，支持 zsh、bash，配置 vimrc、zshrc、bashrc 等。

## 特性

- 支持 Linux（Ubuntu / Debian / Fedora）和 macOS
- 配置以软链接管理，修改保存在仓库内，便于备份和版本控制
- 支持一键或按需安装，`--yes` 静默执行
- 场景化配置：C++、Python、AI Infra（LLVM / MLIR、TVM）

## 快速开始

```bash
git clone https://github.com/your-user/my-utils.git ~/repos/my-utils
cd ~/repos/my-utils

# 一键安装
./bootstrap.sh --yes

# 或交互式选择
./bootstrap.sh

exec $SHELL
```

## 安装选项

```bash
# 仅安装系统包
./bootstrap.sh --tools packages --yes

# 仅创建软链接（vimrc、bashrc、zshrc 等）
./bootstrap.sh --tools links --yes

# 仅安装 oh-my-zsh、pyenv
./bootstrap.sh --tools misc --yes

# 仅安装 vim 插件
./bootstrap.sh --tools vimrc --yes
```

## 配置结构

`~/.vimrc`、`~/.bashrc`、`~/.zshrc` 等通过软链接指向仓库内 `config/` 下的文件，修改 `config/` 中的文件即修改实际使用的配置，可直接 git 提交。

```sh
config/
├── _vimrc      → ~/.vimrc
├── _bashrc     → ~/.bashrc
├── _zshrc      → ~/.zshrc
├── myrc.bash
├── resetrc.bash
└── ...
```

## 场景 Profiles

```bash
source ~/repos/my-utils/profiles/cpp/env.bash      # C++ / LLVM
source ~/repos/my-utils/profiles/python/env.bash   # Python
source ~/repos/my-utils/profiles/ai_infra/env.bash  # AI Infra
```

## License

MIT
