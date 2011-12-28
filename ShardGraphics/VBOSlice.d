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
	this(VertexBufferObject!(IsIndexBuffer) VBO, const size_t Offset, const size_t Size) {
		this.VBO = VBO;
		this.Offset = Offset;
		this.Size = Size;
	}

	/// The underlying VBO.
	const VertexBufferObject!(IsIndexBuffer) VBO;

	/// The offset, in bytes, in VBO that this slice starts at.
	const size_t Offset;

	/// The size, in bytes, of this slice.
	const size_t Size;

	/// The last byte included in this slice.
	@property size_t End() const {
		return Offset + Size;
	}	
	
}

/// Represents a slice of a VertexBuffer.
alias const(VBOSlice!(false)) VertexBufferSlice;

/// Represents a slice of an IndexBuffer.
alias const(VBOSlice!(true)) IndexBufferSlice;