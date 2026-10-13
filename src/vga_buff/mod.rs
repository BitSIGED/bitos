mod buffer;
mod colour;
mod writer;

pub use colour::{Colour, VgaAttribute};
pub use writer::WRITER;

use core::fmt;

#[doc(hidden)]
pub fn _print(args: fmt::Arguments) {
    use core::fmt::Write;
    WRITER.lock().write_fmt(args).unwrap();
}

pub fn set_line_wrapping(do_line_wrap: bool) {
    WRITER.lock().do_line_wrapping = do_line_wrap;
}

#[macro_export]
macro_rules! print {
    ($($arg:tt)*) => ($crate::vga_buff::_print(format_args!($($arg)*)));
}

#[macro_export]
macro_rules! println {
    () => ($crate::print!("\n"));
    ($($arg:tt)*) => ($crate::print!("{}\n", format_args!($($arg)*)));
}
