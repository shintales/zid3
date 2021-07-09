const std = @import("std");
const utils = @import("utils.zig");
usingnamespace @import("header.zig");
usingnamespace @import("frames.zig");
usingnamespace @import("tags.zig");

pub const ID3 = struct {
    header: Header,
    frame_headers: FrameHeaderList,
    file: std.fs.File,
    allocator: *std.mem.Allocator,
    tags: Tags,
    const Self = @This();

    pub fn load(allocator: *std.mem.Allocator, filename: []const u8) !Self {
        var file = try std.fs.openFileAbsolute(filename, .{});
        defer file.close();

        var id3 = Self{
            .header = undefined,
            .frame_headers = undefined,
            .file = file,
            .tags = undefined,
            .allocator = allocator,
        };

        id3.header = try parseHeader(&id3.file);
        id3.frame_headers = try FrameHeaderList.parseFromID3(&id3);
        id3.tags = Tags.init(&id3.frame_headers);
        std.debug.print("ID: {s}\nSize: {}\nVersion: {s}\n", .{ id3.header.id, utils.bytesToInt(u32, &id3.header.size), id3.header.version });
        std.debug.print("File size: {}\n", .{id3.file.getEndPos()});

        return id3;
    }

    pub fn deinit(self: *Self) void {
        self.frame_headers.deinit();
    }

    pub fn xxformat(
        self: Self,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        try writer.print("ID: {s}\nVersion: {s}\n Flags: {s}\nSize: {s}", .{
            self.header.id,
            self.header.version,
            self.header.flags,
            self.header.size,
        });
    }
};
