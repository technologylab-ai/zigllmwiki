const std = @import("std");
const builtin = @import("builtin");

// The exact 0.17 Linux Threaded body converts maxInt(i96) nanoseconds to
// POSIX seconds before checking cancellation. The seconds do not fit time_t.
// A separate subprocess gate requires the specific safety panic and trace.
// Other hosts compile this program without executing the Linux witness.
pub fn main(init: std.process.Init) !void {
    if (builtin.os.tag != .linux) return;

    const infinite: std.Io.Timeout = .none;
    try infinite.sleep(init.io);
}
