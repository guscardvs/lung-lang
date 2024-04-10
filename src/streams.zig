const std = @import("std");

const StreamError = error{
    BoundOverflow,
};

pub fn Stream(comptime T: type) type {
    return struct {
        buffer: []const T,
        pos: usize,
        const Self = @This();
        pub const StreamIterator = struct {
            stream: Stream(T),
            const IteratorSelf = @This();

            pub fn next(self: *IteratorSelf) ?T {
                if (self.stream.isEndOfStream()) {
                    return null;
                }
                return self.stream.walk();
            }

            //Iterate until the next value does not match any items in haystack
            pub fn nextExcept(self: *IteratorSelf, haystack: []const T) ?T {
                while (self.next()) |next_val| {
                    if (!std.mem.containsAtLeast(T, haystack, 1, &[_]T{next_val})) {
                        return next_val;
                    }
                }
                return null;
            }

            // Iterate until the next value matches any item in haystack
            pub fn nextUntil(self: *IteratorSelf, haystack: []const T) ?T {
                while (self.next()) |next_val| {
                    if (std.mem.containsAtLeast(T, haystack, 1, &[_]T{next_val})) {
                        return next_val;
                    }
                }
                return null;
            }

            pub fn isExhausted(self: IteratorSelf) bool {
                return self.stream.isEndOfStream();
            }

            pub fn reset(self: *IteratorSelf) void {
                self.stream.pos = 0;
            }

            pub fn init(stream: Stream(T)) IteratorSelf {
                return IteratorSelf{ .stream = stream.getCopy() };
            }

            pub fn getLastPos(self: IteratorSelf) usize {
                return if (self.stream.pos == 0) 0 else self.stream.pos - 1;
            }

            pub fn getLast(self: IteratorSelf) T {
                return self.stream.buffer[self.getLastPos()];
            }

            pub fn getStreamCurrent(self: IteratorSelf) T {
                return self.stream.current();
            }
        };

        pub fn isEndOfStream(self: Self) bool {
            return self.pos >= self.buffer.len;
        }

        pub fn peek(self: Self, upto: usize) bool {
            const pos = @min(self.pos + upto, self.buffer.len - 1);
            return self.buffer[pos];
        }

        pub fn walkN(self: *Self, upto: usize) T {
            defer self.pos += upto;
            return self.buffer[self.pos];
        }

        pub fn walk(self: *Self) T {
            return self.walkN(1);
        }

        pub fn lookBehindN(self: Self, upto: usize) T {
            const pos = if (self.getPos() < upto) 0 else self.pos - upto;
            return self.buffer[pos];
        }

        pub fn lookBehind(self: Self) T {
            return self.lookBehindN(1);
        }

        pub fn current(self: Self) T {
            return self.buffer[self.getPos()];
        }

        pub fn getPos(self: Self) usize {
            return @min(self.pos, self.buffer.len - 1);
        }

        pub fn init(buffer: []const T) Self {
            return Self{ .buffer = buffer, .pos = 0 };
        }

        pub fn getCopy(self: Self) Self {
            return Self.init(self.buffer);
        }

        pub fn iterator(self: Self) StreamIterator {
            return StreamIterator.init(self);
        }

        pub fn peekSlice(self: Self, start: usize, end: usize) StreamError![]const T {
            if (start > end or end >= self.buffer.len) return StreamError.BoundOverflow;
            return self.buffer[start..end];
        }
    };
}

pub const CharStream = Stream(u8);
pub const StringStream = Stream([]const u8);
