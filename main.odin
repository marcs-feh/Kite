package kite

import "core:fmt"
import "core:sync"
import "core:thread"
import "core:os"
import "core:time"
import "core:unicode/utf8"

import "terminal"
import "core:container/queue"

Keyboard_Worker_Arg :: struct {
	input: ^queue.Queue(rune),
	lock: ^sync.Mutex,
}

keyboard_worker :: proc(thrd: ^thread.Thread){
	handle, err := os.open("/dev/stdin")
	arg := transmute(^Keyboard_Worker_Arg)thrd.data
	@static input_buf : [16 * 1024]byte
	@static decode_buf : [len(input_buf) / 4]rune

	for {
		n, _ := os.read(handle, input_buf[:])
		bytes_in := input_buf[:n]

		decoded := 0
		for decoded < len(decode_buf) {
			left := bytes_in[decoded:]
			if len(left) < 1 { break }
			r, n := utf8.decode_rune(left)
			decoded += n
		}
		
		commit_input: {
			sync.guard(arg.lock)
			queue.push_back_elems(arg.input, ..decode_buf[:])
		}
	}
}

main :: proc(){
	@static input_queue : queue.Queue(rune)
	@static input_lock : sync.Mutex
	@static input_buf : [1024]rune
	queue.init_from_slice(&input_queue, input_buf[:])

	arg := Keyboard_Worker_Arg {
		input = &input_queue,
		lock = &input_lock,
	}

	kb_worker := thread.create(keyboard_worker)
	kb_worker.data = &arg
	thread.start(kb_worker)

	for {
		read_input: {
			sync.guard(&input_lock)
			r, _ := queue.pop_back_safe(&input_queue)
			fmt.print(r)
			time.sleep(12 * time.Millisecond)
		}
	}

	terminal.enable_raw_mode()
}

