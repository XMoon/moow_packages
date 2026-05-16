# Agent Notes

## naiveproxy 版本更新流程

更新 `naiveproxy` 时，不要只改 `PKG_REAL_VERSION`。这个包还固定了 Chromium 的 clang 和 Linux PGO profile，三组源码/依赖 hash 都需要一起更新并编译验证。

1. 确认 upstream 最新 release。

   优先打开 GitHub release/tag 页面核对 `Latest` 标记和发布时间，例如：

   ```bash
   https://github.com/klzgrad/naiveproxy/releases
   https://github.com/klzgrad/naiveproxy/releases/tag/v<version>
   ```

   不要只依赖搜索结果摘要；摘要可能滞后。

2. 下载 release 源码包并计算 `PKG_HASH`。

   ```bash
   version="148.0.7778.96-5"
   curl -L --fail -o "/tmp/naiveproxy-v${version}.tar.gz" \
     "https://codeload.github.com/klzgrad/naiveproxy/tar.gz/v${version}"
   sha256sum "/tmp/naiveproxy-v${version}.tar.gz"
   ```

3. 解包源码，读取 Chromium clang 和 Linux PGO pin。

   ```bash
   rm -rf "/tmp/naiveproxy-v${version}"
   mkdir -p "/tmp/naiveproxy-v${version}"
   tar -xzf "/tmp/naiveproxy-v${version}.tar.gz" \
     -C "/tmp/naiveproxy-v${version}" --strip-components=1

   rg -n "CLANG_REVISION|CLANG_SUB_REVISION|PACKAGE_VERSION" \
     "/tmp/naiveproxy-v${version}/src/tools/clang/scripts/update.py"

   cat "/tmp/naiveproxy-v${version}/src/chrome/build/linux.pgo.txt"
   ```

   `CLANG_VER` 的格式是去掉 `llvmorg-` 前缀后的 `CLANG_REVISION` 加上 `CLANG_SUB_REVISION`，例如：

   ```text
   CLANG_REVISION = 'llvmorg-23-init-5669-g8a0be0bc'
   CLANG_SUB_REVISION = 4
   CLANG_VER:=23-init-5669-g8a0be0bc-4
   ```

   `PGO_VER` 是 `linux.pgo.txt` 中 `chrome-linux-` 和 `.profdata` 之间的部分。

4. 下载 clang 与 PGO profile，计算各自 hash。

   如果新 release 读取出的 clang/PGO pin 与当前 `Makefile` 完全相同，可以复用已有下载文件，但仍要确认 `Makefile` 中的 hash 与文件匹配。

   ```bash
   clang_ver="23-init-5669-g8a0be0bc-4"
   pgo_ver="7778-1777374771-45dd5813b3332165d1d1cd33a478e0a7b948195e-d8efa9b284bd43eccbaf67df2d4a1deaa3c39b89"

   curl -L --fail -o "/tmp/clang-llvmorg-${clang_ver}.tar.xz" \
     "https://commondatastorage.googleapis.com/chromium-browser-clang/Linux_x64/clang-llvmorg-${clang_ver}.tar.xz"

   curl -L --fail -o "/tmp/chrome-linux-${pgo_ver}.profdata" \
     "https://storage.googleapis.com/chromium-optimization-profiles/pgo_profiles/chrome-linux-${pgo_ver}.profdata"

   sha256sum "/tmp/clang-llvmorg-${clang_ver}.tar.xz"
   sha256sum "/tmp/chrome-linux-${pgo_ver}.profdata"
   ```

5. 更新 `naiveproxy/Makefile`。

   需要同步修改这些字段：

   - `PKG_REAL_VERSION`
   - `PKG_HASH`
   - `CLANG_VER`
   - `Download/CLANG` 里的 `HASH`
   - `PGO_VER`
   - `Download/PGO_PROF` 里的 `HASH`

6. 在 SDK 下验证。

   如果 SDK 的 `feeds/moow_packages/naiveproxy` 是独立拷贝而不是当前仓库的 symlink，需要先把更新后的 `naiveproxy/Makefile` 同步到 SDK feed 目录。也可以把刚下载并校验过的三个文件预先复制到 SDK 的 `dl/`，减少重复下载。

   本仓库常用测试 SDK 示例：

   ```bash
   sdk="/home/xmoon/openwrt/openwrt-sdk-25.12.1-x86-64_gcc-14.3.0_musl.Linux-x86_64"

   cp naiveproxy/Makefile "$sdk/feeds/moow_packages/naiveproxy/Makefile"
   cp "/tmp/naiveproxy-v${version}.tar.gz" "$sdk/dl/naiveproxy-${version}.tar.gz"
   [ -f "/tmp/clang-llvmorg-${clang_ver}.tar.xz" ] && \
     cp "/tmp/clang-llvmorg-${clang_ver}.tar.xz" "$sdk/dl/clang-llvmorg-${clang_ver}.tar.xz"
   [ -f "/tmp/chrome-linux-${pgo_ver}.profdata" ] && \
     cp "/tmp/chrome-linux-${pgo_ver}.profdata" "$sdk/dl/chrome-linux-${pgo_ver}.profdata"

   make -C "$sdk" package/feeds/moow_packages/naiveproxy/download V=s
   make -C "$sdk" package/feeds/moow_packages/naiveproxy/compile V=s -j"$(nproc)"
   ```

7. 验证产物与工作区。

   ```bash
   ls -lh "$sdk/bin/packages/x86_64/moow_packages"/naiveproxy-*.apk
   git diff -- naiveproxy/Makefile
   git status --short
   ```

   编译成功时，ninja 会完成 `LINK ./naive`，SDK 会生成类似：

   ```text
   bin/packages/x86_64/moow_packages/naiveproxy-<version-with-dots>-r1.apk
   ```
