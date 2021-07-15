const std = @import("std");
const utils = @import("utils.zig");
const ID3 = @import("zid3.zig").ID3;

const FrameTypes = union {
    text: TextFrame,
    link: UrlLinkFrame,
    comment: CommentFrame,
};

pub const FrameHeader = struct {
    id: [4]u8,
    size: [4]u8,
    flags: [2]u8,
    content: []u8,
    const Self = @This();

    fn parseFromID3(id3: *ID3) !?FrameHeader {
        var frame_header: [10]u8 = undefined;
        _ = try id3.file.read(frame_header[0..10]);
        var id = frame_header[0..4].*;
        var size = frame_header[4..8].*;
        var flags = frame_header[8..10].*;

        const content = try id3.allocator.alloc(u8, utils.bytesToInt(u32, &size));
        _ = try id3.file.read(content);

        return switch (id[0]) {
            'T', 'W', 'C', 'A', 'P' => FrameHeader{
                .id = id,
                .size = size,
                .flags = flags,
                .content = content,
            },
            else => null,
        };
    }

    pub fn getTextFrame(self: *const Self) TextFrame {
        return .{
            .encoding = self.content[0],
            .information = self.content[1..],
        };
    }

    pub fn getFrame(self: *const Self) FrameTypes {
        return switch (self.id[0]) {
            'T' => getTextFrame(),
            else => unreachable,
        };
    }
};

pub const FrameHeaderList = struct {
    allocator: *std.mem.Allocator,
    inner_list: std.ArrayList(FrameHeader),
    const Self = @This();

    pub fn init(allocator: *std.mem.Allocator) FrameHeaderList {
        return .{
            .allocator = allocator,
            .inner_list = std.ArrayList(FrameHeader).init(allocator),
        };
    }

    pub fn parseFromID3(id3: *ID3) !FrameHeaderList {
        var frame_headers = FrameHeaderList.init(id3.allocator);
        const end_position = utils.bytesToInt(u24, &id3.header.size);
        var current_position = try id3.file.getPos();
        while (current_position < end_position) : (current_position = try id3.file.getPos()) {
            const frame_header = try FrameHeader.parseFromID3(id3);
            if (frame_header != null)
                try frame_headers.inner_list.append(frame_header.?);
        }
        return frame_headers;
    }

    pub fn deinit(self: *Self) void {
        for (self.inner_list.items) |frame_header| {
            self.allocator.free(frame_header.content);
        }
        self.inner_list.deinit();
    }
};

const TextFrame = struct {
    encoding: u8,
    information: []u8,
};

const UrlLinkFrame = struct { url: []u8 };

const CommentFrame = struct {
    encoding: u8,
    language: [3]u8,
    //Short content descrip.  <text string according to encoding> $00 (00)
    description: []u8,
    //The actual text         <full text string according to encoding>
    text: []u8,
};

const PictureFrame = struct {
    encoding: u8,
    mime_type: []u8,
    picture_type: u8,
    description: []u8,
    picture_data: []u8,
};
