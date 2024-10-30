package kite

import "core:fmt"
import "core:sync"
import "core:thread"
import "core:os"
import "core:time"
import "core:container/queue"
import "core:slice"
import "core:mem"
import arr "core:container/small_array"
import "core:strings"
import "core:unicode/utf8"

import "terminal"
import gb "gap_buffer"

Cursor :: struct {
	mark, pos: gb.Pos,
}

Buffer :: struct {
	byte_buf: gb.Gap_Buffer,
	cursors: [dynamic]Cursor,
	filename: string,
}

buffer_make :: proc(filename: string, allocator := context.allocator) -> (buf: Buffer, err: mem.Allocator_Error){
	defer if err != nil { gb.buffer_destroy(&buf.byte_buf) }
	defer if err != nil { delete(buf.cursors) }
	defer if err != nil { delete(filename) }

	buf.byte_buf = gb.buffer_make(500, allocator) or_return
	buf.cursors = make([dynamic]Cursor, 1, cap=20, allocator = allocator) or_return
	buf.filename = strings.clone(filename, allocator) or_return

	return
}

buffer_delete :: proc(buf: ^Buffer){
	delete(buf.filename, allocator=buf.byte_buf.allocator)
	gb.buffer_destroy(&buf.byte_buf)
}

main :: proc(){
	terminal.enable_raw_mode()
	defer terminal.disable_raw_mode()

	@static raw_buf : [4096]byte

	input_loop: for {
		handle, err := os.open("/dev/stdin")
		n, _ := os.read(handle, raw_buf[:])

		decode_buf := raw_buf[:n]
		decoded := 0

		decode_raw_buffer: for {
			left := decode_buf[decoded:]
			if len(left) < 1 { break }
			r, n := utf8.decode_rune(left);

			if r == 0x03 {
				break input_loop
			}

			fmt.print(r)
			decoded += max(1, n)
		}
	}
}


