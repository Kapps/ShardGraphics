module ShardGraphics.VertexElement;

import gl;
import ShardGraphics.GraphicsDevice;
public import ShardGraphics.ShaderAttribute;
import ShardTools.ExceptionTools;
import std.algorithm;
import std.conv;



/// Represents a single element in a Vertex, such as a Position or Color.
struct VertexElement {
	// TODO: Use reflection to generate this.
	// TODO: Revert to const once the glitch with not being mutable is fixed.

	/// The position of the attribute represented by this element.
	int Position;	
	
	/// The type of this vertex, such as GL_FLOAT.
	GLenum Type;

	/// The number of Type in this vertex. For example, a Vector3 would be 3.
	GLuint Size;

	/// The number of bytes between each consecutive vertex in the array. Generally, the size of the vertex structure being used.
	GLsizei VertexSize;
	
	/// The distance, in bytes, between the start of each vertex and this element.
	GLsizei VertexOffset;

	/// Initializes a new instance of the VertexElement struct.	
	this(int Position, GLenum Type, GLint Size, GLsizei VertexSize, GLsizei VertexOffset) {
		this.Position = Position;
		this.Type = Type;		
		this.Size = Size;
		this.VertexSize = VertexSize;	
		this.VertexOffset = VertexOffset;		
	}

	/// Enables this VertexElement for rendering.
	/// This should usually be called only by the GraphicsDevice, due to caching reasons.
	/// To enable an element, set a VertexDeclaration containing it on the GraphicsDevice.
	package void Enable() {
		glVertexAttribPointer(Position, Size, Type, GL_FALSE, VertexSize, cast(void*)VertexOffset);
		glEnableVertexAttribArray(Position);	
	}

	/// Disables this VertexElement.
	/// For caching reasons, this should usually be called only by the GraphicsDevice.
	/// To disable an element, remove the VertexDeclaration containing it from the GraphicsDevice.
	package void Disable() {
		glDisableVertexAttribArray(Position);		
	}
}
