const std = @import("std");
const file = @import("./file.zig");
const Args = @import("./Args.zig");
const Scanner = @import("./Scanner.zig");
const streams = @import("./streams.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer {
        _ = gpa.deinit();
    }
    const allocator = gpa.allocator();
    const args = try Args.init(allocator);
    defer args.deinit();
    const file_contents = try file.readFile(args.filename orelse unreachable, allocator);
    defer allocator.free(file_contents);

    var stream = streams.CharStream.init(file_contents);
    var scanner = Scanner{ .char_stream = stream };
    var token_stream = try scanner.read(allocator);
    defer Scanner.freeTokenStream(allocator, token_stream);

    const json_val = try std.json.stringifyAlloc(allocator, token_stream.buffer, .{ .whitespace = .indent_2 });
    defer allocator.free(json_val);

    std.debug.print("{s}", .{json_val});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
