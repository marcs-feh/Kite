package term

import "core:strings"

TermHandle :: distinct uintptr

enable_raw_mode :: proc() -> bool {
	return _enable_raw_mode()
}

disable_raw_mode :: proc() -> bool {
	return _disable_raw_mode()
}

get_dimensions :: proc() -> (w: int, h: int, ok: bool) {
	return _get_dimensions()
}

// Write buffer to terminal and reset it
write_buffer :: proc(buf: ^strings.Builder){
	write_data(buf.buf[:])
	strings.builder_reset(buf)
}

write_data :: proc(data: []byte) -> bool {
	return _write_data(data)
}

