# STM32H743 工程模板（CubeMX + VSCode + Makefile + OpenOCD）

> 这是一个可直接复用的新项目初始化模板，面向个人/小团队长期维护。  
> 路线固定为：**STM32CubeMX 生成基础代码 + Makefile 构建 + VSCode 开发 + OpenOCD 烧录/调试**。

---

## 1. 环境要求

- `arm-none-eabi-gcc`（建议 12.x 或更新）
- `arm-none-eabi-objcopy` / `arm-none-eabi-size`
- `mingw32-make`（Windows）或 `make`（Linux/macOS）
- `openocd`
- VSCode 扩展：
  - `ms-vscode.cpptools`
  - `marus25.cortex-debug`

---

## 2. 推荐目录（兼容 CubeMX 生成）

```text
.
├─ .vscode/
│  ├─ tasks.json
│  ├─ launch.json
│  └─ c_cpp_properties.json
├─ build/                       # 构建输出
├─ openocd/
│  └─ stm32h743.cfg
├─ linker/
│  └─ STM32H743xI.ld
├─ startup/
│  └─ startup_stm32h743xx.s     # 必须使用 CubeMX/CMSIS 真实版本
├─ src/                         # 你的业务代码（长期维护）
├─ inc/                         # 你的业务头文件（长期维护）
├─ Core/                        # CubeMX 常见目录（可选）
├─ Drivers/                     # CubeMX 生成 HAL/CMSIS
├─ Makefile
└─ README.md
```

---

## 3. 哪些文件由 CubeMX 管，哪些你长期维护

### 3.1 CubeMX 生成后通常不改（或尽量少改）

- `Drivers/CMSIS/**`
- `Drivers/STM32H7xx_HAL_Driver/**`
- `Core/Src/*`、`Core/Inc/*`（仅建议在 `USER CODE` 区域改）
- `.ioc`（建议放在 `cube/` 或根目录并纳入版本管理）
- `startup/startup_stm32h743xx.s`（建议由 CubeMX/CMSIS 提供，不手写）

### 3.2 建议长期手工维护

- `Makefile`
- `.vscode/tasks.json`
- `.vscode/launch.json`
- `.vscode/c_cpp_properties.json`
- `openocd/stm32h743.cfg`
- `linker/*.ld`（按板卡 Flash/RAM 布局调整）
- `src/**`、`inc/**`（业务代码/BSP 封装）
- `README.md`、`docs/**`

---

## 4. 常用命令

Windows（推荐）：

```bash
mingw32-make
mingw32-make clean
mingw32-make rebuild
mingw32-make flash
mingw32-make size
mingw32-make list
```

Linux/macOS：

```bash
make
make clean
make rebuild
make flash
make size
make list
```

构建配置：

```bash
mingw32-make CONFIG=debug
mingw32-make CONFIG=release
```

---

## 5. 首次使用步骤（最小落地流程）

1. 用 CubeMX 生成 STM32H743 工程（HAL），确保生成 `Core/`、`Drivers/` 和 **真实** `startup_stm32h743xx.s`。
2. 把本模板中的 `Makefile`、`.vscode/`、`openocd/` 拷贝进工程根目录。
3. 把模板中的 `startup/startup_stm32h743xx.s` 替换为 CubeMX/CMSIS 真实版本（如果你已经有真实版本，可直接覆盖模板占位文件）。
4. 检查并按板卡修改以下变量：
   - `MCU` / `DEVICE`
   - `LDSCRIPT`
   - `STARTUP`
   - `OPENOCD_CFG`
5. 执行 `make list`（或 `mingw32-make list`）确认源文件与 include 目录。
6. 执行 `make`（或 `mingw32-make`）编译。
7. 执行 `make flash`（或 `mingw32-make flash`）烧录。
8. VSCode 选择 `STM32H743 Debug (OpenOCD)` 启动调试。

---

## 6. 常见问题

### `_init` 重复定义

若你在 `syscalls.c` 中实现了 `_init`，可能与工具链 `crti.o` 冲突。可使用：

- `-nostartfiles`
- `--specs=nano.specs --specs=nosys.specs`

本模板已在链接参数中给出默认配置。

---

## 7. 说明

- 本模板默认以 `STM32H743ZI` / `STM32H743xx` 为示例，**后续可按你的板卡型号调整**。
- `svdFile` 默认写为 `${workspaceFolder}/STM32H743.svd`，若无此文件可先删除该字段或替换为实际路径。
- 当前仓库内的 `startup/startup_stm32h743xx.s` 是为了模板完整性提供的占位版本，**新项目首次使用时必须替换为真实启动文件**。

---

## 8. 首次使用（5~8 步最短路径）

1. Clone 模板仓库到新项目目录。
2. 用 CubeMX 生成你板卡对应的 `Core/`、`Drivers/`、`startup` 和 `.ioc`。
3. 用真实 `startup_stm32h743xx.s` 覆盖模板占位启动文件。
4. 修改 `Makefile` 中 `DEVICE`、`LDSCRIPT`、`STARTUP`、`OPENOCD_CFG`。
5. 修改 `.vscode/launch.json` 中 `device`、`svdFile`（`executable` 默认与 Makefile 输出对齐，若改输出目录请同步改）。
6. 执行 `make list` 检查路径，再执行 `make`、`make size`、`make flash`。

详细核对项请看：`docs/FIRST_USE_CHECKLIST.md`。
