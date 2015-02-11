module ShardGraphics.GraphicsBuffer;
private import std.conv;
import derelict.opengl3.gl3;
import std.traits;
import std.typecons;
import ShardGraphics.GpuResource;
import std.math;
import std.exception;
import ShardTools.ExceptionTools;
import ShardTools.Logger;
import gl;

/// Determines how vertex data will be modified.
enum BufferModifyHint {
	/// The data will be set once and used multiple times.
	/// In OpenGL, this maps to STATIC.
	infrequent = GL_STATIC_DRAW - 1,
	/// The data will be set once, used once, repeated any number of times.
	/// In OpenGL this maps to STREAM.
	perDraw = GL_STREAM_DRAW - 1,
	/// The data will be set multiple times then used multiple times.
	/// In OpenGL this maps to DYNAMIC.
	frequent = GL_DYNAMIC_DRAW - 1
}

/// Determines how vertex data will be accessed.
enum BufferAccessHint {
	/// The data is generated by the application then passed to the graphics API for rendering.
	/// In OpenGL this maps to DRAW.
	writeOnly = 1,
	/// The data is generated by the graphics API and read from the application.
	/// In OpenGL this maps to READ.
	readOnly = 2,
	/// The data is generated or read both by the graphics API and the application.
	/// In OpenGL this maps to COPY.
	readWrite = 3
}

/// Indicates the type of the graphics buffer.
/// The values here may not be a complete list depending on the graphics API used.
/// For other values, it is allowed to specify the direct value (such as GL_TRANSFORM_FEEDBACK_BUFFER) instead of one of the below values.
enum BufferType {
	///
	vertex = GL_ARRAY_BUFFER,
	///
	index = GL_ELEMENT_ARRAY_BUFFER,
	///
	uniformStore = GL_UNIFORM_BUFFER,
	///
	textureStore = GL_TEXTURE_BUFFER
}

/// Represents a generic graphics buffer, such as a VertexBuffer or UniformBuffer.
struct GraphicsBuffer(BufferType _type) {

public:
	/// The default constructor is disabled for buffers.
	@disable this();

	/// Creates a new GpuBuffer with the given access and modify hints.
	/// Params:
	///		modifyHint = Determines how the data will be used.
	///		accessHint = Determines how the data will be accessed.
	this(BufferModifyHint modifyHint, BufferAccessHint accessHint) {
		ResourceID id;
		GL.createBuffers(1, &id); // Has to be create.
		this.id = id;
		this._style = modifyHint + accessHint;
		debug ensureValidStyle(_style);
		logdf("Created %sBuffer with style of %s (%s-%s) [%s].", _type, _style, modifyHint, accessHint, GL_STATIC_DRAW);
	}

	mixin GpuResource;

	/// Indicates the type of this buffer.
	enum type = _type;

	/// Gets the total size, in bytes, of the data this VBO contains.
	@property size_t size() const {
		return _sizeInBytes;
	}

	/+ /// Returns a pointer to the contents of this buffer in the form of an array. This array should never be stored.
	/// While a buffer is mapped, it is not safe to make any calls that alter the state of the buffer.
	/// A buffer may not be mapped until setData has been called at least once, as it specifies the size of the buffer.
	/// Params:
	/// 	Accessstyle = Determines the data to put in the buffer. It is important that you do not attempt to access the buffer in a way not defined by this parameter.
	///		offset = The number of bytes within the buffer for the start of the map.
	///		Length = The number of bytes the map contains.
	void[] RequestMap(VertexAccessHint Accessstyle, uint offset, uint Length) {
		debug assert(isDataSet);
		GLenum style = Accessstyle == VertexAccessHint.ReadOnly ? GL_MAP_READ_BIT : Accessstyle == VertexAccessHint.WriteOnly ? GL_MAP_WRITE_BIT : GL_MAP_READ_BIT | GL_MAP_WRITE_BIT;
		void* Result = glMapBufferRange(ResourceID, 0, Length, style);
		return Result[0 .. length];
	}

	/// Flushes the given subrange of the currently active map.
	/// This must be called before the given subrange mapped can be used again, and may be called multiple times for different regions.
	/// Params:
	/// 	offset = The offset within the map to flush. Important: Relative to the map, not the buffer.
	/// 	Length = The number of bytes within the map to flush.
	bool FlushMap(uint offset, uint Length) {
		return true;
	}+/

	/// Assigns a range within this buffer to the given data.
	/// The buffer must first have had data allocated through `setData` or `allocData`.
	/// It is not allowed to attempt to assign past the end of the allocated data, and an exception will be thrown in this case.
	void setSubData(T)(in T[] data, size_t offset) if(!is(T == class) && !hasIndirections!T) {
		debug isAllocated.enforceNoGC!(InvalidArgumentException, "Attempted to assign data past the end of the GraphicsBuffer.");
		if(offset + (T.sizeof * data.length) > this.size)
			throw new InvalidArgumentException("Attempted to assign data past the buffer size.");
		GL.namedBufferSubData(id, offset, data.length * T.sizeof, data.ptr);
	}

	/// Sets the data for this buffer to the given values.
	/// This results in a GPU allocation to create storage for the buffer.
	/// If you wish to reuse a buffer from a previous call to `setData` or `allocData`, use `setSubData` instead.
	void setData(T)(in T[] elements) if(!is(T == class) && !hasIndirections!T) {
		this._sizeInBytes = elements.length * T.sizeof;
		GL.namedBufferData(id, elements.length * T.sizeof, elements.ptr, _style);
		debug isAllocated = true;
	}

	/// Allocates space for the given number of bytes within this buffer.
	/// The data should then be assigned using `setSubData`, as `setData` will allocate a new buffer.
	void allocData(size_t size) {
		this._sizeInBytes = size;
		GL.namedBufferData(id, size, null, _style);
		debug isAllocated = true;
	}

	/+/// Creates an immutable slice of this VBO.
	/// Params:
	/// 	Start = The number of elements within this VBO to return a segment for. For a VertexBuffer, this is the number of bytes. For an IndexBuffer, the number of elements.
	/// 	End = The last index (exclusive) to return a segment for.
	VBOSlice!(IsIndexBuffer) opSlice(uint start, uint end) {
		return VBOSlice!(IsIndexBuffer)(this, start, end);
	}+/

private:
	debug bool isAllocated;
	GLenum _style;
	size_t _sizeInBytes;

	debug void ensureValidStyle()(GLenum style) const {
		enforce(
			_style == GL_STATIC_DRAW || _style == GL_STATIC_COPY || _style == GL_STATIC_READ ||
			_style == GL_DYNAMIC_DRAW || _style == GL_DYNAMIC_COPY || _style == GL_DYNAMIC_READ ||
			_style == GL_STREAM_DRAW || _style == GL_STREAM_COPY || _style == GL_STREAM_READ
		);
	}

	void destroyResource(ResourceID id) {
		GL.deleteBuffers(1, &id);
	}
}

/// Convenience aliases to various buffer types.
alias VertexBuffer = GraphicsBuffer!(BufferType.vertex);
/// Ditto
alias IndexBuffer = GraphicsBuffer!(BufferType.index);
/// Ditto
alias UniformBufferStore = GraphicsBuffer!(BufferType.uniformStore);
/// Ditto
alias TextureBufferStore = GraphicsBuffer!(BufferType.textureStore);