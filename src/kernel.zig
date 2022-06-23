const zigvale = @import("zigvale").v2;
const builtin = @import("std").builtin;
const SerialPort = @import("x86_64").additional.serial_port.SerialPort;
const COMPort = @import("x86_64").additional.serial_port.COMPort;
const BaudRate = @import("x86_64").additional.serial_port.BaudRate;

export var stack_bytes: [16 * 1024:0]u8 align(16) linksection(".bss") = undefined;

export const header linksection(".stivale2hdr") = zigvale.Header{
    .stack = &stack_bytes[stack_bytes.len],

    .flags = .{
        .higher_half = 1,
        .pmr = 1,
    },

    .tags = &term_tag.tag,
    .entry_point = entry,
};

// This tag tells the bootloader to set up a terminal for your kernel to use
const term_tag = zigvale.Header.TerminalTag{
    .tag = .{ .identifier = .terminal, .next = &fb_tag.tag },
};

// This tag tells the bootloader to select the best possible video mode
const fb_tag = zigvale.Header.FramebufferTag{};
const entry = zigvale.entryPoint(kmain);
var gterm: *const zigvale.Struct.TerminalTag = undefined;
var serial: SerialPort = undefined;

pub fn panic(message: []const u8, stack_trace: ?*builtin.StackTrace) noreturn {
    _ = stack_trace;
    gterm.print("\nKERNEL PANIC! {s}\n", .{message});
    serial.writer().print("\nKERNEL PANIC! {s}\n", .{message}) catch {};
    while (true) {}
}

fn kmain(stivale_info: zigvale.Struct.Parsed) noreturn {
    serial = SerialPort.init(
        COMPort.COM1,
        BaudRate.Baud115200,
    );

    if (stivale_info.terminal) |term| {
        gterm = term;
        term.print(
            "Hello, world from Zig {}!\n",
            .{@import("builtin").zig_version},
        );
    }
    
    halt();
}

fn halt() noreturn {
    while (true) {
        asm volatile ("hlt");
    }
}
