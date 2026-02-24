# Portable Runtime 设计说明

**文档版本**: 0.2.0  
**创建日期**: 2026-02-25  
**更新日期**: 2026-02-25  
**状态**: Draft（Decision Confirmed）

---

## 1. 决策结论

1. 默认采用 Portable 模式：在 `init` 阶段下载私有运行时。
2. 默认不安装系统全局包，不修改系统级 PATH，不写入系统服务。
3. 运行时文件统一放在用户隔离目录，可整体删除回收。
4. 该方案在 Linux（Ubuntu/Debian 首发基线）可行，作为当前实现主路径。

---

## 2. 可行性确认（结论）

1. 可行：可通过预编译运行时 + 校验清单，在 `init` 阶段完成自举。
2. 下载源可使用 GitHub Releases，并配置 Gitee 镜像回退。
3. 启动时通过 wrapper 注入私有 `PATH`/`LD_LIBRARY_PATH`，避免污染系统环境。
4. 若网络不可用或校验失败，流程应阻断在 `init`，并提供 `resume` 继续能力。
5. 不同发行版的底层 ABI 差异依旧存在，需要通过平台清单和兼容提示做前置约束。

---

## 3. 目标

1. 将 Node/Python 运行时与项目依赖从系统环境中隔离。
2. 在网络可用时完成初始化下载；中断后可 `resume` 继续。
3. 启动阶段复用已准备运行时，避免重复下载。
4. 默认不需要用户手工全局安装组件即可完成可运行基线。

---

## 4. 非目标

1. 不承诺覆盖所有 Linux 发行版“零兼容问题”。
2. 不在本阶段支持 Windows/macOS 运行时打包。
3. 不在默认路径中自动做系统级依赖安装（仅提示或显式授权后执行）。

---

## 5. 目录建议

以 `VCP_INSTALLER_HOME` 为根（默认 `~/.local/share/vcpinstallergui`）：

1. `runtime/node/`：Node 运行时。
2. `runtime/python/`：Python 运行时与 `venv`。
3. `runtime/cache/`：下载缓存与校验文件。
4. `runtime/manifests/`：版本、来源、SHA256、签名信息。
5. `runtime/bin/`：wrapper 启动脚本。
6. `state/`：阶段状态快照（支持 `resume`）。
7. `reports/`：初始化/安装报告。

---

## 6. 下载源与清单

1. 使用 runtime manifest 描述下载项：
   - `name`
   - `version`
   - `platform`
   - `url_primary`
   - `url_mirror`
   - `sha256`
   - `signature`（可选）
2. 默认下载优先级：`GitHub` -> `Gitee`。
3. 同一版本在不同源必须保持同文件名、同 SHA256。
4. 清单更新需版本化，避免客户端和清单不兼容。

---

## 7. 初始化流程（目标状态）

1. `S20_INIT_PROFILE`：采集工作区与启动命令。
2. `S25_RUNTIME_PLAN`：根据平台生成下载清单。
3. `S26_RUNTIME_FETCH`：下载运行时与依赖包（支持断点续传）。
4. `S27_RUNTIME_VERIFY`：校验 SHA256/签名。
5. `S28_RUNTIME_PREPARE`：解压、链接、生成 wrapper。
6. `S50_INSTALL`：执行组件安装与配置生成。
7. `S70_REPORT`：导出报告并记录可恢复状态。

---

## 8. 环境污染控制

1. 默认不调用系统包管理器做全局安装。
2. 默认不写入 `/usr`、`/etc`、系统级 shell profile。
3. 所有运行时注入仅在 installer 启动的子进程内生效。
4. `reset --runtime`（后续实现）应支持私有运行时整目录回收。

---

## 9. 风险与缓解

1. 首次初始化耗时增加（下载体积大）。
   - 缓解：缓存复用、分阶段下载、断点恢复。
2. glibc/动态库兼容差异导致部分发行版失败。
   - 缓解：平台白名单、预检阻断、清晰错误提示。
3. 镜像可用性影响首装稳定性。
   - 缓解：主/备下载源切换 + 失败后 `resume`。

---

## 10. 验收要点

1. `init` 能下载并校验至少一套私有运行时清单。
2. `start` 默认使用私有运行时启动，不依赖系统全局 Node/Python。
3. 删除 `VCP_INSTALLER_HOME/runtime` 后可重新 `init` 恢复。
4. 默认流程不会改动系统全局 PATH 与全局 npm/pip 包。
