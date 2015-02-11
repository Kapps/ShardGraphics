module ShardGraphics.GraphicsAPI;
private import std.conv, std.format;

/// The API used to render graphics. At the moment, only OpenGL is supported.
enum GraphicsRenderer : string {
	unknown = "Unknown",
	openGL = "OpenGL"
}

/// Provides information about the graphics API being used.
struct GraphicsAPI {
	/// The renderer being used.
	const GraphicsRenderer renderer;
	/// The major version of the API. Example: For OpenGL 4.0, this would be 4. For OpenGL 3.2, this would be 3. For DirectX 11, this would be 11.
	const int majorVersion;
	/// The minor version of the API. Example: For OpenGL 4.0, this would be 0. For OpenGL 3.2, this would be 2. For DirectX 11, this would be 0(?).
	const int minorVersion;

	this(GraphicsRenderer renderer, int majorVersion, int minorVersion) {
		this.renderer = renderer;
		this.majorVersion = majorVersion;
		this.minorVersion = minorVersion;
	}

	/// Returns a string representation of the GraphicsAPI.
	void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const {
		sink.formatValue(renderer, fmt);
		sink(" ");
		sink.formatValue(majorVersion, fmt);
		sink(".");
		sink.formatValue(minorVersion, fmt);
	}
}