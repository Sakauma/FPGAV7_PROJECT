#pragma once

#include <ap_axi_sdata.h>
#include <ap_int.h>
#include <hls_stream.h>

typedef ap_axiu<64, 64, 0, 0> video_axis64_t;

void video_gray10_axis(hls::stream<video_axis64_t>& s_axis,
                       hls::stream<video_axis64_t>& m_axis);
