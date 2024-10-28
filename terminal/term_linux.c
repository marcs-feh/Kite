#include <stdint.h>
#include <termios.h>
#include <sys/ioctl.h>
#include <sys/termios.h>

typedef uint32_t u32;
typedef int32_t  i32;

i32 term_get_dimensions(i32 fd, i32* width, i32* height){
	struct winsize win = {0};
	i32 err = ioctl(fd, TIOCGWINSZ, &win);
	*width  = (i32)win.ws_col;
	*height = (i32)win.ws_row;

	return err;
}

i32 term_enable_raw_mode(i32 fd){
	struct termios tio = {0};
	i32 err = 0;

	err = tcgetattr(fd, &tio);
	if(err < 0){ return err; }

	tio.c_lflag &= ~(ECHO | ICANON | ISTRIP | ISIG);
	tio.c_iflag &= ~(IXON | IXOFF);

	err = tcsetattr(fd, TCSAFLUSH, &tio);
	if(err < 0){ return err; }

	return err;
}

i32 term_disable_raw_mode(i32 fd){
	i32 err = 0;
	struct termios tio = {0};

	err = tcgetattr(fd, &tio);
	if(err < 0){ return err; }

	tio.c_lflag |= ECHO | ICANON;

	err = tcsetattr(fd, TCSAFLUSH, &tio);
	if(err < 0){ return err; }

	return err;
}

