# Portable Bash Dotfiles

通用 Linux Bash 环境配置，面向 Debian、Ubuntu、Fedora、RHEL 等服务器环境。目标是保持启动快、可维护、可选增强，并且不会因为缺少某个工具导致 shell 启动失败。

## Features

- Bash 5.x 兼容，尽量兼容 Bash 4.x
- 模块化 Bash 配置，不把所有内容堆进 `.bashrc`
- 自动加载 `bash-completion`
- 增强 history：
  - 大容量历史记录
  - 多终端历史合并
  - 去除重复命令
  - 上下方向键按前缀搜索历史
  - 保留时间戳
- 可选加载增强工具：
  - `ble.sh`
  - `fzf`
  - `bash-completion`
  - `git`
  - `tmux`
  - `docker`
  - `podman`
- 简洁服务器风格 prompt：
  - `user@host`
  - 当前路径
  - Git branch
  - root 用户红色高亮
- 常用 alias 和小工具函数
- 安装脚本会备份已有配置并创建软链接
- 不自动安装软件，不执行危险操作

## Layout

```text
dotfiles/
├── bashrc
├── bash/
│   ├── aliases.sh
│   ├── functions.sh
│   ├── prompt.sh
│   ├── completion.sh
│   └── tools.sh
├── vimrc
├── tmux.conf
└── install.sh
```

## Installation

Clone the repository:

```bash
git clone git@github.com:wtfllix/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

If you have not configured SSH keys for GitHub, use HTTPS instead:

```bash
git clone https://github.com/wtfllix/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

Then open a new shell, or reload Bash:

```bash
source ~/.bashrc
```

The installer creates these links:

```text
~/.dotfiles  -> cloned repository, or symlink to it
~/.bashrc    -> ~/.dotfiles/bashrc
~/.vimrc     -> ~/.dotfiles/vimrc
~/.tmux.conf -> ~/.dotfiles/tmux.conf
```

Existing files are moved to:

```text
~/.dotfiles-backup/YYYYMMDD-HHMMSS/
```

## Recommended Packages

Debian / Ubuntu:

```bash
sudo apt install bash-completion fzf git vim tmux
```

Fedora:

```bash
sudo dnf install bash-completion fzf git vim-enhanced tmux
```

RHEL / CentOS / Rocky / AlmaLinux:

```bash
sudo dnf install bash-completion git vim-enhanced tmux
```

`fzf` and `ble.sh` may require EPEL or manual installation on some RHEL-like systems.

## Optional Tools

These integrations are loaded only when available:

- `nvim`
- `fzf`
- `tmux`
- `docker`
- `podman`
- `ble.sh`

Missing optional tools do not break shell startup.

## Local Overrides

For host-specific private settings, keep them outside the repository:

```bash
~/.bashrc.local
```

`bashrc` loads this file automatically when it exists. Use it for secrets, private aliases, host-specific environment variables, proxy auto-enable, or internal paths.

## Proxy

The installer asks whether proxy should be enabled automatically for new interactive shells.

Default proxy:

```text
http://127.0.0.1:7892
```

If enabled, the installer writes a managed block to:

```bash
~/.bashrc.local
```

The repository only provides the functions:

```bash
proxy_on
proxy_off
proxy_status
```

Manual usage:

```bash
proxy_on
proxy_on http://127.0.0.1:7892
proxy_status
proxy_off
```

Supported auto-config schemes:

```text
http
https
socks5
socks5h
```

Rerun `./install.sh` to change or disable the managed proxy auto-enable block.

## Safe Aliases

The default configuration does not override destructive commands such as `rm`, `cp`, or `mv`.

To enable safer interactive aliases:

```bash
export DOTFILES_SAFE_ALIASES=1
source ~/.bashrc
```

This enables:

```text
rm -I
cp -i
mv -i
```

## Development

Run syntax checks:

```bash
bash -n bashrc
bash -n bash/*.sh
bash -n install.sh
```

Run the installer again after edits:

```bash
./install.sh
source ~/.bashrc
```

## Notes

- `.bashrc` exits early for non-interactive shells.
- The prompt calls Git only inside Git work trees.
- All external tools are checked with `command -v` or readable file checks before loading.
- The installer reports missing recommended tools, but does not install packages automatically.
