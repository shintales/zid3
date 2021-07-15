const std = @import("std");
const zid3 = @import("zid3.zig");

pub fn main() anyerror!void {
    const filename = "/home/shintales/GitRepositories/zid3/test.mp3";
    var id3 = try zid3.ID3.load(std.heap.page_allocator, filename);
    defer id3.deinit();

    std.debug.print("{s}\n", .{id3.getTitle()});
    std.debug.print("{s}\n", .{id3.getArtist()});

    try id3.save("out.mp3");
}
