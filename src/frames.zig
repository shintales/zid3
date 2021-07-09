const std = @import("std");
const utils = @import("utils.zig");
const ID3 = @import("zid3.zig").ID3;

pub const FrameHeader = struct {
    id: [4]u8,
    size: [4]u8,
    flags: [2]u8,
    content: []u8,
};

pub const FrameHeaderList = struct {
    allocator: *std.mem.Allocator,
    inner_list: std.ArrayList(FrameHeader),

    pub fn init(allocator: *std.mem.Allocator) FrameHeaderList {
        return .{
            .allocator = allocator,
            .inner_list = std.ArrayList(FrameHeader).init(allocator),
        };
    }

    pub fn deinit(self: *Self) void {
        for (self.inner_list.items) |frame_header| {
            self.allocator.free(frame_header.content);
        }
        self.inner_list.deinit();
    }
};

const TextFrameInformation = struct {
    encoding: u8,
    information: []u8,
};

fn parseFrameHeaders(self: *ID3) !FrameHeaderList {
    var frame_headers = FrameHeaderList.init(self.allocator);
    //const end_position = try self.file.getEndPos();
    const end_position = utils.bytesToInt(u24, &self.header.size);
    var current_position = try self.file.getPos();
    while (current_position < end_position) : (current_position = try self.file.getPos()) {
        const frame_header = try parseFrameHeader();
        if (frame_header != null)
            try frame_headers.inner_list.append(frame_header.?);
    }
    return frame_headers;
}

fn parseFrameHeader(self: *ID3) !?FrameHeader {
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
