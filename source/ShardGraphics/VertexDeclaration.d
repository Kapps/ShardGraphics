module ShardGraphics.VertexDeclaration;
import ShardTools.Initializers;
import derelict.opengl3.gl3;
import std.typecons;
import std.traits;
import ShardMath.Vector;
import ShardMath.Matrix;
import ShardTools.Color;
import ShardTools.Udas;
import std.typetuple;
import ShardGraphics.GpuResource;
import std.conv;

/// Provides a collection of VertexAttributes stored together in a Vertex Declaration or Vertex Array Object.
struct VertexDeclaration {

	mixin GpuResource;

	/// Creates a new VertexArrayObject containing the given number of elements.
	this(size_t length) {
		this._length = length;
		GLuint id;
		glCreateVertexArrays(1, &id);
		this.id = id;
	}

	/// Returns the number of attributes in this declaration.
	@property size_t length() const {
		return _length;
	}

	/// Sets the attribute at the given index.
	void opIndexAssign(VertexAttribute attrib, size_t index) {
		if(index >= length)
			assert(0, "Index out of range.");
		glEnableVertexArrayAttrib(id, cast(uint)index);
		glVertexArrayAttribFormat(id, cast(uint)index, cast(int)attrib.count, attrib.type, false, cast(uint)attrib.offset);
	}

private:
	size_t _length;

	void destroyResource(ResourceID id) {
		glDeleteVertexArrays(1, &id);
	}
}

/// Creates a VertexDeclaration from the given type by enumerating over its fields and adding each as an attribute.
auto createDeclaration(T)() if(is(T == struct) && !hasIndirections!T) {
	static if(is(T == Vector!(N, ET), int N, ET) || is(T == Matrix!(N, ET), int N, ET)) {
		// Special handling for Vector/Matrix due to their containing unions.
		auto declaration = VertexDeclaration(1);
		declaration[0] = VertexAttribute(0, ElementCount!T, vertexElementType!T, 0);
	} else {
		auto declaration = VertexDeclaration(T.tupleof.length);
		foreach(i, val; T.init.tupleof) {
			alias VT = typeof(val);
			auto count = ElementCount!VT;
			auto type = vertexElementType!VT;
			auto offset = T.tupleof[i].offsetof;
			declaration[i] = VertexAttribute(i, count, type, offset);
		}
	}
	return declaration;
}

private template ElementCount(T_) {
	alias T = Unqual!T_;
	static if(is(T == Color))
		enum ElementCount = 4;
	else static if(is(T == Vector!(N, ET), int N, ET))
		enum ElementCount = N;
	else static if(is(T == Matrix!(N, ET), int N, ET))
		enum ElementCount = N * N;
	else
		enum ElementCount = 1;
}

private template ElementType(T_) {
	alias T = Unqual!T_;
	static if(is(T == Vector!(N, ET), int N, ET))
		alias ElementType = ET;
	else static if(is(T == Matrix!(N, ET), int N, ET))
		alias ElementType = ET;
	else static if(is(T == Color))
		alias ElementType = float;
	else
		alias ElementType = T;
}

private template TypeName(T_) {
	alias T = Unqual!T_;
	static if(is(typeof(__traits(identifier, T))))
		enum TypeName = __traits(identifier, T);
	else
		enum TypeName = T.stringof;
}

private template EnumNames(T, size_t index = 0) {
	static if(index < EnumMembers!T.length - 1)
		enum EnumNames = [__traits(identifier, EnumMembers!T[index])] ~ EnumNames!(T, index + 1);
	else
		enum EnumNames = [__traits(identifier, EnumMembers!T[index])];
}

private VertexElementType vertexElementType(T_)() {
	alias T = ElementType!(Unqual!T_);
	enum typeStr = TypeName!T ~ "_";
	static assert(is(typeof(to!VertexElementType(typeStr))), "Unable to determine element type for " ~ T_.stringof ~ ".");
	enum res = to!VertexElementType(typeStr);
	return res;
}

@name("ElementCount Tests")
unittest {
	assert(ElementCount!int == 1);
	assert(is(ElementType!int == int));
	assert(vertexElementType!int == VertexElementType.int_);

	assert(ElementCount!Vector3f == 3);
	assert(is(ElementType!Vector3f == float));
	assert(vertexElementType!Vector3f == VertexElementType.float_);

	assert(ElementCount!Matrix4d == 16);
	assert(is(ElementType!Matrix4d == double));
	assert(vertexElementType!Matrix4d == VertexElementType.double_);
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

	this(size_t index, size_t count, VertexElementType type, size_t offset) {
		this.index = index;
		this.count = count;
		this.type = type;
		this.offset = offset;
	}
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