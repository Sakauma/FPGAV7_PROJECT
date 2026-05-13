#include "video_gray10_axis.h"

static ap_uint<16> raw16_to_gray10(ap_uint<16> pix16) {
#pragma HLS inline
    ap_uint<16> shifted = pix16 >> 6;
    return shifted.range(9, 0);
}

void video_gray10_axis(hls::stream<video_axis64_t>& s_axis,
                       hls::stream<video_axis64_t>& m_axis) {
#pragma HLS interface axis port=s_axis
#pragma HLS interface axis port=m_axis
#pragma HLS interface ap_ctrl_none port=return
#pragma HLS pipeline II=1

    video_axis64_t in = s_axis.read();
    video_axis64_t out = in;

    ap_uint<64> data = in.data;
    ap_uint<64> converted = 0;
    converted.range(15, 0) = raw16_to_gray10(data.range(15, 0));
    converted.range(31, 16) = raw16_to_gray10(data.range(31, 16));
    converted.range(47, 32) = raw16_to_gray10(data.range(47, 32));
    converted.range(63, 48) = raw16_to_gray10(data.range(63, 48));

    out.data = converted;
    m_axis.write(out);
}
