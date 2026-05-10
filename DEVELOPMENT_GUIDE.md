# 开发指南

## 工程快速开始
本工程目标器件为 `xc7vx690tffg1761-2`，原工程来自 Vivado 2018.3，当前发布版本已在 Vivado 2025.2 下完成 IP 升级检查，并通过 `synth_1` 项目模式综合冒烟测试。Windows 环境可直接使用：

```powershell
D:\AMD\2025.2\Vivado\bin\vivado.bat LPVX30_0040\LPVX30_0040.xpr
```

在 Vivado Tcl Console 中常用流程：

```tcl
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 8
launch_runs impl_1 -to_step write_bitstream -jobs 8
```

首次克隆后建议先打开工程，检查 IP Status；如 Vivado 提示重新生成 output products，按提示生成即可，不要提交 `.runs`、`.cache`、`.sim`、`.hw`、日志、波形数据库和 DCP 等生成物。
综合前置脚本会在缺少 `mig_7series_0.dcp` 时自动运行 `mig_7series_0_synth_1` 并准备 MIG checkpoint，因此首次综合耗时会更长。

## 目录导读
- `HDL/VX30_0040_TOP.V`：顶层模块 `LTVX30_0040_TOP`。
- `HDL/DEF/Gobal_define.vh`：项目级宏定义，包含器件类型、仿真开关、SRIO 配置等。
- `HDL/HDL_CMN`：通用 FIFO、AXI-Stream 转换、数据聚合等基础模块。
- `HDL/HDL_DMA`：PCIe DMA 相关封装和接口逻辑。
- `HDL/HDL_GT`：SRIO/GT 收发、链路和字符处理逻辑。
- `HDL/10G_ETH`：10G Ethernet、MAC、UDP/IP/ARP/ICMP 数据路径。
- `LPVX30_0040/LPVX30_0040.srcs/constrs_1/new`：顶层约束和时序约束。
- `LPVX30_0040/ip_patch`：综合/实现流程中调用的 Tcl hook 和 IP 补丁脚本。

## 学习路线
1. 先掌握 Verilog 基础、同步复位、跨时钟域、FIFO，以及 AXI-Stream 的 `valid/ready/last/keep` 握手。
2. 阅读 `HDL/DEF/Gobal_define.vh`，理解 SRIO、PCIe、以太网位宽、通道数和仿真宏。
3. 从 `HDL/HDL_CMN` 入手，熟悉本工程常用 FIFO 与 AXI-Stream 适配模块。
4. 跟踪 `HDL/10G_ETH` 中 ARP/IP/UDP/MAC 的收发路径。
5. 结合顶层实例化阅读 `HDL/HDL_DMA` 和 `HDL/HDL_GT`，理解 PCIe DMA 与 SRIO/GT 的连接关系。
6. 最后在 Vivado 中查看 IP、约束、综合报告和时序报告。

## 开发与验证建议
修改 RTL 后至少运行 Vivado 语法检查或 XSim 编译。涉及时钟、复位、GT、PCIe、SRIO、DDR 或约束的修改，应重新运行 `synth_1` 并检查 timing summary。新增测试平台放入 `HDL/TB`，建议命名为 `模块名_tb.v`。提交前确认没有加入 Vivado 生成目录、日志、波形数据库、本地备份和临时文件。

## Vivado 2025.2 迁移注意事项
当前 IP 状态为 Up-to-date，`synth_1` 已完成且 0 errors。仍需关注综合日志中的 Critical Warnings：`ten_gig_eth_pcs_pma_0_support.v` 内 `coreclk` 重复声明，以及 `clk_wiz_fast` 的 `reset` 管脚未连接。`axi_quad_spi_0` 升级时 Vivado 报告过地址块差异，后续联调 SPI 寄存器访问时应重点确认地址映射。

## 参考开源仓库
- [fpganinja/taxi](https://github.com/fpganinja/taxi)：AXI/AXIS、Ethernet、PCIe 组件库，可参考模块划分和测试组织。
- [corundum/corundum](https://github.com/corundum/corundum)：PCIe DMA 与多速率 Ethernet FPGA NIC 架构参考。
- [alexforencich/verilog-pcie](https://github.com/alexforencich/verilog-pcie)：PCIe、AXI、DMA 组件和 cocotb 测试结构参考。
- [analogdevicesinc/hdl](https://github.com/analogdevicesinc/hdl)：大型 Vivado/Quartus HDL 工程组织、Tcl 脚本和 IP 管理参考。
- [ZipCPU/wb2axip](https://github.com/ZipCPU/wb2axip)：AXI/Wishbone 总线、形式验证和高质量 RTL 风格参考。
