use super::VgaAttribute;
use volatile::Volatile;

pub(super) const BUFFER_HEIGHT: usize = 25;
pub(super) const BUFFER_WIDTH: usize = 80;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[repr(C)]
pub(super) struct ScreenChar {
    pub(super) ascii_character: u8,
    pub(super) colour_code: VgaAttribute,
}

#[repr(transparent)]
pub(super) struct Buffer {
    pub(super) chars: [[Volatile<ScreenChar>; BUFFER_WIDTH]; BUFFER_HEIGHT],
}
