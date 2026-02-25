# Portable Runtime 任务清单

**目标**: 完成“初始化下载私有运行时，默认不全局安装”的可交付闭环。  
**更新日期**: 2026-02-25  
**状态**: Blocked（仅剩 GitHub 发布仓库地址确认）

---

## 0. 已确认约束

- [x] 默认模式为 `portable`，`init` 阶段下载私有运行时。
- [x] 默认不修改系统级 PATH，不做全局 npm/pip 安装。
- [x] 可执行产物需支持删除用户隔离目录后完整回收。

## 1. 文档与设计对齐

- [x] 需求文档写入 FR-010 与验收口径（`requirements-design.md`）。
- [x] Linux AIO 文档同步 Portable 策略与状态机（`linux-aio-design.md`）。
- [x] 输出 Portable 专项设计说明（`portable-runtime-design.md`）。

## 2. Runtime Manifest 与源管理

- [x] 定义 manifest schema（`record_type|name|version|platform|url_primary|url_mirror|sha256|signature`）。
- [x] 定义 GitHub 主源 + Gitee 镜像回退字段（`url_primary/url_mirror`）与客户端优先级（主源失败回退镜像）。
- [x] 增加 manifest 版本号与兼容策略（`manifest_version|1`）。
- [x] 增加 manifest 校验器（字段完整性 + URL + SHA256 格式，见 `scripts/validate-runtime-manifest.sh`）。

## 3. `init` 自举实现

- [x] 在 `init` 中加入 `plan/fetch/verify/prepare` 阶段落盘状态（`S25/S26/S27/S28`）。
- [x] 实现下载断点续传与已校验缓存复用（`.part` + sha 命中跳过）。
- [x] 校验失败必须阻断后续安装并输出修复建议。
- [x] 下载失败支持 `resume` 继续，且不重复已完成文件。

## 4. 启动隔离实现

- [x] 生成 runtime wrapper（注入私有 `PATH`/`LD_LIBRARY_PATH`）。
- [x] `start` 仅使用已准备运行时，不触发下载副作用。
- [x] 增加可选开关 `--runtime-mode portable|system`（默认 portable）。
- [x] 系统集成模式支持二次确认并记录审计日志（`--allow-system-integration` + audit log）。

## 5. 可观测性与恢复

- [x] 安装报告新增 runtime manifest/包装器/环境污染安全字段（`global_mutation.safe_default=true`）。
- [x] `status` 增加运行时健康状态（模式/manifest/wrapper/health）。
- [x] `reset` 支持 runtime 清理（`--reset-runtime`）。
- [x] `resume` 支持从 `fetch`/`verify` 阶段恢复（依赖 init 快照）。

## 6. 测试与发布门禁

- [x] 新增 smoke：`init` 下载（mock）+ `resume` + wrapper 启动链路。
- [x] 新增弱网/离线回归策略文档与最小验证脚本（`docs/runtime-network-regression.md` + `scripts/runtime-regression.sh`）。
- [x] 更新 release checklist 的 Portable Runtime 验收项为必须项（见 `tmp/release-task-checklist.md` section 13）。
- [x] 将“默认不污染系统环境”加入 release 验收报告（install report `global_mutation` 字段）。

## 7. 需要项目管理员确认

- [ ] 确认 runtime 二进制发布仓库（GitHub 仓库地址）。
- [x] Gitee 镜像策略暂时冻结（忽略，不作为当前发布阻塞项）。
- [x] 首发平台口径调整为 Linux `x86_64`（`glibc` 基线）；Ubuntu/Debian 仅作为回归测试基线。

---

## 8. 当前阻塞项（对外发布）

1. 默认 manifest 仍是模板占位，未绑定可用线上产物地址。
2. 发布前需要管理员确认 GitHub runtime 发布仓库地址（用于产物 URL 固化）。
