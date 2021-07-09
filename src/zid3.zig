const std = @import("std");
const utils = @import("utils.zig");
usingnamespace @import("header.zig");
//usingnamespace @import("frames.zig");
usingnamespace @import("tags.zig");

pub const FrameHeader = struct {
    id: [4]u8,
    size: [4]u8,
    flags: [2]u8,
    content: []u8,
};

const TextFrameInformation = struct {
    encoding: u8,
    information: []u8,
};

pub const ID3 = struct {
    header: Header,
    frame_headers: std.ArrayList(FrameHeader),
    file: std.fs.File,
    allocator: *std.mem.Allocator,
    tags: Tags,
    const Self = @This();

    pub fn load(allocator: *std.mem.Allocator, filename: []const u8) !Self {
        var file = try std.fs.openFileAbsolute(filename, .{});
        defer file.close();

        var id3 = Self{
            .header = undefined,
            .frame_headers = std.ArrayList(FrameHeader).init(allocator),
            .file = file,
            .tags = undefined,
            .allocator = allocator,
        };

        id3.header = try parseHeader(&id3.file);
        id3.frame_headers = try id3.parseFrameHeaders();
        id3.tags = Tags.init(&id3.frame_headers);
        std.debug.print("ID: {s}\nSize: {}\nVersion: {s}\n", .{ id3.header.id, utils.bytesToInt(u32, &id3.header.size), id3.header.version });
        std.debug.print("File size: {}\n", .{id3.file.getEndPos()});

        return id3;
    }

    pub fn deinit(self: *Self) void {
        for (self.frame_headers.items) |frame_header| {
            self.allocator.free(frame_header.content);
        }
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

    fn parseFrameHeaders(self: *Self) !std.ArrayList(FrameHeader) {
        var frame_headers = std.ArrayList(FrameHeader).init(self.allocator);
        //const end_position = try self.file.getEndPos();
        const end_position = utils.bytesToInt(u24, &self.header.size);
        var current_position = try self.file.getPos();
        while (current_position < end_position) : (current_position = try self.file.getPos()) {
            const frame_header = try self.parseFrameHeader();
            if (frame_header != null)
                try frame_headers.append(frame_header.?);
        }
        return frame_headers;
    }

    fn parseFrameHeader(self: *Self) !?FrameHeader {
        var frame_header: [10]u8 = undefined;
        _ = try self.file.read(frame_header[0..10]);
        var id = frame_header[0..4].*;
        var size = frame_header[4..8].*;
        var flags = frame_header[8..10].*;

        const content = try self.allocator.alloc(u8, utils.bytesToInt(u32, &size));
        _ = try self.file.read(content);

        return switch (id[0]) {
            'T', 'W', 'C', 'A', 'P' => FrameHeader{
                .id = frame_header[0..4].*,
                .size = frame_header[4..8].*,
                .flags = frame_header[8..10].*,
                .content = content,
            },
            else => null,
        };
    }
};
