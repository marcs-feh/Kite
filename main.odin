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

	input: queue.Queue(rune),
	input_lock: ^sync.Mutex,
}

BUFFER_INPUT_CAP :: 800

buffer_make :: proc(filename: string, allocator := context.allocator) -> (buf: Buffer, err: mem.Allocator_Error){
	defer if err != nil {
		buffer_delete(&buf)
	}

	input_buf := make([]rune, BUFFER_INPUT_CAP) or_return

	buf.byte_buf = gb.buffer_make(500, allocator) or_return
	buf.cursors = make([dynamic]Cursor, 1, cap=20, allocator = allocator) or_return
	buf.filename = strings.clone(filename, allocator) or_return
	buf.input_lock = new(sync.Mutex, allocator)
	queue.init_from_slice(&buf.input, input_buf)

	return
}

buffer_delete :: proc(buf: ^Buffer){
	delete(buf.filename, buf.byte_buf.allocator)
	gb.buffer_destroy(&buf.byte_buf)
	delete(buf.cursors)
	delete(buf.filename, buf.byte_buf.allocator)
	free(buf.input_lock, buf.byte_buf.allocator)
	delete(raw_data(buf.input.data)[:BUFFER_INPUT_CAP], buf.byte_buf.allocator)
}

buffer : Buffer

main :: proc(){
	terminal.enable_raw_mode()
	defer terminal.disable_raw_mode()

	@static raw_buffer : arr.Small_Array(4096, byte)
	@static rune_buffer : arr.Small_Array(512, rune)

	err : mem.Allocator_Error
	buffer, err = buffer_make("Pog")
	assert(err == nil)

	thread.create_and_start_with_data(&buffer, proc(data: rawptr){
		buffer := transmute(^Buffer)data
		for {
			sync.lock(buffer.input_lock)

			if buffer.input.len > 0 {
				defer sync.unlock(buffer.input_lock)
				for buffer.input.len > 0 {
					r := queue.pop_front(&buffer.input)
					fmt.print(r)
				}
			}
			else {
				sync.unlock(buffer.input_lock)
				time.sleep(time.Millisecond * 3)
			}
		}
	})

	handle, open_err := os.open("/dev/stdin")
	assert(open_err == nil)

	input_loop: for {
		n, read_error := os.read(handle, raw_buffer.data[:])
		raw_buffer.len = n

		decoded_byte_count := 0
		decode_raw_buffer: for {
			left_to_decode := arr.slice(&raw_buffer)[decoded_byte_count:]
			// fmt.println(len(left_to_decode))
			if len(left_to_decode) < 1 { break }

			r, n := utf8.decode_rune(left_to_decode);
			arr.append(&rune_buffer, r)
			decoded_byte_count += max(1, n)

			if r == 0x03 {
				break input_loop
			}
		}

		if sync.mutex_guard(buffer.input_lock){
			for ok, _ := queue.push_back_elems(&buffer.input, ..arr.slice(&rune_buffer)); !ok; {
				@static failed := 0
				failed += 1
				if failed > 100 {
					buffer.input.len = 0
					raw_buffer.len   = 0
					rune_buffer.len  = 0
					failed           = 0
					fmt.println(terminal.CSI + "2J" + terminal.CSI + "3J")
					fmt.println("[[ FATAL ERROR ]] A fatal input error has occoured, the file may be left in an incomplete state")
					time.sleep(3 * time.Second)
					continue input_loop
				}
			}
		}

		raw_buffer.len -= decoded_byte_count
		rune_buffer.len = 0

		assert(raw_buffer.len >= 0)
		assert(rune_buffer.len >= 0)
		// fmt.println(buffer.input)
	}
}


