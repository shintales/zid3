pub fn bytesToInt(comptime T: type, bytes: []const u8) T {
    var result: T = 0x00;
    var i: usize = 0;
    while (i < bytes.len) : (i += 1) {
        result = result << 8;
        result = result | bytes[i];
    }
    return result;
}

pub fn checkBit(comptime T: type, value: T, bit_to_check: T) bool {
    return (value & bit_to_check) == bit_to_check;
}
