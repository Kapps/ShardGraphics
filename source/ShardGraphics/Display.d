module ShardGraphics.Display;
import derelict.glfw3.glfw3;
import core.stdc.string;
import ShardMath.Vector;
import std.format;

@nogc:

alias DisplayHandle = GLFWmonitor*;

/// Provides information about a single physical display.
struct Display {

	/// The default constructor is disabled as displays should be queried.
	@disable this();

	/// Creates a display from the given handle.
	this(DisplayHandle handle) {
		this._handle = handle;
	}

	/// Returns the primary display, as determined by the operating system.
	@property static Display primary() {
		return Display(glfwGetPrimaryMonitor());
	}

	/// Gets the handle of this display.
	@property DisplayHandle handle() {
		return _handle;
	}

	/// Returns the current resolution of this display.
	/// With the current implementation, this is actually the active video mode, which may be different
	/// if there is currently a full-screen program focused that is not using the native resolution.
	@property Vector2i resolution() {
		auto vm = glfwGetVideoMode(handle);
		return Vector2i(vm.width, vm.height);
	}

	/// Returns the name of this display.
	/// The return value is managed by the underlying window provider, and so
	/// the lifespan of the value is tied to the lifespan of the window provider (such as GLFW).
	@property string name() {
		auto res = glfwGetMonitorName(handle);
		auto len = strlen(res);
		return cast(string)res[0..len];
	}

	/// Returns this display in the format of "Name (Width x Height)".
	void toString(scope void delegate(const(char)[]) @nogc sink, FormatSpec!char fmt) {
		sink(name);
		sink(" (");
		auto res = resolution;
		sink.formatValue(res.width, fmt);
		sink(" x ");
		sink.formatValue(res.height, fmt);
		sink(")");
	}

	private DisplayHandle _handle;
}

