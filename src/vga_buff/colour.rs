#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(u8)]
#[allow(dead_code)]
pub enum Colour {
    Black = 0,
    Blue = 1,
    Green = 2,
    Cyan = 3,
    Red = 4,
    Magenta = 5,
    Brown = 6,
    LightGray = 7,
    DarkGray = 8,
    LightBlue = 9,
    LightGreen = 10,
    LightCyan = 11,
    LightRed = 12,
    Pink = 13,
    Yellow = 14,
    White = 15,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(transparent)]
pub struct VgaAttribute(u8);

impl VgaAttribute {
    #[allow(dead_code)]
    pub const fn new(blink: bool, fg: Colour, bg: Colour) -> Self {
        Self(((blink as u8) << 7) | (((bg as u8) & 0x07) << 4) | ((fg as u8) & 0x0F))
    }

    pub const fn from_colour(fg: Colour, bg: Colour) -> Self {
        Self((((bg as u8) & 0x07) << 4) | ((fg as u8) & 0x0F))
    }
}
