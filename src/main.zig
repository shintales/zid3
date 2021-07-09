const std = @import("std");
const zid3 = @import("zid3.zig");

pub fn main() anyerror!void {
    const filename = "/home/shintales/GitRepositories/zid3/test.mp3";
    var id3 = try zid3.ID3.load(std.heap.page_allocator, filename);
    defer id3.deinit();

    for (id3.frame_headers.items) |frame_header| {
        //std.debug.print("{s}\n", .{frame_header.id});
        std.debug.print("{s}: {s}\n", .{ frame_header.id, frame_header.content });
    }
    //const frame_header = id3.frame_headers.items[22];
    std.debug.print("{s}\n", .{id3.tags.artist});
}
