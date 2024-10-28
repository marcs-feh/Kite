package term

import "core:fmt"
import str "core:strings"

CSI :: "\e["

Color :: enum {
	Black   = 0,
	Red     = 1,
	Green   = 2,
	Yellow  = 3,
	Blue    = 4,
	Magenta = 5,
	Cyan    = 6,
	White   = 7,
}

set_foreground :: proc(buf: ^str.Builder, fg: Color, bold := false){
	if bold {
		fmt.sbprintf(buf, CSI + "1;3%dm", int(fg))
	}
	else {
		fmt.sbprintf(buf, CSI + "3%dm", int(fg))
	}
}

set_background :: proc(buf: ^str.Builder, fg: Color){
	fmt.sbprintf(buf, CSI + "4%dm", int(fg))
}

reset_color :: proc(buf: ^str.Builder){
	fmt.sbprintf(buf, CSI + "0m")
}

// The x,y coordinates are 0-indexed.
set_cursor :: proc(buf: ^str.Builder, x, y: int){
	fmt.sbprintf(buf, CSI + "%d;%dH", y + 1, x + 1)
}

printf :: proc(buf: ^str.Builder, format: string, args: ..any){
	fmt.sbprintf(buf, format, ..args)
}

clear_screen :: proc(buf: ^str.Builder) {
	fmt.sbprintf(buf, CSI + "2J" + CSI + "3J")
}
