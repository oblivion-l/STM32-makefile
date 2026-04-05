# 首次使用检查清单（STM32H743 + CubeMX + VSCode + Makefile）

> 适用场景：你新建了一个 STM32H743 项目，准备把本模板直接套进去。

## 一、必须修改（不改通常无法正常构建/烧录）

1. **芯片宏 `DEVICE`**（Makefile）
   - 位置：`Makefile` 中 `DEVICE ?= STM32H743xx`
   - 动作：按你的具体芯片改为匹配宏（例如 `STM32H743xx` / `STM32H750xx`）。

2. **链接脚本 `LDSCRIPT`**（Makefile）
   - 位置：`Makefile` 中 `LDSCRIPT ?= ...`
   - 动作：改成你的板卡对应 `.ld` 文件路径。

3. **启动文件 `STARTUP`**（Makefile + 文件本体）
   - 位置：`Makefile` 中 `STARTUP ?= startup/startup_stm32h743xx.s`
   - 动作：
     - 用 CubeMX/CMSIS 生成的真实 `startup_stm32h743xx.s` 覆盖模板占位文件。
     - 确认 `STARTUP` 路径与实际文件一致。

4. **OpenOCD 配置 `OPENOCD_CFG`**（Makefile + openocd）
   - 位置：`Makefile` 中 `OPENOCD_CFG ?= openocd/stm32h743.cfg`
   - 动作：根据你的调试器和芯片调整（interface/target）。

5. **`launch.json` 中必须替换项**
   - `device`：按你芯片具体型号修改。
   - `svdFile`：改为你实际存在的 SVD 路径（或删除该字段）。
   - `executable`：确认与 Makefile 输出路径一致（默认 `build/debug/<工程名>.elf`）。

## 二、建议检查（不一定马上报错，但容易埋坑）

1. **CubeMX 重新生成后差异检查**
   - 重点看：
     - `Core/Src/*`, `Core/Inc/*` 是否只在 `USER CODE` 区域保留手改。
     - `Drivers/**` 是否被意外手工修改。
     - `startup`、`linker` 是否被新版本覆盖。

2. **Makefile 自动路径识别结果**
   - 执行 `make list`，确认：
     - `Existing source dirs` 列表符合预期。
     - `Existing include dirs` 列表包含 CubeMX 生成目录。

3. **tasks / launch 对齐**
   - `tasks.json` 的 `build/flash/size` 是否都能调用到当前 Makefile。
   - `launch.json` 的 `preLaunchTask` 是否与任务名称一致。

## 三、可选调整（按团队习惯）

1. **编译优化等级**
   - `debug` 默认 `-Og -g3`
   - `release` 默认 `-O2`
   - 可按项目改为 `-Os` 等策略。

2. **告警等级**
   - 默认 `-Wall -Wextra -Wshadow -Wundef -Wdouble-promotion`。
   - 可按团队代码规范增减。

3. **OpenOCD 速度与复位策略**
   - `adapter speed` 可按板卡稳定性调低。
   - `reset_config` 可按硬件连线调整。

## 四、最短验收命令（建议每次新项目初始化都执行）

```bash
make list
make
make size
make flash
```

如果 `make` 报找不到 `arm-none-eabi-gcc`：

- 先安装 ARM GNU Toolchain
- 确保 `arm-none-eabi-gcc --version` 可执行
