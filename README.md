# moow_packages

`moow_packages` 是一个面向 OpenWrt / ImmortalWrt SDK 与 Buildroot 的第三方软件包 feed。

当前仓库主要包含这些包：

- `smartdns`
- `smartdns-ui`
- `luci-app-smartdns`
- `ddns-go`
- `luci-app-ddns-go`
- `naiveproxy`
- `phantun-client`
- `phantun-server`
- `luci-theme-argon`
- `gn`（主要作为 `naiveproxy` 的构建依赖）

## 添加 feed

在 SDK 或完整源码的 `feeds.conf.default` 里加入：

```bash
src-git-full moow_packages https://github.com/XMoon/moow_packages.git
```

然后更新 feed：

```bash
./scripts/feeds update -a
```

## 基于 SDK 编译本仓库的包

下面这套流程基于实际编译记录整理，适用于在 OpenWrt SDK 中单独编译本仓库包体。

### 1. 主机依赖

至少需要一套常见的 OpenWrt SDK 构建依赖，例如：

```bash
apt install build-essential clang flex bison g++ gawk \
gcc-multilib g++-multilib gettext git libncurses5-dev libssl-dev \
python3-setuptools rsync swig unzip zlib1g-dev file wget
```

如果要编译 `smartdns-ui`，还需要额外注意：

- 本机需可用 `npm`
- 需要 Rust host 构建环境
- 网络需能访问 npm / cargo / GitHub 下载源

### 2. 安装包到 SDK

常见安装方式如下：

```bash
./scripts/feeds install phantun-server
./scripts/feeds install phantun-client
./scripts/feeds install luci-theme-argon
./scripts/feeds install naiveproxy
./scripts/feeds install luci-app-ddns-go
```

`smartdns` / `luci-app-smartdns` 与官方 feed 存在同名包时，建议显式强制切到 `moow_packages` 版本：

```bash
./scripts/feeds uninstall smartdns luci-app-smartdns smartdns-ui
./scripts/feeds install -p moow_packages -f smartdns luci-app-smartdns smartdns-ui
```

说明：

- `-p moow_packages` 指定安装来源
- `-f` 强制覆盖同名包

安装完成后，`package/feeds/moow_packages/*` 会链接到本仓库对应目录。

### 3. 选择要编译的包

```bash
make menuconfig
```

建议第一次先选成模块包 `=m`，便于单独分发和验证。

### 4. 单包编译

排查问题时，优先使用单线程详细日志：

```bash
make package/feeds/moow_packages/smartdns/compile -j1 V=s
make package/feeds/moow_packages/luci-app-smartdns/compile -j1 V=s
make package/feeds/moow_packages/ddns-go/compile -j1 V=s
make package/feeds/moow_packages/luci-app-ddns-go/compile -j1 V=s
make package/feeds/moow_packages/naiveproxy/compile -j1 V=s
make package/feeds/moow_packages/phantun/compile -j1 V=s
make package/feeds/moow_packages/luci-theme-argon/compile -j1 V=s
```

几个目标名对应关系：

- `phantun-server` / `phantun-client` 共用 `package/feeds/moow_packages/phantun/compile`
- `smartdns-ui` 由 `smartdns` 目录一并产出
- `luci-app-ddns-go` 和 `ddns-go` 可以分开编

### 5. 批量编译

依赖都准备好以后，可以直接：

```bash
make -j$(nproc)
```

### 6. 产物位置

编译产物通常在：

```bash
bin/packages/<arch>/moow_packages/
```

例如 `x86_64` SDK 下通常是：

```bash
bin/packages/x86_64/moow_packages/
```

可用下面的命令快速检查：

```bash
find bin/packages -path '*/moow_packages/*' -type f
```

## 常见问题

### 1. `smartdns` 找不到 `rust-package.mk`

这个仓库在 SDK feed 场景下需要从 `feeds/packages` 引入 Rust 构建辅助文件：

```make
include $(TOPDIR)/feeds/packages/lang/rust/rust-package.mk
```


### 2. `ddns-go` 编译时 Go 依赖下载失败

如果编译卡在 Go 模块下载，先检查代理和 Go 环境变量：

```bash
env | grep -E '^(http|https|all|HTTP|HTTPS|ALL)_proxy=|^GOPROXY=|^NO_PROXY=|^no_proxy='
```

如果本地代理配置异常，可以先清掉：

```bash
unset http_proxy https_proxy all_proxy HTTP_PROXY HTTPS_PROXY ALL_PROXY
```

### 3. WSL 下 `PATH` 含空格导致 Go 构建异常

在 WSL 环境里，如果 `PATH` 被注入了带空格的 Windows 路径，例如 `Program Files`，部分 Go 包在 OpenWrt SDK 里可能会因为 `PATH` 展开问题而构建失败。

这类问题通常出现在外部 feed `feeds/packages/lang/golang/golang-package.mk`，不是本仓库自身逻辑问题，但在 WSL 环境下比较常见。

### 4. `smartdns-ui` 依赖较重

`smartdns-ui` 会额外触发 Rust 与前端构建流程，包括：

- `cargo install --force --locked bindgen-cli`
- `npm install`
- `npm run build`

如果只需要 `smartdns` 服务端，建议不要同时启用 `smartdns-ui`。

## 一套可直接复用的命令顺序

```bash
./scripts/feeds update -a

./scripts/feeds install phantun-server
./scripts/feeds install phantun-client
./scripts/feeds install luci-theme-argon
./scripts/feeds install naiveproxy
./scripts/feeds install luci-app-ddns-go

./scripts/feeds uninstall smartdns luci-app-smartdns smartdns-ui
./scripts/feeds install -p moow_packages -f smartdns luci-app-smartdns smartdns-ui

make menuconfig

make package/feeds/moow_packages/smartdns/compile -j1 V=s
make package/feeds/moow_packages/luci-app-smartdns/compile -j1 V=s
make package/feeds/moow_packages/ddns-go/compile -j1 V=s

make -j$(nproc)
```
