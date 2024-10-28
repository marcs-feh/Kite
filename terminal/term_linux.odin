#+private linux
package term

import "core:sys/linux"
foreign import term "term_linux.o"

stdout :: 1

@(private="file")
foreign term {
	term_enable_raw_mode :: proc(fd: i32) -> i32 ---
	term_disable_raw_mode :: proc(fd: i32) -> i32 ---
	term_get_dimensions :: proc(fd: i32, w, h: ^i32) -> i32 ---
}

_enable_raw_mode :: proc() -> bool {
	e := term_enable_raw_mode(stdout)
	return e >= 0
}

_disable_raw_mode :: proc() -> bool {
	e := term_disable_raw_mode(stdout)
	return e >= 0
}

_get_dimensions :: proc() -> (w: int, h: int, ok: bool) {
	w_in, h_in : i32
	e := term_get_dimensions(stdout, &w_in, &h_in)
	ok = e >= 0
	w, h = int(w_in), int(h_in)
	return
}

_write_data :: proc(data: []byte) -> bool {
	_, e := linux.write(stdout, data)
	return i32(e) >= 0
}

