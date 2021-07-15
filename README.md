# Zig ID3 Metadata Library

This is a library written in Zig with the ability to read id3 tags from mp3 files.

This was created with the sole purpose of learning Zig. It is free to use however 
one sees fit.

## Features
Get metadata information for common tags in id3 v2.3 format.

## Usage
This should work with Zig 0.8 stable and 0.9 dev releases

```zig
// Import the module
const zid3 = @import("zid3");


pub fn main() anyerror!void {
    const filename = "/absolute/path/to/file.mp3";

    // Use whatever memory allocator you want
    var id3 = try zid3.ID3.load(std.heap.page_allocator, filename);
    defer id3.deinit();

    // Examples of getting tags that already have functions
    std.debug.print("{s}\n", .{id3.getTitle()});
    std.debug.print("{s}\n", .{id3.getArtist()});

    // Examples of getting tag that does not have predefined function. This uses
    // the ID3v2 frame id
    std.debug.print("{s}\n", .{id3.getTag("APIC")});
}
```

## Future goals (hopefully)
* Add zigmod support
* Support id3 v2.4
* Support id3 v1?
* The ability to edit id3 tags
