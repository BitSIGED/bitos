use core::fmt;

use lazy_static::lazy_static;
use spin::Mutex;

use super::buffer::{BUFFER_HEIGHT, BUFFER_WIDTH, Buffer, ScreenChar};
use super::{Colour, VgaAttribute};

pub struct Writer {
    pub(super) column_position: usize,
    pub(super) colour_code: VgaAttribute,
    pub(super) buffer: &'static mut Buffer,
    pub(super) do_line_wrapping: bool,
}

impl Writer {
    pub fn write_string(&mut self, s: &str) {
        for byte in s.bytes() {
            match byte {
                0x20..=0x7e | b'\n' | b'\t' | b'\r' => self.write_byte(byte),
                _ => self.write_byte(0xfe), 
            }
        }
    }

    pub fn write_byte(&mut self, byte: u8) {
        match byte {
            b'\n' => self.new_line(),
            b'\t' => {
                let delta = 4 - (self.column_position % 4);
                for _ in 0..delta {
                    self.write_byte(b' ');
                }
            }
            b'\r' => {
                self.column_position = 0;
            }
            byte => {
                // TODO: Add support for non line wrapping modes
                if self.column_position >= BUFFER_WIDTH {
                    if self.do_line_wrapping { self.new_line() } 
                    else { return; } // Advanced buffering with scrolling can be implemnted later.
                                     // For now an overflow without linewrapping can be dropped
                }
                let row = BUFFER_HEIGHT - 1;
                let col = self.column_position;
                let colour_code = self.colour_code;
                self.buffer.chars[row][col].write(ScreenChar {
                    ascii_character: byte,
                    colour_code,
                });
                self.column_position += 1;
            }
        }
    }
  
    fn new_line(&mut self) {
        for row in 1..BUFFER_HEIGHT {
            for col in 0..BUFFER_WIDTH {
                self.buffer.chars[row - 1][col].write(self.buffer.chars[row][col].read())
            }
        }
        self.clear_row(BUFFER_HEIGHT - 1);
        self.column_position = 0;
    }

    fn clear_row(&mut self, row: usize) {
        let blank = ScreenChar {
            ascii_character: b' ',
            colour_code: self.colour_code,
        };
        for col in 0..BUFFER_WIDTH {
            self.buffer.chars[row][col].write(blank);
        }
    }
}

impl fmt::Write for Writer {
    fn write_str(&mut self, s: &str) -> fmt::Result {
        self.write_string(s);
        Ok(())
    }
}

lazy_static! {
    pub static ref WRITER: Mutex<Writer> = Mutex::new(Writer {
        column_position: 0,
        colour_code: VgaAttribute::from_colour(Colour::White, Colour::Black),
        buffer: unsafe { &mut *(0xb8000 as *mut Buffer) },
        do_line_wrapping: true,
    });
}
