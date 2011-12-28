module glfw;

extern(System) {
	enum int GLFW_VERSION_MAJOR = 2;
	enum int GLFW_VERSION_MINOR = 7;
	enum int GLFW_VERSION_REVISION = 0;

	enum {
		GLFW_RELEASE = 0,
		GLFW_PRESS = 1,		
	}

	enum {
		GLFW_KEY_UNKNOWN	= -1,
		GLFW_KEY_SPACE		= 32,
		GLFW_KEY_SPECIAL	= 256,
		GLFW_KEY_ESC		= (GLFW_KEY_SPECIAL+1),
		GLFW_KEY_F1         = (GLFW_KEY_SPECIAL+2),
		GLFW_KEY_F2         = (GLFW_KEY_SPECIAL+3),
		GLFW_KEY_F3         = (GLFW_KEY_SPECIAL+4),
		GLFW_KEY_F4         = (GLFW_KEY_SPECIAL+5),
		GLFW_KEY_F5         = (GLFW_KEY_SPECIAL+6),
		GLFW_KEY_F6         = (GLFW_KEY_SPECIAL+7),
		GLFW_KEY_F7         = (GLFW_KEY_SPECIAL+8),
		GLFW_KEY_F8         = (GLFW_KEY_SPECIAL+9),
		GLFW_KEY_F9         = (GLFW_KEY_SPECIAL+10),
		GLFW_KEY_F10        = (GLFW_KEY_SPECIAL+11),
		GLFW_KEY_F11        = (GLFW_KEY_SPECIAL+12),
		GLFW_KEY_F12        = (GLFW_KEY_SPECIAL+13),
		GLFW_KEY_F13        = (GLFW_KEY_SPECIAL+14),
		GLFW_KEY_F14        = (GLFW_KEY_SPECIAL+15),
		GLFW_KEY_F15        = (GLFW_KEY_SPECIAL+16),
		GLFW_KEY_F16        = (GLFW_KEY_SPECIAL+17),
		GLFW_KEY_F17        = (GLFW_KEY_SPECIAL+18),
		GLFW_KEY_F18        = (GLFW_KEY_SPECIAL+19),
		GLFW_KEY_F19        = (GLFW_KEY_SPECIAL+20),
		GLFW_KEY_F20        = (GLFW_KEY_SPECIAL+21),
		GLFW_KEY_F21        = (GLFW_KEY_SPECIAL+22),
		GLFW_KEY_F22        = (GLFW_KEY_SPECIAL+23),
		GLFW_KEY_F23        = (GLFW_KEY_SPECIAL+24),
		GLFW_KEY_F24        = (GLFW_KEY_SPECIAL+25),
		GLFW_KEY_F25        = (GLFW_KEY_SPECIAL+26),
		GLFW_KEY_UP         = (GLFW_KEY_SPECIAL+27),
		GLFW_KEY_DOWN       = (GLFW_KEY_SPECIAL+28),
		GLFW_KEY_LEFT       = (GLFW_KEY_SPECIAL+29),
		GLFW_KEY_RIGHT      = (GLFW_KEY_SPECIAL+30),
		GLFW_KEY_LSHIFT     = (GLFW_KEY_SPECIAL+31),
		GLFW_KEY_RSHIFT     = (GLFW_KEY_SPECIAL+32),
		GLFW_KEY_LCTRL      = (GLFW_KEY_SPECIAL+33),
		GLFW_KEY_RCTRL      = (GLFW_KEY_SPECIAL+34),
		GLFW_KEY_LALT       = (GLFW_KEY_SPECIAL+35),
		GLFW_KEY_RALT       = (GLFW_KEY_SPECIAL+36),
		GLFW_KEY_TAB        = (GLFW_KEY_SPECIAL+37),
		GLFW_KEY_ENTER      = (GLFW_KEY_SPECIAL+38),
		GLFW_KEY_BACKSPACE  = (GLFW_KEY_SPECIAL+39),
		GLFW_KEY_INSERT     = (GLFW_KEY_SPECIAL+40),
		GLFW_KEY_DEL        = (GLFW_KEY_SPECIAL+41),
		GLFW_KEY_PAGEUP     = (GLFW_KEY_SPECIAL+42),
		GLFW_KEY_PAGEDOWN   = (GLFW_KEY_SPECIAL+43),
		GLFW_KEY_HOME       = (GLFW_KEY_SPECIAL+44),
		GLFW_KEY_END        = (GLFW_KEY_SPECIAL+45),
		GLFW_KEY_KP_0       = (GLFW_KEY_SPECIAL+46),
		GLFW_KEY_KP_1       = (GLFW_KEY_SPECIAL+47),
		GLFW_KEY_KP_2       = (GLFW_KEY_SPECIAL+48),
		GLFW_KEY_KP_3       = (GLFW_KEY_SPECIAL+49),
		GLFW_KEY_KP_4       = (GLFW_KEY_SPECIAL+50),
		GLFW_KEY_KP_5       = (GLFW_KEY_SPECIAL+51),
		GLFW_KEY_KP_6       = (GLFW_KEY_SPECIAL+52),
		GLFW_KEY_KP_7       = (GLFW_KEY_SPECIAL+53),
		GLFW_KEY_KP_8       = (GLFW_KEY_SPECIAL+54),
		GLFW_KEY_KP_9       = (GLFW_KEY_SPECIAL+55),
		GLFW_KEY_KP_DIVIDE  = (GLFW_KEY_SPECIAL+56),
		GLFW_KEY_KP_MULTIPLY= (GLFW_KEY_SPECIAL+57),
		GLFW_KEY_KP_SUBTRACT= (GLFW_KEY_SPECIAL+58),
		GLFW_KEY_KP_ADD     = (GLFW_KEY_SPECIAL+59),
		GLFW_KEY_KP_DECIMAL = (GLFW_KEY_SPECIAL+60),
		GLFW_KEY_KP_EQUAL   = (GLFW_KEY_SPECIAL+61),
		GLFW_KEY_KP_ENTER   = (GLFW_KEY_SPECIAL+62),
		GLFW_KEY_KP_NUM_LOCK = (GLFW_KEY_SPECIAL+63),
		GLFW_KEY_CAPS_LOCK	= (GLFW_KEY_SPECIAL+64),
		GLFW_KEY_SCROLL_LOCK = (GLFW_KEY_SPECIAL+65),
		GLFW_KEY_PAUSE		= (GLFW_KEY_SPECIAL+66),
		GLFW_KEY_LSUPER		= (GLFW_KEY_SPECIAL+67),
		GLFW_KEY_RSUPER		= (GLFW_KEY_SPECIAL+68),
		GLFW_KEY_MENU		= (GLFW_KEY_SPECIAL+69),
		GLFW_KEY_LAST       = GLFW_KEY_MENU,
	}

	enum {
		GLFW_MOUSE_BUTTON_1 = 0,	
		GLFW_MOUSE_BUTTON_2 = 1,
		GLFW_MOUSE_BUTTON_3 = 2,
		GLFW_MOUSE_BUTTON_4 = 3,
		GLFW_MOUSE_BUTTON_5 = 4,
		GLFW_MOUSE_BUTTON_6 = 5,
		GLFW_MOUSE_BUTTON_7 = 6,
		GLFW_MOUSE_BUTTON_8 = 7,	
		GLFW_MOUSE_BUTTON_LAST = GLFW_MOUSE_BUTTON_8,
		GLFW_MOUSE_BUTTON_LEFT = GLFW_MOUSE_BUTTON_1,
		GLFW_MOUSE_BUTTON_RIGHT = GLFW_MOUSE_BUTTON_2,
		GLFW_MOUSE_BUTTON_MIDDLE = GLFW_MOUSE_BUTTON_3,
	}

	enum {
		GLFW_JOYSTICK_1 = 0,	
		GLFW_JOYSTICK_2 = 1,
		GLFW_JOYSTICK_3 = 2,
		GLFW_JOYSTICK_4 = 3,
		GLFW_JOYSTICK_5 = 4,
		GLFW_JOYSTICK_6 = 5,
		GLFW_JOYSTICK_7 = 6,
		GLFW_JOYSTICK_8 = 7,
		GLFW_JOYSTICK_9 = 8,
		GLFW_JOYSTICK_10 = 9,
		GLFW_JOYSTICK_11 = 10,
		GLFW_JOYSTICK_12 = 11,
		GLFW_JOYSTICK_13 = 12,
		GLFW_JOYSTICK_14 = 13,
		GLFW_JOYSTICK_15 = 14,
		GLFW_JOYSTICK_16 = 15,
		GLFW_JOYSTICK_LAST = GLFW_JOYSTICK_16,
	}

	enum {
		GLFW_WINDOW = 0x10001,
		GLFW_FULLSCREEN = 0x10002
	}

	enum {
		GLFW_OPENED = 0x20001,
		GLFW_ACTIVE = 0x20002,
		GLFW_ICONIFIED = 0x20003,
		GLFW_ACCELERATED = 0x20004,
		GLFW_RED_BITS = 0x20005,
		GLFW_GREEN_BITS = 0x20006,
		GLFW_BLUE_BITS = 0x20007,
		GLFW_ALPHA_BITS = 0x20008,
		GLFW_DEPTH_BITS = 0x20009,
		GLFW_STENCIL_BITS = 0x2000A
	}

	enum {
		GLFW_REFRESH_RATE = 0x2000B,
		GLFW_ACCUM_RED_BITS = 0x2000C,
		GLFW_ACCUM_GREEN_BITS = 0x2000D,
		GLFW_ACCUM_BLUE_BITS = 0x2000E,
		GLFW_ACCUM_ALPHA_BITS = 0x2000F,
		GLFW_AUX_BUFFERS = 0x20010,
		GLFW_STEREO = 0x20011,
		GLFW_WINDOW_NO_RESIZE = 0x20012,
		GLFW_FSAA_SAMPLES = 0x20013,
		GLFW_OPENGL_VERSION_MAJOR = 0x00020014,
		GLFW_OPENGL_VERSION_MINOR = 0x00020015,
		GLFW_OPENGL_FORWARD_COMPAT = 0x00020016,
		GLFW_OPENGL_DEBUG_CONTEXT = 0x00020017,
		GLFW_OPENGL_PROFILE	= 0x00020018
	}

	enum GLFW_OPENGL_PROFILES {
		GLFW_OPENGL_CORE_PROFILE = 0x00050001,
		GLFW_OPENGL_COMPAT_PROFILE = 0x00050002
	}

	enum {
		GLFW_MOUSE_CURSOR = 0x30001,
		GLFW_STICKY_KEYS = 0x30002,
		GLFW_STICKY_MOUSE_BUTTONS = 0x30003,
		GLFW_SYSTEM_KEYS = 0x30004,
		GLFW_KEY_REPEAT = 0x30005,
		GLFW_AUTO_POLL_EVENTS = 0x30006,
	}

	enum {
		GLFW_WAIT = 0x40001,
		GLFW_NOWAIT = 0x40002
	}

	enum {
		GLFW_PRESENT = 0x50001,
		GLFW_AXES = 0x50002,
		GLFW_BUTTONS = 0x50003
	}

	enum {
		GLFW_NO_RESCALE_BIT = 1,
		GLFW_ORIGIN_UL_BIT = 2,
		GLFW_BUILD_MIPMAPS = 4,
		GLFW_ALPHA_MAP_BIT = 8
	}

	const double GLFW_INFINITY = 100000.0;

	struct GLFWvidmode {
		int Width, Height;
		int RedBits, GreenBits, BlueBits;	
	}

	struct GLFWimage {
		int Width, Height;
		int Format;
		int BytesPerPixel;
		ubyte* Data;	
	}

	alias int GLFWthread;
	alias void* GLFWmutex;
	alias void* GLFWcond;

	alias void function(int, int) GLFWwindowsizefun;
	alias int function() GLFWwindowclosefun;
	alias void function() GLFWwindowrefreshfun;
	alias void function(int, int) GLFWmousebuttonfun;
	alias void function(int, int) GLFWmouseposfun;
	alias void function(int) GLFWmousewheelfun;
	alias void function(int, int) GLFWkeyfun;
	alias void function(int, int) GLFWcharfun;
	alias void function(void*) GLFWthreadfun;


	int glfwInit();
	void glfwTerminate();
	void glfwGetVersion(int*, int*, int*);

	// Window handling
	int glfwOpenWindow(int, int, int, int, int, int, int, int, int);
	void glfwOpenWindowHint(int, int);
	void glfwCloseWindow();
	void glfwSetWindowTitle(const char*);
	void glfwGetWindowSize(int *, int *);
	void glfwSetWindowSize(int, int);
	void glfwSetWindowPos(int, int);
	void glfwIconifyWindow();
	void glfwRestoreWindow();
	void glfwSwapBuffers();
	void glfwSwapInterval(int);
	int glfwGetWindowParam(int);
	void glfwSetWindowSizeCallback(GLFWwindowsizefun);
	void glfwSetWindowCloseCallback(GLFWwindowclosefun);
	void glfwSetWindowRefreshCallback(GLFWwindowrefreshfun);

	// Video mode functions
	int glfwGetVideoModes(GLFWvidmode *, int);
	void glfwGetDesktopMode(GLFWvidmode *);

	// Input handling
	void glfwPollEvents();
	void glfwWaitEvents();
	int glfwGetKey(int);
	int glfwGetMouseButton(int);
	void glfwGetMousePos(int*,int *);
	void glfwSetMousePos(int, int);
	int glfwGetMouseWheel();
	void glfwSetMouseWheel(int);
	void glfwSetKeyCallback(GLFWkeyfun);
	void glfwSetCharCallback(GLFWcharfun);
	void glfwSetMouseButtonCallback(GLFWmousebuttonfun);
	void glfwSetMousePosCallback(GLFWmouseposfun);
	void glfwSetMouseWheelCallback(GLFWmousewheelfun);

	// Joystick input
	int glfwGetJoystickParam(int, int);
	int glfwGetJoystickPos(int, float *, int);
	int glfwGetJoystickButtons(int, ubyte*, int);

	// Time
	double glfwGetTime();
	void glfwSetTime(double);
	void glfwSleep(double);

	// Extension support
	int glfwExtensionSupported(const char*);
	void* glfwGetProcAddress(const char*);
	void glfwGetGLVersion(int *, int*, int*);

	// Threading support
	GLFWthread glfwCreateThread(GLFWthreadfun, void* );
	void glfwDestroyThread(GLFWthread);
	int glfwWaitThread(GLFWthread, int);
	GLFWthread glfwGetThreadID();
	GLFWmutex glfwCreateMutex();
	void glfwDestroyMutex(GLFWmutex);
	void glfwLockMutex(GLFWmutex);
	void glfwUnlockMutex(GLFWmutex);
	GLFWcond glfwCreateCond();
	void glfwDestroyCond(GLFWcond);
	void glfwWaitCond(GLFWcond, GLFWmutex, double );
	void glfwSignalCond(GLFWcond);
	void glfwBroadcastCond(GLFWcond);
	int glfwGetNumberOfProcessors();

	// Enable/disable functions
	void glfwEnable(int);
	void glfwDisable(int);

	// Image/texture I/O support
	int glfwReadImage(const char*, GLFWimage*, int);
	int glfwReadMemoryImage(const void*, size_t, GLFWimage*, int);
	void glfwFreeImage(GLFWimage *);
	int glfwLoadTexture2D(const char*, int);
	int glfwLoadMemoryTexture2D(const void *, size_t, int);
	int glfwLoadTextureImage2D(GLFWimage *, int);
}