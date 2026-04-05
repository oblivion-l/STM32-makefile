# 模板验收报告（STM32H743 + CubeMX + VSCode + Makefile + OpenOCD）

## 1. 验收目标

把模板从“文件补齐”推进到“新项目可直接复用”，并与当前仓库结构对齐。

## 2. 一致性检查结果

### 2.1 Makefile 路径对齐

- 源码路径：使用候选目录自动筛选，仅保留当前存在目录。`src` / `Core/Src` / `Drivers/.../Src`。
- include 路径：同样使用候选目录自动筛选，仅保留当前存在目录。
- linker 路径：默认 `linker/STM32H7xx/STM32H743xI.ld`。
- startup 路径：默认 `startup/startup_stm32h743xx.s`。
- OpenOCD 路径：默认 `openocd/stm32h743.cfg`。
- 预检查：增加 `precheck`，构建前检查 linker/startup/openocd 配置文件。

### 2.2 VSCode 配置对齐

- `tasks.json`：命令与 Makefile 目标一一对应，且提供跨平台命令（`make` / Windows 下 `mingw32-make`）。
- `launch.json`：`configFiles` 指向 `openocd/stm32h743.cfg`，`preLaunchTask` 指向 `make: build (debug)`，`executable` 指向 `build/debug/${workspaceFolderBasename}.elf`。

## 3. 启动文件策略

当前 `startup/startup_stm32h743xx.s` 为占位文件。

结论：

- 在模板仓库中可保留占位版本用于结构完整性。
- 在新项目首次落地时，**必须替换为 CubeMX/CMSIS 真实启动文件**。

此要求已同步写入：

- `README.md`
- `docs/PROJECT_STRUCTURE.md`

## 4. 实际命令验收结果

在当前环境执行：

- `make clean`：通过
- `make`：失败（缺少 `arm-none-eabi-gcc`）
- `make rebuild`：失败（同上）
- `make size`：失败（同上）
- `make list`：通过
- `make flash`：失败（依赖编译产物，且当前环境无工具链）

说明：

- 失败原因是运行环境缺少 ARM 工具链，不是模板目标缺失。
- `list` 可用于在无工具链时先验证路径与目标映射。

## 5. 当前可复用状态结论

已达到“模板可复用”要求：

- 构建系统目标完整（含 debug/release + flash/size/list）
- VSCode 任务和调试配置与 Makefile 对齐
- OpenOCD 配置可直接作为 H743 + ST-Link 起点
- 文档明确 CubeMX 生成部分与手工维护部分边界
- 明确启动文件占位策略与首次替换要求

## 6. 新项目落地最小步骤

1. 用 CubeMX 生成 H743 工程（HAL），拿到 `Core/`、`Drivers/`、真实 `startup_stm32h743xx.s`。
2. 拷贝本模板中的：`Makefile`、`.vscode/`、`openocd/`、文档。
3. 用真实启动文件替换模板占位启动文件。
4. 按板卡修改 `Makefile`：`DEVICE`、`LDSCRIPT`、`STARTUP`、`OPENOCD_CFG`。
5. 运行 `make list` 检查路径和源文件；再运行 `make`、`make flash`。
