# video_gray10_axis HLS 算法岛

本目录只承载视频算法层，不承载 PCIe、DMA、SRIO 或 RK3588 SDK 通信协议。

## 边界

- 输入：原工程已经提取出的 64-bit AXI4-Stream 视频 payload。
- 输出：同样宽度和边界的 AXI4-Stream payload。
- 保持：`keep`、`strb`、`user`、`last` 原样透传。
- 当前算法：每个 16-bit 像素执行 `pix10 = pix16 >> 6`，并放回 16-bit 容器的低 10bit。

## 使用方式

Vivado/Vitis 2025.2 推荐使用 `vitis-run`：

```powershell
D:\AMD\2025.2\Vitis\bin\vitis-run.bat --mode hls --csim --config hls_config.cfg --work_dir video_gray10_axis_prj
```

HLS 综合使用 Tcl 流：

```tcl
D:\AMD\2025.2\Vitis\bin\vitis-run.bat --mode hls --tcl --input_file run_hls.tcl
```

生成 RTL/IP 后，只允许通过独立 wrapper 接入原工程已经稳定的 payload 位置。不要在 HLS 模块中解析或生成 PCIe DMA 包头、`sp_cond_up` 描述头、SRIO 包头或 RK3588 自定义头。

## 后续算法

拼接、特征点提取、平移估计和融合应在本算法岛内迭代。底层链路保持原工程实现，避免重新定义传输格式和长度。
