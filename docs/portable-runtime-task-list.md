# Portable Runtime 任务清单

**目标**: 完成“初始化下载私有运行时，默认不全局安装”的可交付闭环。  
**更新日期**: 2026-02-25  
**状态**: In Progress

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

- [ ] 定义 manifest schema（`name/version/platform/url/sha256/signature`）。
- [ ] 定义 GitHub 主源 + Gitee 镜像回退字段与优先级策略。
- [ ] 增加 manifest 版本号与兼容策略（客户端最小支持版本）。
- [ ] 增加 manifest 校验器（字段完整性 + URL + SHA256 格式）。

## 3. `init` 自举实现

- [ ] 在 `init` 中加入 `plan/fetch/verify/prepare` 阶段落盘状态。
- [ ] 实现下载断点续传与已校验缓存复用。
- [ ] 校验失败必须阻断后续安装并输出修复建议。
- [ ] 下载失败支持 `resume` 继续，且不重复已完成文件。

## 4. 启动隔离实现

- [ ] 生成 runtime wrapper（注入私有 `PATH`/`LD_LIBRARY_PATH`）。
- [ ] `start` 仅使用已准备运行时，不触发下载副作用。
- [ ] 增加可选开关 `--runtime-mode portable|system`（默认 portable）。
- [ ] 系统集成模式必须二次确认并记录审计日志。

## 5. 可观测性与恢复

- [ ] 安装报告新增 runtime manifest、下载源、校验结果、耗时。
- [ ] `status` 增加运行时健康状态（版本/路径/完整性）。
- [ ] `reset` 支持 runtime 清理（后续命令参数可细化）。
- [ ] `resume` 支持从 `fetch`/`verify` 阶段恢复。

## 6. 测试与发布门禁

- [ ] 新增 smoke：`init` 下载（mock）+ `resume` + wrapper 启动链路。
- [ ] 新增弱网/离线回归策略文档与最小验证脚本。
- [ ] 更新 release checklist 的 Portable Runtime 验收项为必须项。
- [ ] 将“默认不污染系统环境”加入 release 验收报告。

## 7. 需要项目管理员确认

- [ ] 确认 runtime 二进制发布仓库（GitHub 仓库地址）。
- [ ] 确认 Gitee 镜像仓库与同步方式（手动/自动）。
- [ ] 确认首发 runtime 版本矩阵（Ubuntu/Debian x86_64）。
