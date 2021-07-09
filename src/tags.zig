const std = @import("std");
const FrameHeader = @import("zid3.zig").FrameHeader;

/// Structure to store tagging information.
pub const Tags = struct {
    title: []u8,
    artist: []u8,
    album: []u8,
    album_artist: []u8,
    genre: []u8,
    track_num: []u8,
    year: []u8,

    pub fn init(frame_headers: *std.ArrayList(FrameHeader)) Tags {
        return .{
            .title = getTagInformation("TIT2", frame_headers),
            .artist = getTagInformation("TPE1", frame_headers),
            .album = getTagInformation("TALB", frame_headers),
            .album_artist = getTagInformation("TPE2", frame_headers),
            .genre = getTagInformation("TCON", frame_headers),
            .track_num = getTagInformation("TRCK", frame_headers),
            .year = getTagInformation("TYER", frame_headers),
        };
    }

    fn getTagInformation(id: []const u8, frame_headers: *std.ArrayList(FrameHeader)) []u8 {
        for (frame_headers.items) |frame_header| {
            if (std.mem.eql(u8, frame_header.id[0..], id))
                return frame_header.content;
        }
        return undefined;
    }
};
