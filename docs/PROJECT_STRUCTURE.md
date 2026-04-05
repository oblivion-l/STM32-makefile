# 项目目录职责说明（STM32H743 + CubeMX + Makefile）

本文用于说明目录职责，避免后续维护时“生成代码”和“手工代码”混在一起。

## 推荐目录

```text
.
├─ .vscode/                     # VSCode 任务与调试配置（手工维护）
├─ build/                       # 构建产物（自动生成，忽略）
├─ openocd/                     # OpenOCD 配置（手工维护）
├─ linker/                      # 链接脚本（手工维护，可按板卡调整）
├─ startup/                     # 启动文件（建议使用 CubeMX/CMSIS 真实版本）
├─ src/                         # 业务代码/BSP（手工维护）
├─ inc/                         # 业务头文件（手工维护）
├─ Core/                        # CubeMX 生成（尽量只改 USER CODE 区）
├─ Drivers/                     # CubeMX 生成 HAL/CMSIS（通常不改）
├─ Makefile                     # 构建系统核心（手工维护）
└─ README.md                    # 项目说明（手工维护）
```

## 维护边界

### CubeMX 生成后通常不改

- `Drivers/CMSIS/**`
- `Drivers/STM32H7xx_HAL_Driver/**`
- `Core/Src/*`, `Core/Inc/*`（除 `USER CODE` 区域外）
- `startup/startup_stm32h743xx.s`（建议使用生成版本，不建议长期手工维护）

### 需要长期维护

- `Makefile`
- `.vscode/tasks.json`
- `.vscode/launch.json`
- `.vscode/c_cpp_properties.json`
- `openocd/stm32h743.cfg`
- `src/**`, `inc/**`
- `README.md`, `docs/**`

## 启动文件说明（重要）

- 模板仓库中的 `startup/startup_stm32h743xx.s` 为占位文件，仅用于保证模板结构完整。
- 在新项目首次落地时，**必须替换为 CubeMX/CMSIS 生成的真实启动文件**。
- 未替换时，即使能编译通过，也不能作为可运行固件依据。

## 建议流程

1. 先在 CubeMX 修改配置并重新生成。
2. 立即替换模板占位启动文件为真实启动文件。
3. 执行 `make list` 检查源文件与 include 集合是否正确。
4. 执行 `make` / `make flash` 验证编译和烧录。
5. 提交前查看 `git diff`，确认没有误改 CubeMX 自动生成部分。
