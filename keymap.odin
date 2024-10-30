package kite

Key :: enum byte {
	a = 'a', b = 'b', c = 'c', d = 'd', e = 'e', f = 'f', g = 'g', h = 'h', i = 'i', j = 'j', k = 'k', l = 'l', m = 'm',
	n = 'n', o = 'o', p = 'p', q = 'q', r = 'r', s = 's', t = 't', u = 'u', v = 'v', w = 'w', x = 'x', y = 'y', z = 'z',

	A = 'A', B = 'B', C = 'C', D = 'D', E = 'E', F = 'F', G = 'G', H = 'H', I = 'I', J = 'J', K = 'K', L = 'L', M = 'M',
	N = 'N', O = 'O', P = 'P', Q = 'Q', R = 'R', S = 'S', T = 'T', U = 'U', V = 'V', W = 'W', X = 'X', Y = 'Y', Z = 'Z',

	Ctrl_A = 0x01, Ctrl_B = 0x02, Ctrl_C = 0x03, Ctrl_D = 0x04, Ctrl_E = 0x05, Ctrl_F = 0x06, Ctrl_G = 0x07, Ctrl_H = 0x08, Ctrl_I = 0x09, Ctrl_J = 0x0a, Ctrl_K = 0x0b, Ctrl_L = 0x0c, Ctrl_M = 0x0d,
	Ctrl_N = 0x0e, Ctrl_O = 0x0f, Ctrl_P = 0x10, Ctrl_Q = 0x11, Ctrl_R = 0x12, Ctrl_S = 0x13, Ctrl_T = 0x14, Ctrl_U = 0x15, Ctrl_V = 0x16, Ctrl_W = 0x17, Ctrl_X = 0x18, Ctrl_Y = 0x19, Ctrl_Z = 0x1a,

	// Num_0 = '0', Num_1 = '1', Num_2 = '2', Num_3 = '3', Num_4 = '4', Num_5 = '5', Num_6 = '6', Num_7 = '7', Num_8 = '8', Num_9 = '9',
}

Key_Map_Action :: #type proc(data: rawptr)

MAX_KEYMAP_LEN :: 8

Key_Sequence :: arr.Small_Array(MAX_KEYMAP_LEN, Key)

Key_Map :: struct {
	sequence: Key_Sequence,
	action: Key_Map_Action,
}

Key_Maps :: [dynamic]Key_Map

// Searches for keymap in map array, returns a slice with all matching entries
// at `offset`. This assumes the array is sorted by key sequence
keymap_search :: proc(maps: []Key_Map, key: Key, offset: int) -> []Key_Map {
	assert(offset < MAX_KEYMAP_LEN);
	begin, end : int
	found := false

	for km, i in maps {
		#no_bounds_check if km.sequence.data[offset] == key {
			fmt.println(km.sequence.data[offset], "=", key)
			begin = i
			found = true
			break
		}
	}

	#reverse for km, i in maps {
		#no_bounds_check if km.sequence.data[offset] == key {
			end = i
			break
		}
	}

	return maps[begin:end+1] if found else nil
}

// Helper to create a keymap
keymap_make :: proc(action: Key_Map_Action, keys: ..Key) -> Key_Map {
	key_seq : Key_Sequence
	key_seq.len = min(MAX_KEYMAP_LEN, len(keys))
	mem.copy_non_overlapping(raw_data(key_seq.data[:]), raw_data(keys[:]), size_of(Key) * len(keys))
	km := Key_Map {
		sequence = key_seq,
		action = action,
	}
	return km
}

// Compare 2 key sequences, used to keep keymaps sorted and lookups consistent
key_seq_compare :: proc(seq_a, seq_b: ^Key_Sequence) -> int {
	a := transmute([]byte) seq_a.data[:seq_a.len]
	b := transmute([]byte) seq_b.data[:seq_b.len]
	return mem.compare(a, b)
}

// Add a new keymaps, key sequence must be unique
keymap_add :: proc(maps: ^[dynamic]Key_Map, new_map: Key_Map){
	insert_at := 0
	new_map := new_map
	for &km, i in maps {
		comp := key_seq_compare(&km.sequence, &new_map.sequence)
		if comp > 0 {
			insert_at = i
			break
		}
		else if comp == 0 {
			panic("Cannot have 2 conflicting keymaps")
		}
		else {
			continue
		}
	}

	inject_at(maps, insert_at, new_map)
}
