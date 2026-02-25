# Runtime 弱网/离线回归策略

**文档版本**: 0.1.0  
**创建日期**: 2026-02-25  
**状态**: Draft

---

## 1. 目标

验证 Portable Runtime 在以下网络场景下的行为一致性：

1. 主源不可达时自动回退镜像源。
2. 下载失败后可通过 `resume` 继续。
3. 默认不触发系统全局安装，不修改系统 PATH。

## 2. 最小回归脚本

执行：

```bash
cd VCPInstallerGUI
./scripts/runtime-regression.sh
```

脚本覆盖场景：

1. `primary=unreachable` + `mirror=file://`，验证镜像回退成功。
2. `primary=unreachable` + `mirror=-`，验证 `init` 阻断失败。
3. 替换为可用 manifest 后执行 `resume`，验证恢复成功。

## 3. 通过标准

1. 首轮回退场景可生成 `runtime/bin/vcp-runtime-exec`。
2. 离线失败场景必须返回非 0 并停在 runtime 阶段。
3. `resume` 后恢复成功，并重新生成 runtime wrapper。

## 4. 注意事项

1. 脚本使用本地临时目录 `.local-build-env/runtime-regression-*`。
2. 脚本使用 `file://` 本地产物模拟镜像源，不依赖外网。
3. 真正发布前仍需用 GitHub/Gitee 真实二进制源做一次联调验证。
