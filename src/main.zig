const std = @import("std");
const zid3 = @import("zid3.zig");

pub fn main() anyerror!void {
    const filename = "/home/shintales/GitRepositories/zid3/test.mp3";
    var id3 = try zid3.ID3.load(std.heap.page_allocator, filename);
    defer id3.deinit();

    for (id3.frame_headers.inner_list.items) |frame_header| {
        //std.debug.print("{s}\n", .{frame_header.id});
        std.debug.print("{s}: {s}\n", .{ frame_header.id, frame_header.content });
        std.debug.print("{}\n", .{frame_header.getTextFrame()});
    }
    var frame_header = id3.frame_headers.inner_list.items[2];
    std.debug.print("{s}\n", .{frame_header.getTextFrame().information});
    try id3.setTitle("Modify");
    std.debug.print("{s}\n", .{id3.getTitle()});
    std.debug.print("{s}\n", .{id3.getArtist()});

    try id3.save("out.mp3");
}
