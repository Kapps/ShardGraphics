module ShardGraphics.VertexDeclaration;
import ShardTools.Initializers;
import derelict.opengl3.gl3;
import std.typecons;
import std.traits;

/// Provides a collection of VertexAttributes that are used for a single render.
/// Optionally allows specifying a capacity as a template, which if non-zero will
/// result in the attributes being allocated on the stack rather than being RefCounted
/// and allocated on the heap.
template VertexDeclaration(size_t numElements = 0) {
	static if(numElements == 0)
		alias VertexDeclaration = RefCounted!(VertexDeclarationImpl, RefCountedAutoInitialize.no);
	else
		alias VertexDeclaration = VertexDeclarationImpl!(numElements);
}

/// Ditto
struct VertexDeclarationImpl(size_t numElements = 0) {
	/// No default constructor allowed.
	@disable this();

	static if(numElements == 0) {
		/// Creates a new VertexDeclaration of `attribCount` uninitialized elements.
		/// The user is responsible for assigning all elements prior to a render call.
		this(size_t attribCount) {
			_attributes = mallocNew!(VertexAttribute[])(capacity);
		}
		/// Creates a new VertexDeclaration by duplicating an existing array on the heap using `malloc`.
		this(VertexAttribute[] attributes) {
			_attributes = attributes.mallocDup;
		}
		/// Releases the manual memory allocated by the VertexDeclaration when using a non-fixed size.
		~this() {
			if(_attributes.length)
				_attributes.mallocFree();
		}
	} else {
		/// Creates a VertexDeclaration from an existing static array of attributes.
		this(VertexAttribute[numElements] attributes) {
			this._attributes = attributes;
		}
	}

	/// Creates a VertexDeclaration by specifying each attribute as an argument.
	this(T...)(T elements) if(numElements == 0 || elements.length == numElements) {
		static if(numElements == 0)
			this._attributes = mallocNew!(VertexAttribute[])(elements.length);
		for(size_t i = 0; i < T.length; i++)
			this._attributes[i] = elements[i];
	}

	/// Returns the number of attributes in this declaration.
	@property size_t length() const {
		return _attributes.length;
	}

	/// Gets or sets the attribute at the given index.
	VertexAttribute opIndex(size_t index) {
		return _attributes[index];
	}

	/// Ditto
	void opIndexAssign(VertexAttribute attrib, size_t index) {
		_attributes[index] = attrib;
	}

	/// Returns a range of the attributes set on this declaration.
	@property auto attributes() {
		return _attributes;
	}

private:
	VertexAttribute[] _attributes;
}

/// Creates a VertexDeclaration from the given type by enumerating over its fields and adding each as an attribute.
auto createDeclaration(T)() if(is(T == struct) && !hasIndirections!T) {
	alias FieldTup = Select!(is(T == struct), T.tupleof, Tuple!(T));
	VertexDeclaration!(FieldTup.length) declaration;
	foreach(val; T.tupleof) {

	}
}

/// Represents a single vertex attribute used for rendering.
/// An attribute represents the location within a VertexBuffer of individual fields.
/// This struct is immutable, but its members are API-dependent.
struct VertexAttribute {
	/// The index of this attribute. Must correspond with a shader index.
	const size_t index;
	/// The number of elements of `type` within a single vertex.
	/// For example, a Vector3f would be 3 floats.
	const size_t count;
	/// The type of the elements within a vertex.
	/// There can be multiple of an element packed within a single vertex.
	/// For example, a Vector3f would be 3 floats.
	const VertexElementType type;
	/// The offset, in bytes, within the vertex that this attribute is located at.
	const size_t offset;
}

/// Indicates the type of the values within a vertex.
enum VertexElementType {
	///
	byte_ = GL_BYTE,
	///
	ubyte_ = GL_UNSIGNED_BYTE,
	///
	short_ = GL_SHORT,
	///
	ushort_ = GL_UNSIGNED_SHORT,
	///
	int_ = GL_INT,
	///
	uint_ = GL_UNSIGNED_INT,
	///
	half_ = GL_HALF_FLOAT,
	///
	float_ = GL_FLOAT,
	///
	double_ = GL_DOUBLE,
}