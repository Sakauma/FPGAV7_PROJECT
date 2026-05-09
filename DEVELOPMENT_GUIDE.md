# 开发指南

## 工程快速开始
本工程使用 Vivado 2018.3，目标器件为 `xc7vx690tffg1761-2`。克隆仓库后，直接用 Vivado 打开 `LPVX30_0040/LPVX30_0040.xpr`。首次打开后先检查 IP 状态，再运行 `update_compile_order`，确认源文件顺序无缺失。

常用流程：

```tcl
open_project LPVX30_0040/LPVX30_0040.xpr
update_compile_order -fileset sources_1
launch_runs synth_1 -jobs 8
launch_runs impl_1 -to_step write_bitstream -jobs 8
```

仿真入口在 `HDL/TB/convertb.v`，波形配置为 `HDL/TB/convertb_behav.wcfg`。如果重新导出 XSim 脚本，请不要提交生成的 `.sim`、`.wdb`、日志和 Vivado 缓存目录。

## 目录导读
- `HDL/VX30_0040_TOP.V`：顶层模块 `LTVX30_0040_TOP`。
- `HDL/DEF/Gobal_define.vh`：项目级宏定义，新增全局配置优先放在这里。
- `HDL/HDL_CMN`：通用 FIFO、AXI-Stream 转换、数据聚合等基础模块。
- `HDL/HDL_DMA`：PCIe DMA 相关封装和接口逻辑。
- `HDL/HDL_GT`：SRIO/GT 收发、解码和链路相关逻辑。
- `HDL/10G_ETH`：10G Ethernet、MAC、UDP/IP/ARP/ICMP 数据路径。
- `LPVX30_0040/LPVX30_0040.srcs/constrs_1/new`：顶层约束和时序约束。
- `LPVX30_0040/ip_patch`：工程综合/实现步骤中引用的 Tcl hook 和补丁脚本。

## 学习路线
1. 先掌握 Verilog 基础、同步复位、跨时钟域、FIFO 和 AXI-Stream 的 `valid/ready/last/keep` 握手。
2. 阅读 `HDL/DEF/Gobal_define.vh`，理解 SRIO、PCIe、以太网位宽和通道数等全局参数。
3. 从 `HDL/HDL_CMN` 入手，理解本工程常用 FIFO 与 AXI-Stream 适配模块。
4. 再看 `HDL/10G_ETH` 的协议分层，按 ARP/IP/UDP/MAC 的数据流追踪收发路径。
5. 阅读 `HDL/HDL_DMA` 和 `HDL/HDL_GT`，结合顶层实例化理解 PCIe DMA 与 SRIO/GT 的连接关系。
6. 最后打开 Vivado 工程查看 IP、约束、时序报告和综合实现结果。

## 开发与提交建议
修改 RTL 后至少运行 Vivado 语法检查或 XSim 编译。涉及时钟、复位、GT、PCIe、SRIO 或约束的修改，必须重新综合并检查 timing summary。新增测试平台放入 `HDL/TB`，命名建议使用 `模块名_tb.v`。

提交前确认没有加入以下内容：`LPVX30_0040.cache`、`LPVX30_0040.runs`、`LPVX30_0040.sim`、`LPVX30_0040.hw`、`.Xil`、日志、波形数据库和本地备份文件。

## 参考开源仓库
- [fpganinja/taxi](https://github.com/fpganinja/taxi)：现代 AXI/AXIS、Ethernet、PCIe 组件库，可参考模块划分和测试组织。
- [corundum/corundum](https://github.com/corundum/corundum)：PCIe DMA 与多速率 Ethernet FPGA NIC 架构参考。
- [alexforencich/verilog-pcie](https://github.com/alexforencich/verilog-pcie)：PCIe、AXI、DMA 组件和 cocotb 测试结构参考。
- [analogdevicesinc/hdl](https://github.com/analogdevicesinc/hdl)：大型 Vivado/Quartus HDL 工程组织、Tcl 脚本和 IP 管理参考。
- [ZipCPU/wb2axip](https://github.com/ZipCPU/wb2axip)：AXI/Wishbone 总线、形式验证和高质量 RTL 风格参考。
