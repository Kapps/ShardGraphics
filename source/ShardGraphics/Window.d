module ShardGraphics.Window;
import derelict.glfw3.glfw3;
import ShardTools.ScopeString;
import ShardMath.Vector;
import ShardGraphics.Display;
import ShardGraphics.GpuResource;
public import ShardGraphics.GraphicsContext;
import ShardTools.ExceptionTools;
import ShardTools.Logger;

@nogc:

alias WindowHandle = GLFWwindow*;

struct WindowHints {
	/// Indicates whether to remove decorations. Required for borderless fullscreen.
	bool borderless = false;
	/// Indicates how many multisamples to use for antialiasing (MSAA).
	/// The default value is 1 for no antialiasing. A value of 2 or 4 is common.
	int multisamples = 0;
	/// Indicates whether to use fullscreen mode.
	/// If both this and borderless are set, borderless fullscreen will be simulated.
	bool fullscreen = false;
	/// Indicates whether to create the context as a debug context.
	bool debugContext = false;
}

/// Provides a basic Window class that can be used for a graphics context. 
final class Window : GraphicsContext {

	/// Creates an opens a new window on the given display with the given title, size, and hints.
	/// Note that the size may be ignored for fullscreen.
	this(string title, Vector2i size, Display display, WindowHints hints) {
		this._title = title;
		this._handle = createWindow(title, size, display, hints);
		this.makeActive();
		glfwSwapInterval(0);
	}

	~this() {
		if(_handle) {
			logdf("Destroying window with handle of %s.", _handle);
			glfwDestroyWindow(_handle);
			_handle = null;
		}
	}

	/// Gets or sets the title of the created window.
	/// Note that this value is cached and will not reflect external changes.
	@property string title() const {
		return this._title;
	}

	/// Ditto
	@property void title(string val) {
		this._title = val;
		auto buff = ScopeString!256(val);
		glfwSetWindowTitle(_handle, buff.ptr);
	}

	/// Gets the underlying handle for this window.
	/// This is generally not needed in user code.
	@property WindowHandle handle() {
		return _handle;
	}

	/// Returns the Window instance that is associated with the given handle.
	@property static Window fromHandle(WindowHandle handle) {
		auto userPtr = glfwGetWindowUserPointer(handle);
		return cast(Window)userPtr;
	}

	/// Gets or sets the position or size of this window.
	@property Vector2i size() {
		Vector2i res;
		glfwGetWindowSize(handle, &res.x, &res.y);
		return res;
	}

	/// Ditto
	@property void size(Vector2i val) {
		glfwSetWindowSize(handle, val.x, val.y);
	}

	/// Ditto
	@property Vector2i position() {
		Vector2i res;
		glfwGetWindowPos(handle, &res.x, &res.y);
		return res;
	}

	/// Ditto
	@property void position(Vector2i val) {
		glfwSetWindowPos(handle, val.x, val.y);
	}

	/// Recreates the window with the given WindowHints on the given display.
	/// Resources are shared with the previous window.
	void recreateWindow(Display display, WindowHints hints) {
		this._handle = createWindow(title, size, display, hints);
		this.makeActive();
		glfwSwapInterval(0);
	}

protected:

	/// Handles the actual window creation.
	WindowHandle createWindow(string title, Vector2i size, Display display, WindowHints hints) {
		if(hints.fullscreen && hints.borderless) {
			size = display.resolution;
			hints.fullscreen = false;
		}
		glfwWindowHint(GLFW_DECORATED, !hints.borderless);
		glfwWindowHint(GLFW_SAMPLES, hints.multisamples);
		glfwWindowHint(GLFW_CLIENT_API, GLFW_OPENGL_API);
		auto buff = ScopeString!256(title);
		Vector2i oldPos;
		if(_handle !is WindowHandle.init)
			oldPos = this.position;
		auto res = glfwCreateWindow(size.width, size.height, buff.ptr, hints.fullscreen ? display.handle : null, _handle);
		enforceNoGC!(ResourceCreationException, "Failed to create the window handle.")(res);
		logdf("Created window with handle of %s and previous handle of %s.", res, _handle);
		if(_handle) {
			if(!hints.fullscreen)
				glfwSetWindowPos(res, oldPos.x, oldPos.y);
			glfwDestroyWindow(_handle);
			_handle = WindowHandle.init;
		}
		glfwSetWindowUserPointer(res, cast(void*)this);
		return res;
	}

	override void makeActiveImpl() {
		glfwMakeContextCurrent(handle);
	}

private:
	string _title;
	WindowHandle _handle;
}