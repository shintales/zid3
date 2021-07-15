const std = @import("std");
const ID3 = @import("zid3.zig").ID3;
const utils = @import("utils.zig");

/// The ID3v2 Tag header structure
pub const Header = struct {
    const Version = struct {
        major: u8,
        minor: u8,
    };
    id: [3]u8,
    version: Version,
    flags: u8,
    size: [4]u8,

    pub fn parseFromFile(file: *std.fs.File) !Header {
        var buffer: [10]u8 = undefined;
        _ = try file.read(buffer[0..10]);
        var header = Header{
            .id = buffer[0..3].*,
            .version = .{
                .major = buffer[3],
                .minor = buffer[4],
            },
            .flags = buffer[5],
            .size = buffer[6..10].*,
        };
        std.log.debug("{s}", .{buffer});
        return header;
    }
};

/// An optional structure that contains information that is not vital to the
/// correct parsing of the tag information
pub const ExtendedHeader = struct {
    size: [4]u8,
    flags: [2]u8,
    padding: [4]u8,

    pub fn parseFromID3(id3: *ID3) !?ExtendedHeader {
        if (utils.checkBit(u8, id3.header.flags, 0x40)) {
            var buffer: [10]u8 = undefined;
            _ = try id3.file.read(buffer[0..10]);
            var extended_header = ExtendedHeader{
                .size = buffer[0..4].*,
                .flags = buffer[4..6].*,
                .padding = buffer[6..10].*,
            };
            return extended_header;
        }
        return null;
    }
};
