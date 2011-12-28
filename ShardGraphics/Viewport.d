module ShardGraphics.Viewport;
public import ShardMath.Rectangle;
import gl;

/// A static class to provide information about the drawing area for a window.
static class Viewport  {

public static:
	
	/// Gets or sets the starting X coordinate for the Viewport.
	@property int X() {
		return Dimensions.X;
	}

	/// Ditto
	@property void X(int Value) {
		Rectanglei Curr = Dimensions;
		Dimensions = Rectanglei(Value, Curr.Y, Curr.Width, Curr.Height);
	}

	/// Gets or sets the starting Y coordinate for the Viewport.
	@property int Y() {
		return Dimensions.Y;
	}

	/// Ditto
	@property void Y(int Value) {
		Rectanglei Curr = Dimensions;
		Dimensions = Rectanglei(Curr.X, Value, Curr.Width, Curr.Height);
	}

	/// Gets or sets the Width of the Viewport.
	@property int Width() {
		return Dimensions.Width;
	}

	/// Ditto
	@property void Width(int Value) {
		Rectanglei Curr = Dimensions;
		Dimensions = Rectanglei(Curr.X, Curr.Y, Value, Curr.Height);
	}

	/// Gets or sets the Height of the Viewport.
	@property int Height() {
		return Dimensions.Height;
	}

	/// Ditto
	@property void Height(int Value) {
		Rectanglei Curr = Dimensions;
		Dimensions = Rectanglei(Curr.X, Curr.Y, Curr.Width, Value);
	}

	/// Gets or sets a rectangle encompassing the entire Viewport.
	@property Rectanglei Dimensions() {
		Rectanglei Result;
		glGetIntegerv(GL_VIEWPORT, cast(GLint*)&Result);
		return Result;
	}

	/// Ditto
	@property void Dimensions(Rectanglei Value) {
		glViewport(Value.X, Value.Y, Value.Width, Value.Height);
	}
}