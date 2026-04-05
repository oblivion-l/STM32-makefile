# STM32H743 长期维护模板（CubeMX + VSCode + Makefile + OpenOCD）

> 目标：面向个人/小团队，强调“可复用、可维护、可升级”，不引入 CMake。

## 1. 你当前状态评估（结论）

你已经把最关键的链路跑通了：

- 能编译 / 链接 / 烧录
- 启动文件、链接脚本、HAL 初始化可工作
- OpenOCD 已可用
- `_init` 冲突问题已处理（`-nostartfiles + nano.specs + nosys.specs`）

这已经是“可开发状态”。下一步重点是把项目从“能跑”升级为“可长期维护模板”。

## 2. 推荐目录结构（适合 H743 + CubeMX）

```text
project-root/
├─ .vscode/
│  ├─ tasks.json
│  ├─ launch.json
│  ├─ c_cpp_properties.json
│  └─ settings.json
├─ build/                       # 构建输出（git 忽略）
├─ cube/                        # CubeMX 工程源（强烈建议保留）
│  └─ <project>.ioc
├─ Drivers/
│  ├─ CMSIS/
│  └─ STM32H7xx_HAL_Driver/
├─ linker/
│  └─ STM32H743xI.ld
├─ openocd/
│  ├─ board.cfg
│  └─ flash.gdb
├─ src/
│  ├─ app/                      # 用户应用层（建议）
│  ├─ bsp/                      # 板级封装（建议）
│  ├─ hal_gen/                  # CubeMX 生成的 *.c（建议集中）
│  └─ system/                   # system_stm32h7xx.c/syscalls/sysmem 等
├─ inc/
│  ├─ app/
│  ├─ bsp/
│  ├─ hal_gen/
│  └─ system/
├─ startup/
│  └─ startup_stm32h743xx.s
├─ scripts/
│  ├─ check-toolchain.ps1
│  └─ release.ps1
├─ docs/
│  ├─ build.md
│  ├─ debug.md
│  └─ cubemx-regenerate.md
├─ Makefile
├─ compile_flags.txt
├─ .gitignore
├─ README.md
└─ VERSION
```

### 哪些现在“先不用加”

- 单元测试框架（Ceedling/Unity）后续再引入即可，第一阶段不是必需项。
- CI（GitHub Actions）如果当前主要在 Windows 本地开发，可以先不配。
- Doxygen 文档自动化可以等接口稳定后再上。

## 3. 文件职责边界（非常关键）

### CubeMX 管（尽量不手改）

- `cube/*.ioc`
- `src/hal_gen/*`（如 `gpio.c/fdcan.c/usart.c/dma.c`）
- `inc/hal_gen/*`
- HAL/CMSIS 目录

### 你自己管（长期稳定核心）

- `Makefile`
- `.vscode/tasks.json`
- `.vscode/launch.json`
- `.vscode/c_cpp_properties.json`
- `openocd/*.cfg`
- `linker/*.ld`（可从 Cube 初版导入，后续人工维护）
- `src/app/*`、`src/bsp/*`、`inc/app/*`、`inc/bsp/*`
- `docs/*`、`README.md`、`.gitignore`、`VERSION`

### 规则建议

1. 用户逻辑只放在 `app/bsp`，不要塞进 Cube 生成文件。
2. 若必须改生成文件，尽量限定在 `/* USER CODE BEGIN */` 块。
3. 每次重新生成后先 `git diff`，确认没有破坏手工改动。

## 4. 模板仓库必备文件清单

### 必须有

- `.gitignore`
- `README.md`
- `VERSION`
- `.vscode/tasks.json`
- `.vscode/launch.json`
- `.vscode/c_cpp_properties.json`
- `openocd/board.cfg`
- `docs/build.md`
- `docs/debug.md`
- `docs/cubemx-regenerate.md`

### 推荐有

- `scripts/check-toolchain.ps1`（检查 `arm-none-eabi-gcc`, `openocd`, `make`）
- `scripts/release.ps1`（打包 hex/bin/map）
- `CHANGELOG.md`（版本演进）

## 5. 建议 .gitignore（Windows + VSCode + Makefile）

```gitignore
# Build outputs
build/
*.o
*.d
*.elf
*.map
*.hex
*.bin

# IDE / editor
.vscode/*.log
*.code-workspace

# OS
.DS_Store
Thumbs.db

# Python/cache tools
__pycache__/
*.pyc

# Optional local overrides
.local/
```

> 如果你希望团队共享 `.vscode`，就不要忽略 `.vscode/*.json`；只忽略日志或本地覆盖文件。

## 6. README 模板结构（建议）

```md
# <ProjectName> (STM32H743)

## 1. Overview
- MCU: STM32H743xxx
- Toolchain: arm-none-eabi-gcc
- Build system: Makefile
- Debug/Flash: OpenOCD + ST-Link
- Codegen: STM32CubeMX

## 2. Quick Start
1) 安装工具链（gcc/openocd/mingw32-make）
2) `mingw32-make -j8`
3) `mingw32-make flash`
4) `mingw32-make debug`

## 3. Directory Layout
（贴你的目录树）

## 4. Common Commands
- build / clean / flash / erase / debug / size

## 5. CubeMX Regenerate Workflow
- 先提交当前代码
- 重新生成
- 对比差异
- 只接受预期变更

## 6. Troubleshooting
- `_init` multiple definition:
  - 链接参数使用 `-nostartfiles`
  - 配合 `--specs=nano.specs --specs=nosys.specs`

## 7. Versioning
- 见 VERSION / CHANGELOG
```

## 7. 建议 tasks.json（核心任务）

建议最少提供这些 task：

- `build`
- `rebuild`
- `flash`
- `erase`
- `size`
- `openocd-server`

并在 `flash` 依赖 `build`，避免把旧产物烧进去。

## 8. 建议 launch.json（Cortex-Debug）

关键字段：

- `type: cortex-debug`
- `servertype: openocd`
- `configFiles: ["openocd/board.cfg"]`
- `executable: "${workspaceFolder}/build/<name>.elf"`
- `svdFile`（可选，建议配）
- `preLaunchTask: "build"`

## 9. Makefile 维护建议（针对你当前路线）

1. **分层变量**：芯片/板级参数与通用编译参数分离。
2. **显式源文件列表**：不要完全依赖通配符，避免误编译。
3. **输出统一到 `build/`**：含 `obj/ dep/ elf/ map/ bin`。
4. **默认开启依赖生成**：`-MMD -MP`。
5. **保留 size/map 目标**：每次构建可追踪体积变化。
6. **规范链接参数顺序**：
   - `-T linker.ld`
   - `-Wl,-Map=...`
   - `-Wl,--gc-sections`
   - `-nostartfiles`
   - `--specs=nano.specs --specs=nosys.specs`
7. **加入 print-config 目标**：打印 CPU/FPU/LDSCRIPT/SRCS，便于排错。
8. **区分 Debug/Release**：
   - Debug: `-Og -g3`
   - Release: `-O2`（必要时 `-Os`）
9. **把 OpenOCD 命令也做成目标**：`flash`, `debug-server`, `reset`。

## 10. 模板仓库组织策略（复用重点）

推荐采用“**母模板 + 项目实例**”模式：

- 母模板仓库存放：
  - `Makefile`
  - `.vscode/*.json`
  - `openocd/*.cfg`
  - `docs/*.md`
  - `scripts/*.ps1`
- 新项目只替换：
  - 芯片型号、链接脚本、启动文件
  - CubeMX 生成代码
  - 板级 BSP

这样可以保证“工具链和流程”稳定复用，而不被某个项目业务代码污染。

## 11. 你当前最小可执行补齐清单（按优先级）

P0（立刻做）

1. 补全 `README.md`（构建/烧录/调试/CubeMX 再生成流程）
2. 固化 `.vscode/tasks.json` 和 `.vscode/launch.json`
3. 固化 `openocd/board.cfg`
4. 固化 `.gitignore`

P1（本周内）

1. 增加 `VERSION` + `CHANGELOG.md`
2. 增加 `docs/cubemx-regenerate.md`
3. 增加 `make print-config` 目标

P2（可选）

1. 自动打包脚本（hex/bin/map）
2. 基础静态检查（如 `cppcheck`）

---

如果你准备把这份模板直接落地，建议先按上面的 P0/P1 执行；几乎不增加复杂度，但能明显提升“长期可维护性”。
