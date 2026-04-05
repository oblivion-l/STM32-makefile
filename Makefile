# ==========================================================
# STM32H743 Makefile 模板（CubeMX + HAL + OpenOCD）
# 说明：
# - 默认支持 debug/release 两种配置
# - 目标：make / clean / rebuild / flash / size / list
# - 后续按板卡修改 MCU / DEVICE / LDSCRIPT / STARTUP / OPENOCD_CFG
# ==========================================================

# ---------- 工具链 ----------
PREFIX          ?= arm-none-eabi-
CC              := $(PREFIX)gcc
AS              := $(PREFIX)gcc
OBJCOPY         := $(PREFIX)objcopy
SIZE            := $(PREFIX)size
OPENOCD         ?= openocd

# ---------- 工程基本信息 ----------
TARGET          ?= $(notdir $(CURDIR))
CONFIG          ?= debug
BUILD_DIR       := build/$(CONFIG)
OBJ_DIR         := $(BUILD_DIR)/obj

# ---------- 芯片与板卡参数（按实际修改） ----------
MCU             ?= cortex-m7
FPU             ?= fpv5-d16
FLOAT_ABI       ?= hard
DEVICE          ?= STM32H743xx
LDSCRIPT        ?= linker/STM32H7xx/STM32H743xI.ld
STARTUP         ?= startup/startup_stm32h743xx.s
OPENOCD_CFG     ?= openocd/stm32h743.cfg

# ---------- 编译/链接公共参数 ----------
CPU_FLAGS       := -mcpu=$(MCU) -mthumb -mfpu=$(FPU) -mfloat-abi=$(FLOAT_ABI)
COMMON_WARN     := -Wall -Wextra -Wshadow -Wundef -Wdouble-promotion
COMMON_DEFS     := -DUSE_HAL_DRIVER -D$(DEVICE)
COMMON_OPTS     := -ffunction-sections -fdata-sections -fno-common -MMD -MP

# ---------- 配置差异 ----------
ifeq ($(CONFIG),release)
OPT_FLAGS       := -O2
DBG_FLAGS       := -g0
else
OPT_FLAGS       := -Og
DBG_FLAGS       := -g3
endif

CFLAGS          := $(CPU_FLAGS) $(COMMON_WARN) $(COMMON_DEFS) $(COMMON_OPTS) $(OPT_FLAGS) $(DBG_FLAGS) -std=c11
ASFLAGS         := $(CPU_FLAGS) $(DBG_FLAGS) -x assembler-with-cpp
LDFLAGS         := $(CPU_FLAGS) -T$(LDSCRIPT) -Wl,-Map=$(BUILD_DIR)/$(TARGET).map -Wl,--gc-sections -nostartfiles --specs=nano.specs --specs=nosys.specs

# ---------- 路径自动适配（对齐 CubeMX 常见目录） ----------
# 仅保留仓库中已存在的目录，避免 include/source 路径失效。
CANDIDATE_SRC_DIRS := src Core/Src Drivers/STM32H7xx_HAL_Driver/Src
CANDIDATE_INC_DIRS := inc Core/Inc \
                      Drivers/CMSIS/Include \
                      Drivers/CMSIS/Device/ST/STM32H7xx/Include \
                      Drivers/STM32H7xx_HAL_Driver/Inc \
                      Drivers/STM32H7xx_HAL_Driver/Inc/Legacy

SRC_DIRS        := $(foreach d,$(CANDIDATE_SRC_DIRS),$(if $(wildcard $(d)),$(d),))
INC_DIRS        := $(foreach d,$(CANDIDATE_INC_DIRS),$(if $(wildcard $(d)),$(d),))

# ---------- 自动收集源文件 ----------
C_SRCS          := $(foreach d,$(SRC_DIRS),$(wildcard $(d)/*.c))
ASM_SRCS        := $(STARTUP)

# 若使用 HAL，通常要剔除模板文件（如有）
C_SRCS          := $(filter-out %/templates/%.c,$(C_SRCS))

# ---------- 派生变量 ----------
INCLUDES        := $(addprefix -I,$(INC_DIRS))
C_OBJS          := $(patsubst %.c,$(OBJ_DIR)/%.o,$(C_SRCS))
ASM_OBJS        := $(patsubst %.s,$(OBJ_DIR)/%.o,$(ASM_SRCS))
OBJS            := $(C_OBJS) $(ASM_OBJS)
DEPS            := $(OBJS:.o=.d)

ELF             := $(BUILD_DIR)/$(TARGET).elf
HEX             := $(BUILD_DIR)/$(TARGET).hex
BIN             := $(BUILD_DIR)/$(TARGET).bin

# ==========================================================
# 默认目标
# ==========================================================
.PHONY: all
all: precheck $(ELF) $(HEX) $(BIN)

# ==========================================================
# 预检查
# ==========================================================
.PHONY: precheck
precheck:
	@command -v $(CC) >/dev/null 2>&1 || (echo "[ERROR] 未找到编译器 $(CC)" && \
	echo "        请先安装 ARM GNU Toolchain，并确认 $(CC) 在 PATH 中。" && \
	echo "        Windows 常用命令验证：arm-none-eabi-gcc --version" && exit 1)
	@test -f $(LDSCRIPT) || (echo "[ERROR] 未找到链接脚本: $(LDSCRIPT)" && \
	echo "        请在 Makefile 中修改 LDSCRIPT，或确认 CubeMX 已生成/拷贝该 .ld 文件。" && exit 1)
	@test -f $(STARTUP) || (echo "[ERROR] 未找到启动文件: $(STARTUP)" && \
	echo "        这是首次使用最常见问题：请先用 CubeMX/CMSIS 真实 startup 文件替换模板占位文件。" && exit 1)
	@test -f $(OPENOCD_CFG) || (echo "[WARN ] 未找到 OpenOCD 配置: $(OPENOCD_CFG)" && \
	echo "        构建可继续，但 flash/debug 会失败；请按板卡修正 OPENOCD_CFG。" && exit 0)

# ==========================================================
# 构建规则
# ==========================================================
$(OBJ_DIR)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

$(OBJ_DIR)/%.o: %.s
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) $(INCLUDES) -c $< -o $@

$(ELF): $(OBJS)
	@mkdir -p $(BUILD_DIR)
	$(CC) $(OBJS) $(LDFLAGS) -o $@

$(HEX): $(ELF)
	$(OBJCOPY) -O ihex $< $@

$(BIN): $(ELF)
	$(OBJCOPY) -O binary $< $@

# ==========================================================
# 功能目标
# ==========================================================
.PHONY: clean
clean:
	rm -rf build

.PHONY: rebuild
rebuild: clean all

.PHONY: flash
flash: $(ELF)
	@command -v $(OPENOCD) >/dev/null 2>&1 || (echo "[ERROR] 未找到 OpenOCD 可执行文件: $(OPENOCD)" && \
	echo "        请先安装 OpenOCD，并确认命令可执行。" && exit 1)
	$(OPENOCD) -f $(OPENOCD_CFG) -c "program $(ELF) verify reset exit"

.PHONY: size
size: $(ELF)
	$(SIZE) $(ELF)

.PHONY: list
list:
	@echo "===== 构建配置 ====="
	@echo "TARGET      = $(TARGET)"
	@echo "CONFIG      = $(CONFIG)"
	@echo "DEVICE      = $(DEVICE)"
	@echo "LDSCRIPT    = $(LDSCRIPT)"
	@echo "STARTUP     = $(STARTUP)"
	@echo "OPENOCD_CFG = $(OPENOCD_CFG)"
	@echo ""
	@echo "===== 已存在的源码目录 ====="
	@$(foreach s,$(SRC_DIRS),echo $(s);)
	@echo ""
	@echo "===== 已存在的头文件目录 ====="
	@$(foreach i,$(INC_DIRS),echo $(i);)
	@echo ""
	@echo "===== C 源文件 ====="
	@$(foreach s,$(C_SRCS),echo $(s);)
	@echo ""
	@echo "===== 汇编源文件 ====="
	@$(foreach s,$(ASM_SRCS),echo $(s);)

.PHONY: debug
# 语义化入口：make debug 等价于 make CONFIG=debug
debug:
	$(MAKE) CONFIG=debug all

.PHONY: release
# 语义化入口：make release 等价于 make CONFIG=release
release:
	$(MAKE) CONFIG=release all

# 包含自动生成依赖
-include $(DEPS)
