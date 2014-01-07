module ShardGraphics.GraphicsAPI;
private import std.conv;

/// The API used to render graphics. At the moment, only OpenGL is supported.
enum GraphicsRenderer {
	Unknown = 0,
	OpenGL = 1
}

/// Provides information about the graphics API being used.
struct GraphicsAPI {
	/// The renderer being used.
	const GraphicsRenderer Renderer;
	/// The major version of the API. Example: For OpenGL 4.0, this would be 4. For OpenGL 3.2, this would be 3. For DirectX 11, this would be 11.
	const int MajorVersion;
	/// The minor version of the API. Example: For OpenGL 4.0, this would be 0. For OpenGL 3.2, this would be 2. For DirectX 11, this would be 0(?).
	const int MinorVersion;

	this(GraphicsRenderer Renderer, int MajorVersion, int MinorVersion) {
		this.Renderer = Renderer;
		this.MajorVersion = MajorVersion;
		this.MinorVersion = MinorVersion;
	}

	/// Returns a string representation of the GraphicsAPI.
	string toString() const {
		return to!string(Renderer) ~ " " ~ to!string(MajorVersion) ~ "." ~ to!string(MinorVersion);
	}
}