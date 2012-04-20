module ShardGraphics.VBOSlice;
public import ShardGraphics.VertexBufferObject;

/// An immutable slice of a VertexBufferObject.
struct VBOSlice(bool IsIndexBuffer)  {

public:

	/// Initializes a new VertexBufferSlice.
	/// Params:
	/// 	VBO = The underlying VBO.
	/// 	Offset = The offset, in bytes, in VBO that this slice starts at.
	/// 	Size = The size, in bytes, of this slice.
	this(VertexBufferObject!(IsIndexBuffer) VBO, const uint Offset, const uint Size) {
		this.VBO = VBO;
		this.Offset = Offset;
		this.Size = Size;
	}

	/// The underlying VBO.
	const VertexBufferObject!(IsIndexBuffer) VBO;

	/// The offset, in bytes, in VBO that this slice starts at.
	const uint Offset;

	/// The size, in bytes, of this slice.
	const uint Size;

	/// The last byte included in this slice.
	@property uint End() const {
		return Offset + Size;
	}	
	
}

/// Represents a slice of a VertexBuffer.
alias const(VBOSlice!(false)) VertexBufferSlice;

/// Represents a slice of an IndexBuffer.
alias const(VBOSlice!(true)) IndexBufferSlice;