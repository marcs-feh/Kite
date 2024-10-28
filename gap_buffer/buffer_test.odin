package gap_buffer

import "core:fmt"
import "core:log"
import "core:mem"
import "core:slice"
import ts "core:testing"

@(test)
basic_editing :: proc(t: ^ts.T){
	defer free_all(context.temp_allocator)
	buf, err := buffer_make(64)
	defer buffer_destroy(&buf)
	expect_all(t,
		err == nil,
		buf.gap_start == 0,
		int(buf.gap_end) == len(buf.data),
	)

	insert_text(&buf, 0, "Hello")
	expect_all(t, buf.gap_start == 5, int(buf.gap_end) == len(buf.data))
	{
		s, _ := buffer_build_string(buf, context.temp_allocator)
		expect(t, s == "Hello")
	}

	insert_text(&buf, text_size(buf), " ")
	expect_all(t, buf.gap_start == 6, int(buf.gap_end) == len(buf.data))
	{
		s, _ := buffer_build_string(buf, context.temp_allocator)
		expect(t, s == "Hello ")
	}

	insert_text(&buf, text_size(buf), '世')
	expect_all(t, buf.gap_start == 6+3, int(buf.gap_end) == len(buf.data))
	{
		s, _ := buffer_build_string(buf, context.temp_allocator)
		expect(t, s == "Hello 世")
	}

	insert_text(&buf, 5, "pe")
	expect_all(t, buf.gap_start == 5 + 2)
	{
		s, _ := buffer_build_string(buf, context.temp_allocator)
		expect(t, s == "Hellope 世")
	}

	insert_text(&buf, text_size(buf), "界")
	{
		s, _ := buffer_build_string(buf, context.temp_allocator)
		expect(t, s == "Hellope 世界")
	}

	delete_text(&buf, text_size(buf) - 3, 3)
	{
		s, _ := buffer_build_string(buf, context.temp_allocator)
		expect(t, s == "Hellope 世")
	}

	delete_text(&buf, 5, 2)
	{
		s, _ := buffer_build_string(buf, context.temp_allocator)
		expect(t, s == "Hello 世")
	}

	delete_text(&buf, 0, 1)
	{
		s, _ := buffer_build_string(buf, context.temp_allocator)
		expect(t, s == "ello 世")
	}

	delete_text(&buf, 0, text_size(buf))
	{
		s, _ := buffer_build_string(buf, context.temp_allocator)
		expect(t, s == "")
	}

}

@(private="file")
expect :: #force_inline proc(t: ^ts.T, ok: bool, loc := #caller_location){ ts.expect(t, ok, loc = loc) }

@(private="file")
expect_all :: #force_inline proc(t: ^ts.T, preds: ..bool, loc := #caller_location){
	ok := true
	for p in preds { ok = ok && p }
	ts.expect(t, ok, loc = loc)
}

@(private="file")
expect_any :: #force_inline proc(t: ^ts.T, preds: ..bool, loc := #caller_location){
	ok := false
	for p in preds { ok = ok || p }
	ts.expect(t, ok, loc = loc)
}

