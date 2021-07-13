const std = @import("std");
const utils = @import("utils.zig");
usingnamespace @import("header.zig");
usingnamespace @import("frames.zig");

pub const ID3 = struct {
    header: Header,
    frame_headers: FrameHeaderList,
    file: std.fs.File,
    allocator: *std.mem.Allocator,
    const Self = @This();

    pub fn load(allocator: *std.mem.Allocator, filename: []const u8) !Self {
        var file = try std.fs.openFileAbsolute(filename, .{});
        defer file.close();

        var id3 = Self{
            .header = undefined,
            .frame_headers = undefined,
            .file = file,
            .allocator = allocator,
        };

        id3.header = try parseHeader(&id3.file);
        id3.frame_headers = try FrameHeaderList.parseFromID3(&id3);
        std.debug.print("ID: {s}\nSize: {}\nVersion: {s}\n", .{ id3.header.id, utils.bytesToInt(u32, &id3.header.size), id3.header.version });
        std.debug.print("File size: {}\n", .{id3.file.getEndPos()});

        return id3;
    }

    pub fn deinit(self: *Self) void {
        self.frame_headers.deinit();
    }

    pub fn save(self: *Self, filename: []const u8) !void {
        var output: [100]u8 = undefined;
        _ = try std.fmt.bufPrint(&output, "/home/shintales/GitRepositories/zid3/{s}", .{filename});
        var file = try std.fs.createFileAbsolute(&output, .{});
        defer file.close();

        try file.writeAll(std.mem.asBytes(&self.header));
        for (self.frame_headers.inner_list.items) |frame_header| {
            try file.writeAll(std.mem.asBytes(&frame_header));
        }
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

    // Handle tag information retriveal
    pub fn getTitle(self: *Self) []u8 {
        return self.getTagInformation("TIT2");
    }

    pub fn getArtist(self: *Self) []u8 {
        return self.getTagInformation("TPE1");
    }

    pub fn getAlbum(self: *Self) []u8 {
        return self.getTagInformation("TALB");
    }
    pub fn getAlbumArtist(self: *Self) []u8 {
        return self.getTagInformation("TPE2");
    }
    pub fn getGenre(self: *Self) []u8 {
        return self.getTagInformation("TCON");
    }
    pub fn getTrack_num(self: *Self) []u8 {
        return self.getTagInformation("TRCK");
    }
    pub fn getYear(self: *Self) []u8 {
        return self.getTagInformation("TYER");
    }

    fn getTagInformation(self: *Self, id: []const u8) []u8 {
        for (self.frame_headers.inner_list.items) |frame_header| {
            if (std.mem.eql(u8, frame_header.id[0..], id)) {
                if (frame_header.getTextFrame().encoding == 1)
                    return frame_header.getTextFrame().information[2..];
                return frame_header.getTextFrame().information;
            }
        }
        return undefined;
    }

    // Handle tag information setting
    pub fn setTitle(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TIT2", input);
    }

    pub fn setArtist(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TPE1", input);
    }

    pub fn setAlbum(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TALB", input);
    }
    pub fn setAlbumArtist(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TPE2", input);
    }
    pub fn setGenre(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TCON", input);
    }
    pub fn setTrackNum(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TRCK", input);
    }
    pub fn setYear(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TYER", input);
    }
    fn setTagInformation(self: *Self, id: []const u8, input: []const u8) !void {
        for (self.frame_headers.inner_list.items) |_, loc| {
            var frame_header = &self.frame_headers.inner_list.items[loc];
            if (std.mem.eql(u8, frame_header.id[0..], id)) {
                var preserve = switch (frame_header.getTextFrame().encoding) {
                    0 => frame_header.content[0..1],
                    1 => frame_header.content[0..3],
                    else => unreachable,
                };
                frame_header.content = try self.allocator.realloc(frame_header.content, input.len + preserve.len);
                var i: u8 = 0;
                for (preserve) |char| {
                    frame_header.content[i] = char;
                    i += 1;
                }
                for (input) |char| {
                    frame_header.content[i] = char;
                    i += 1;
                }
                break;
            }
        }
    }
};
