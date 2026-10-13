#![feature(lang_items)]
#![allow(internal_features)]
#![no_std]

extern crate rlibc;

mod vga_buff;

#[unsafe(no_mangle)]
pub extern "C" fn rust_init() {
    println!("Hello World{}", "!");
}

#[lang = "eh_personality"]
pub extern "C" fn eh_personality() {}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}
