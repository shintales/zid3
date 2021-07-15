const std = @import("std");

/// Tag header structure
pub const Header = struct {
    const Version = struct {
        major: u8,
        minor: u8,
    };
    id: [3]u8,
    version: Version,
    flags: [1]u8,
    size: [4]u8,
};

pub const ExtendedHeader = struct {
    size: [4]u8,
    flags: [2]u8,
    padding: [4]u8,
};

pub fn parseHeader(file: *std.fs.File) !Header {
    //var header = try self.file.reader().readStruct(Header);

    var buffer: [10]u8 = undefined;
    _ = try file.read(buffer[0..10]);
    var header = Header{
        .id = buffer[0..3].*,
        //.version = buffer[3..5].*,
        .version = .{
            .major = buffer[3],
            .minor = buffer[4],
        },
        .flags = buffer[5..6].*,
        .size = buffer[6..10].*,
    };
    std.log.debug("{s}", .{buffer});
    return header;
}
