const std = @import("std");

const buffer_size = 256;
pub fn readFile(filename: []const u8, allocator: std.mem.Allocator) ![]u8 {
    const cur_dir = std.fs.cwd();

    const file = try (if (filename[0] != '/') cur_dir.openFile(filename, .{}) else std.fs.openFileAbsolute(filename, .{}));

    var file_contents = std.ArrayList(u8).init(allocator);
    errdefer file_contents.deinit();

    while (true) {
        var buffer: [buffer_size]u8 = undefined;
        const amt = try file.readAll(&buffer);
        if (amt == 0) break;
        try file_contents.appendSlice(buffer[0..amt]);
    }
    return file_contents.toOwnedSlice();
}
