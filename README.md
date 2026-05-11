# FPGAV7_PROJECT

这是一个面向 Xilinx Virtex-7 `xc7vx690tffg1761-2` 的 Vivado FPGA 工程。原工程来自 Vivado 2018.3，当前仓库版本已升级并在 Vivado 2025.2 下完成综合验证。

## 工程内容

- 顶层 RTL：`HDL/VX30_0040_TOP.V`
- 顶层模块：`LTVX30_0040_TOP`
- 全局宏定义：`HDL/DEF/Gobal_define.vh`
- Vivado 工程：`LPVX30_0040/LPVX30_0040.xpr`
- 约束文件：`LPVX30_0040/LPVX30_0040.srcs/constrs_1/new`
- 测试平台：`HDL/TB`
- 开发指南：`DEVELOPMENT_GUIDE.md`

主要功能模块包括 10G Ethernet、PCIe DMA、SRIO/GT、DDR/MIG、SPI、AXI/AXI-Stream 相关数据通路和调试 IP。

## 环境要求

推荐使用 Vivado 2025.2。已验证的本地 Vivado 路径为：

```powershell
D:\AMD\2025.2\Vivado\bin\vivado.bat
```

其他机器可按实际安装路径替换 Vivado 可执行文件位置。

首次使用建议先运行一次：

```powershell
tools\setup_vivado_user_data.bat
```

该命令会把 `XILINX_LOCAL_USER_DATA` 持久设置到无空格路径，避免 OOC IP 综合时出现 `[Common 17-1257] Failed to create directory 'C'`。运行后请关闭并重新打开 Vivado。

## 快速开始

克隆仓库后，打开 Vivado 工程：

```powershell
tools\open_vivado_2025.bat
```

该脚本也会在当前会话中设置 `XILINX_LOCAL_USER_DATA`。如果 Vivado 不在默认路径，请先设置：

```powershell
$env:VIVADO_2025_BAT="D:\AMD\2025.2\Vivado\bin\vivado.bat"
tools\open_vivado_2025.bat
```

在 Vivado Tcl Console 中更新编译顺序并运行综合：

```tcl
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 8
```

生成 bitstream：

```tcl
launch_runs impl_1 -to_step write_bitstream -jobs 8
```

首次打开时，如果 Vivado 提示重新生成 IP output products，按提示生成即可。
`synth_1` 的前置脚本会在缺少 MIG/PCIe/SRIO output products 或 checkpoint 时自动重新生成相关 IP，并运行对应 OOC 综合准备 DCP，首次综合会比后续综合更久。
如果已经直接打开了 Vivado，也可以先在 Tcl Console 中执行 `source tools/setup_vivado_user_data.tcl`，再启动综合。

## 当前验证状态

已在干净克隆目录中使用 Vivado 2025.2 验证：

- IP 状态已升级到当前 Vivado 版本
- `synth_1` 综合完成
- 综合结果为 `0 Errors`

仍需关注综合日志中的 Critical Warnings：

- `ten_gig_eth_pcs_pma_0_support.v` 中 `coreclk` 重复声明
- `clk_wiz_fast` 的 `reset` 管脚未连接
- `axi_quad_spi_0` 升级时出现过地址块差异提示，联调 SPI 寄存器访问时应复核地址映射

当前仓库尚未验证完整 implementation、timing closure 和 bitstream 上板结果。

## 仓库维护约定

一般不要提交 Vivado 生成目录和中间产物，例如：

- `.Xil`
- `*.cache`
- `*.runs`
- `*.sim`
- `*.hw`
- `*.ip_user_files`
- `*.log`
- `*.jou`
- `*.dcp`
- 仿真波形和本地备份文件

本仓库已跟踪少量综合前置补丁依赖的 IP 产物，包括 MIG、PCIe 和 SRIO 的必要 DCP、RTL 与补丁备份文件。不要删除这些已跟踪文件；新增其他生成物前应确认它们是否为首次综合必需。

更多工程结构、学习路线和参考开源仓库见 `DEVELOPMENT_GUIDE.md`。
