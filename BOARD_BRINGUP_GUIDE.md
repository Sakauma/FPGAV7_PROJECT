# FPGA + RK3588 上板调试流程

本文用于把当前 FPGA 工程和 RK3588 工程联动起来：FPGA 生成或接收视频数据，按原工程数据链路完成处理后，经 PCIe DMA 输出 `gray10le16`，RK3588 接收、组帧、编码并保存 H.265 裸码流。

## 当前默认状态

- Vivado 版本：2025.2，已完成过仿真、综合、实现和 bitstream 生成。
- FPGA 顶层：`HDL/VX30_0040_TOP.V`，`VIDEO_TEST_PATTERN_ENABLE=1`，默认使用内部伪视频源。
- 输出格式：`1920x1080 gray10le16`，每像素 16bit little-endian 容器，低 10bit 有效。
- FPGA 视频 DMA 参数：`VIDEO_DMA_CH=1`。
- 当前 bitstream：`LPVX30_0040/LPVX30_0040.runs/impl_1/LTVX30_0040_TOP.bit`。

## FPGA 侧操作

先用脚本打开 Vivado，避免带空格的用户目录导致 IP OOC 综合报 `[Common 17-1257] Failed to create directory 'C'`：

```bat
D:\Staff\test\LTVX30_0040\_publish\FPGAV7_PROJECT\tools\open_vivado_2025.bat
```

如果首次使用，建议先永久设置一次环境变量，然后关闭并重新打开 Vivado：

```bat
D:\Staff\test\LTVX30_0040\_publish\FPGAV7_PROJECT\tools\setup_vivado_user_data.bat
```

Vivado GUI 中依次执行 `Run Synthesis`、`Run Implementation`、`Generate Bitstream`。也可在 Tcl Console 执行：

```tcl
launch_runs synth_1 -jobs 8
wait_on_run synth_1
launch_runs impl_1 -to_step write_bitstream -jobs 8
wait_on_run impl_1
```

烧录时打开 `Open Hardware Manager`，执行 `Open Target -> Auto Connect`，选择 FPGA device，`Program Device`，bit 文件选择：

```text
LPVX30_0040/LPVX30_0040.runs/impl_1/LTVX30_0040_TOP.bit
```

如果 JTAG 无设备，先确认板卡供电、JTAG 模式和线缆驱动，再在 Vivado Tcl Console 执行：

```tcl
disconnect_hw_server
connect_hw_server
open_hw_target
refresh_hw_device
```

## RK3588 侧操作

通过 SSH 登录板端：

```powershell
ssh root@192.168.1.100
```

拉取或更新工程：

```bash
cd /root
git clone https://github.com/Sakauma/RK3588_PROJECT.git || true
cd /root/RK3588_PROJECT
git pull
```

加载 PCIe SDK 驱动：

```bash
insmod /root/RK3588_PROJECT/cvgDrv.ko || true
lsmod | grep cvg
```

编译 RK3588 程序：

```bash
cd /root/RK3588_PROJECT
cmake -S WinSim -B build-rk3588 \
  -DRK3588API_INCLUDE_DIR=/root/RK3588_PROJECT/RK3588API \
  -DRK3588API_LIBRARY=/root/RK3588_PROJECT/libRK3588.so
cmake --build build-rk3588 -j2
```

先跑离线编码测试，确认 MPP 和输出文件链路可用：

```bash
./build-rk3588/offline_encode_test 1920 1080 /tmp/offline_gray10.h265 60 gray10le16
ls -lh /tmp/offline_gray10.h265
```

确认 `rk3588.ini` 的关键字段：

```ini
UP_LOOP_DMA_CHANNUM=5
FRAME_WIDTH=1920
FRAME_HEIGHT=1080
INPUT_PIXEL_FORMAT=gray10le16
VIDEO_CODEC=h265
VIDEO_OUTPUT_PATH=/tmp/rk3588_capture.h265
RAW16_MAP_MODE=window
RAW16_BLACK_LEVEL=0
RAW16_WHITE_LEVEL=1023
OSD_MODE=burned-in
OSD_ENABLE=0
```

## 联动调试顺序

1. 关闭或准备重启 RK3588。
2. FPGA 上电并通过 JTAG 烧录 `LTVX30_0040_TOP.bit`。
3. 启动或重启 RK3588，让 PCIe host 枚举 FPGA endpoint。
4. RK3588 登录后检查 PCIe 和驱动日志：

```bash
lspci -nn
dmesg | grep -Ei "pcie|cvg|dma|xilinx"
```

5. 启动主程序：

```bash
cd /root/RK3588_PROJECT
./build-rk3588/RK3588Test
```

6. 观察程序日志，确认 `packets`、`frames`、`encoded` 持续增长。
7. 检查输出文件：

```bash
ls -lh /tmp/rk3588_capture.h265
```

8. 拷回 Windows 播放：

```powershell
scp root@192.168.1.100:/tmp/rk3588_capture.h265 .
ffplay -f hevc rk3588_capture.h265
```

## 异常判断

- RK3588 没有 PCIe 设备：先重启 RK3588；仍无设备则检查 FPGA bit 是否已烧录、PCIe reset、PCIe 时钟和供电。
- PCIe 设备存在但无回调数据：优先检查 `UP_LOOP_DMA_CHANNUM`。当前 RK 默认是 `5`，FPGA 内部视频参数是 `VIDEO_DMA_CH=1`，无数据时可依次试 `5`、`1`。
- 有 `frames` 但 `encoded` 不增长：先跑 `offline_encode_test`，确认 MPP 可用。
- 输出文件存在但播放异常：确认按裸 H.265 播放，命令为 `ffplay -f hevc rk3588_capture.h265`。

## 验收标准

- Vivado 显示 `write_bitstream Complete!`。
- RK3588 `lspci` 能看到 FPGA PCIe endpoint。
- RK3588 主程序中 `packets`、`frames`、`encoded` 持续增长。
- `/tmp/rk3588_capture.h265` 文件大小持续增加。
- 文件拷回 Windows 后可用 `ffplay -f hevc` 播放。
