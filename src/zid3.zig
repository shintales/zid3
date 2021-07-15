const std = @import("std");
const utils = @import("utils.zig");
usingnamespace @import("header.zig");
usingnamespace @import("frames.zig");

pub const ID3 = struct {
    header: Header,
    extended_header: ?ExtendedHeader,
    frame_headers: FrameHeaderList,
    file: std.fs.File,
    allocator: *std.mem.Allocator,
    const Self = @This();

    /// Load the contents of an mp3 file into the ID3 struct
    pub fn load(allocator: *std.mem.Allocator, filename: []const u8) !Self {
        var file = try std.fs.openFileAbsolute(filename, .{});
        defer file.close();

        var id3 = Self{
            .header = undefined,
            .extended_header = null,
            .frame_headers = undefined,
            .file = file,
            .allocator = allocator,
        };

        id3.header = try Header.parseFromFile(&id3.file);
        id3.extended_header = try ExtendedHeader.parseFromID3(&id3);
        id3.frame_headers = try FrameHeaderList.parseFromID3(&id3);
        std.debug.print("ID: {s}\nSize: {}\nVersion: {s}\n", .{ id3.header.id, utils.bytesToInt(u32, &id3.header.size), id3.header.version });
        std.debug.print("File size: {}\n", .{id3.file.getEndPos()});

        return id3;
    }

    pub fn deinit(self: *Self) void {
        self.frame_headers.deinit();
    }

    /// Save ID3 information to file 
    /// [TODO] The saved file is corrupted and not in proper format. Need to figure
    /// out how to write frames that have encoding.
    pub fn save(self: *Self, filename: []const u8) !void {
        var full_path = try std.fmt.allocPrint(self.allocator, "/home/shintales/GitRepositories/zid3/{s}", .{filename});
        var file = try std.fs.createFileAbsolute(full_path, .{});
        defer file.close();

        _ = try file.write(std.mem.asBytes(&self.header));
        for (self.frame_headers.inner_list.items) |frame_header| {
            _ = try file.write(&frame_header.id);
            _ = try file.write(&frame_header.size);
            _ = try file.write(&frame_header.flags);
            _ = try file.writeAll(frame_header.content);
        }
    }

    /// Get the title of the song
    pub fn getTitle(self: *Self) []u8 {
        return self.getTag("TIT2");
    }

    /// Get the artist of the song
    pub fn getArtist(self: *Self) []u8 {
        return self.getTag("TPE1");
    }

    /// Get the album song is from
    pub fn getAlbum(self: *Self) []u8 {
        return self.getTag("TALB");
    }

    /// Get names of artist listed on album
    pub fn getAlbumArtist(self: *Self) []u8 {
        return self.getTag("TPE2");
    }

    /// Get the genre from song
    pub fn getGenre(self: *Self) []u8 {
        return self.getTag("TCON");
    }

    /// Get the track number of song
    pub fn getTrackNum(self: *Self) []u8 {
        return self.getTag("TRCK");
    }

    /// Get the year song was released
    pub fn getYear(self: *Self) []u8 {
        return self.getTag("TYER");
    }

    /// Parse the tag information based on the ID3v2 frame id
    pub fn getTag(self: *Self, id: []const u8) []u8 {
        for (self.frame_headers.inner_list.items) |frame_header| {
            if (std.mem.eql(u8, frame_header.id[0..], id)) {
                if (frame_header.getTextFrame().encoding == 1)
                    return frame_header.getTextFrame().information[2..];
                return frame_header.getTextFrame().information;
            }
        }
        return undefined;
    }

    /// Set song title
    pub fn setTitle(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TIT2", input);
    }

    /// Set artist name
    pub fn setArtist(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TPE1", input);
    }

    /// Set album name
    pub fn setAlbum(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TALB", input);
    }

    /// Set album artist name(s)
    /// List names as comma seperated string
    pub fn setAlbumArtist(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TPE2", input);
    }

    /// Set genre
    pub fn setGenre(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TCON", input);
    }

    /// Set track number
    pub fn setTrackNum(self: *Self, input: []const u8) !void {
        try self.setTagInformation("TRCK", input);
    }

    ///Set year released
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
                frame_header.content = try std.mem.concat(self.allocator, u8, &[_][]const u8{ preserve, input });
                break;
            }
        }
    }
};
