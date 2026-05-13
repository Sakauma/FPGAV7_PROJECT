#include "../src/video_gray10_axis.h"

#include <cstdint>
#include <iostream>

static uint16_t lane(uint64_t word, int index) {
    return static_cast<uint16_t>((word >> (index * 16)) & 0xffffu);
}

int main() {
    hls::stream<video_axis64_t> in;
    hls::stream<video_axis64_t> out;

    video_axis64_t sample;
    sample.data = (uint64_t(0x03ff << 6) << 48) |
                  (uint64_t(0x0200 << 6) << 32) |
                  (uint64_t(0x0001 << 6) << 16) |
                  uint64_t(0x0000 << 6);
    sample.keep = 0xff;
    sample.strb = 0xff;
    sample.user = 0x1234;
    sample.last = 1;
    in.write(sample);

    video_gray10_axis(in, out);
    video_axis64_t got = out.read();
    uint64_t got_word = got.data.to_uint64();

    if (lane(got_word, 0) != 0x0000 ||
        lane(got_word, 1) != 0x0001 ||
        lane(got_word, 2) != 0x0200 ||
        lane(got_word, 3) != 0x03ff ||
        got.keep != 0xff ||
        got.user != 0x1234 ||
        got.last != 1) {
        std::cerr << "video_gray10_axis conversion failed: 0x"
                  << std::hex << got_word << std::dec << "\n";
        return 1;
    }

    return 0;
}
