﻿module ShardGraphics.VertexBufferObject;
private import std.conv;
public import ShardGraphics.GraphicsResource;
public import ShardGraphics.VBOSlice;
private import ShardGraphics.GraphicsErrorHandler;
private import ShardGraphics.GraphicsDevice;
public import gl;


/// Determines how vertex data will be modified.
enum BufferUseHint {	
	/// The data will be set once and used multiple times.
	Static = GL_STATIC_DRAW - 1,
	/// The data will be set once, used once, repeated any number of times.
	Stream = GL_STREAM_DRAW - 1,
	/// The data will be set multiple times then used multiple times.
	Dynamic = GL_DYNAMIC_DRAW - 1
}

/// Determines how vertex data will be accessed.
enum BufferAccessHint {	
	/// The data is generated by the application then passed to the graphics API for rendering.
	WriteOnly = 1,
	/// The data is generated by the graphics API and read from the application.
	ReadOnly = 2,
	/// The data is generated or read both by the graphics API and the application.
	ReadWrite = 3
}

/// A class representing a single VBO; either vertices or indices.
/// Params:
///		IsIndexBuffer = Whether this VertexBufferObject stores indices as opposed to vertices.
final class VertexBufferObject(bool IsIndexBuffer) : GraphicsResource {

public:
	/// Initializes a new instance of the VertexBuffer object.
	this() {
		GLuint BufferID;
		glGenBuffers(1, &BufferID);
		assert(BufferID != 0);
		this.ResourceID = BufferID;		
	}

	/// Sets the data for this buffer to the specified value.	
	/// Params:		
	/// 	Elements = The elements to set on this VertexBuffer.
	///		VertexUseHint = Determines how the data will be used.
	///		AccessHint = Determines how the data will be accessed.
	/// 	ElementSize = The size of a single element in this buffer. For an IndexBuffer, this is either 2 or 4. For a VertexBuffer, this is the size of the vertices it contains.
	void SetData(T)(in T[] Elements, uint ElementSize, BufferUseHint UseHint, BufferAccessHint AccessHint) {
		GLenum Style = UseHint + AccessHint;
		debug EnsureValidStyle(Style);			
		debug IsDataSet = true;
		_SizeInBytes = Elements.length * T.sizeof;
		_ElementSize = ElementSize;
		static if(IsIndexBuffer) {
			IndexBuffer OldBuffer = GraphicsDevice.Indices;
			GraphicsDevice.Indices = this;						
			glBufferData(GL_ELEMENT_ARRAY_BUFFER, Elements.length * T.sizeof, Elements.ptr, Style);		
			GraphicsDevice.Indices = OldBuffer; 
		} else {
			VertexBuffer OldBuffer = GraphicsDevice.Vertices;
			GraphicsDevice.Vertices = this;
			glBufferData(GL_ARRAY_BUFFER, Elements.length * T.sizeof, Elements.ptr, Style);		
			GraphicsDevice.Vertices = OldBuffer;		
		}
	}

	/// Gets the total size, in bytes, of this VBO.
	@property uint SizeInBytes() const {
		return _SizeInBytes;
	}

	/// Returns the size, in bytes, of a single element in this buffer.
	/// For an IndexBuffer, this is the size of the indices (2, or 4).
	/// For a VertexBuffer, this is the size of the vertex.
	@property uint ElementSize() const {
		return _ElementSize;
	}

	/// Gets the number of elements contained within this buffer.
	@property uint NumElements() const {
		return SizeInBytes / ElementSize;
	}

	/+ /// Returns a pointer to the contents of this buffer in the form of an array. This array should never be stored.
	/// While a buffer is mapped, it is not safe to make any calls that alter the state of the buffer.
	/// A buffer may not be mapped until SetData has been called at least once, as it specifies the size of the buffer.
	/// Params:
	/// 	AccessStyle = Determines the data to put in the buffer. It is important that you do not attempt to access the buffer in a way not defined by this parameter.
	///		Offset = The number of bytes within the buffer for the start of the map.
	///		Length = The number of bytes the map contains.
	void[] RequestMap(VertexAccessHint AccessStyle, uint Offset, uint Length) {
		debug assert(IsDataSet);
		GLenum Style = AccessStyle == VertexAccessHint.ReadOnly ? GL_MAP_READ_BIT : AccessStyle == VertexAccessHint.WriteOnly ? GL_MAP_WRITE_BIT : GL_MAP_READ_BIT | GL_MAP_WRITE_BIT;
		void* Result = glMapBufferRange(ResourceID, 0, Length, Style);
		return Result[0 .. length];
	}

	/// Flushes the given subrange of the currently active map.
	/// This must be called before the given subrange mapped can be used again, and may be called multiple times for different regions.
	/// Params:
	/// 	Offset = The offset within the map to flush. Important: Relative to the map, not the buffer.
	/// 	Length = The number of bytes within the map to flush.
	bool FlushMap(uint Offset, uint Length) {
		return true;	
	}+/

	/// Sets the data for this buffer to the specified value.	
	/// Params:
	///		Data = The data to set on to this buffer.
	///		Offset = The offset, in bytes from the start of the buffer, at which to set the data.
	///		SizeInBytes = The size, in bytes, of the data inside data.
	void SetOffsetData(T)(in T[] Data, sizediff_t Offset) if(is(T == struct)) {
		debug assert(IsDataSet);
		static if(IsIndexBuffer) {
			IndexBuffer OldBuffer = GraphicsDevice.Indices;
			GraphicsDevice.Indices = this;
			glBufferSubData(GL_ELEMENT_ARRAY_BUFFER, Offset, Data.length * T.sizeof, Data.ptr);
			GraphicsDevice.Indices = OldBuffer;
		} else {
			VertexBuffer OldBuffer = GraphicsDevice.Vertices;
			GraphicsDevice.Vertices = this;
			glBufferSubData(GL_ARRAY_BUFFER, Offset, Data.length * T.sizeof, Data.ptr);
			GraphicsDevice.Vertices = OldBuffer;
		}
	}

	/// Returns a boolean value indicating whether this buffer is a VertexBuffer as opposed to an IndexBuffer.
	@property bool IsVertexBuffer() const {
		return !IsIndexBuffer;
	}

	/// Deletes the graphics resource represented by the given ID.
	/// Params:
	/// 	ID = The ID of the resource to delete.
	protected override void DeleteResource(GLuint ID) {		
		if(IsIndexBuffer && GraphicsDevice.Indices is this)
			GraphicsDevice.Indices = null;
		else if(!IsIndexBuffer && GraphicsDevice.Vertices is this)
			GraphicsDevice.Vertices = null;
		glDeleteBuffers(1, &ID);
	}

	/// Creates an immutable slice of this VBO.
	/// Params:
	/// 	Start = The number of elements within this VBO to return a segment for. For a VertexBuffer, this is the number of bytes. For an IndexBuffer, the number of elements.
	/// 	End = The last index (exclusive) to return a segment for.
	VBOSlice!(IsIndexBuffer) opSlice(size_t Start, size_t End) {
		return VBOSlice!(IsIndexBuffer)(this, Start, End);
	}	
	
private:
	debug bool IsDataSet = false;
	uint _SizeInBytes;
	uint _ElementSize;

	void EnsureValidStyle(GLenum Style) const {		
		debug assert(
			Style == GL_STATIC_DRAW || Style == GL_STATIC_COPY || Style == GL_STATIC_READ ||
			Style == GL_DYNAMIC_DRAW || Style == GL_DYNAMIC_COPY || Style == GL_DYNAMIC_READ ||
			Style == GL_STREAM_DRAW || Style == GL_STREAM_COPY || Style == GL_STREAM_READ
		);		
	}

}

alias VertexBufferObject!(false) VertexBuffer;
alias VertexBufferObject!(true) IndexBuffer;