#+private
package gap_buffer

import "base:runtime"

// Clear everything after an index (index included)
clear_after :: proc(arr: ^[dynamic]$T, idx: int){
	assert(idx >= 0 && idx <= len(arr), "Failed bounds check")
	raw_arr := transmute(^runtime.Raw_Dynamic_Array)arr
	raw_arr.len = idx
}

