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
import "core:unicode/utf8"

import "terminal"

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


