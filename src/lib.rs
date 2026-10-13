#![feature(lang_items)]
#![no_std]

extern crate rlibc;


#[unsafe(no_mangle)]
pub extern "C" fn rust_init() {
    let ptr: *mut u64 = (0xb8000 as *mut u64);
    unsafe { *ptr = 0x2f592f412f4b2f4f }; 
}

#[lang = "eh_personality"]
pub extern "C" fn eh_personality() {}

#[panic_handler]
fn panic(_info: &core::panic::PanicInfo) -> ! {
    loop {}
}
