module ShardGraphics.ShaderParameter;
//private import ShardGraphics.Sampler;
//private import ShardGraphics.Effect;

import ShardGraphics.Shader;
import ShardGraphics.GpuResource;
import ShardMath.Vector;
import ShardTools.ExceptionTools;
import std.string;
import std.conv;
import std.traits;
private import ShardTools.Logger;
import ShardTools.ScopeString;
import std.traits;
import ShardTools.Color;
import derelict.opengl3.gl3;
import ShardGraphics.Effect;
import gl;

mixin(MakeException("InvalidDataTypeException"));

@nogc:

/// Indicates the type of a shader parameter, in particular an attribute or uniform.
enum ParameterKind : GLuint {
	uniform = 1,
	attribute = 2
}


/// Represents a single variable within a shader.
struct ShaderParameter {

public:
	/// Creates a new ShaderParameter with the given details.
	this(string name, string fieldType, ParameterKind kind) {
		this._name = name;
		this._fieldType = fieldType;
		this._kind = kind;
		this._position = -1;
	}

	/+package void NotifyLinked(GLuint Program) {
		this.Program = Program;
		if(Modifiers != AttributeModifier.Uniform)
			this._Position = glGetAttribLocation(Program, _Name.ptr);
		else
			this._Position = -1;
	}+/
	/// Gets the name of the type of this attribute.
	@property string fieldType() const {
		return _fieldType;
	}

	/// Gets the name of this attribute.
	@property string name() const {
		return _name;
	}

	/// Gets the position this attribute is bound to.
	/// If this shader is not currently bound, -1 is returned.
	@property size_t position() {
		return _position;
	}

	/// Indicates whether this parameter is a uniform or attribute.
	@property ParameterKind kind() const {
		return _kind;
	}

	/// Assigns the specified Value to this Attribute.
	/// This only applies if this Attribute has a Uniform modifier.
	/// Params:
	/// 	T = The type of the value to assign.
	/// 	Value = The value to assign to this attribute.
	@property void value(T)(T[] val) {
		static if(is(T == float) || is(T == GLfloat))
			GL.uniform1fv(position, val.ptr, val.length);
		else
			static assert(0, "Unknown type \'" ~ to!string(typeid(T)) ~ "\' to assign to an attribute.");
	}

	/// Assigns the specified Value to this Attribute.
	/// This only applies if this Attribute has a Uniform modifier.
	/// If setting multiple values, performance will be better if the effect is already set on the graphics device.
	/// Params:
	/// 	T = The type of the value to assign.
	/// 	Value = The value to assign to this attribute.
	@property void value(T)(T val) {
		alias Unqual!T Type;
		auto uniformLoc = getUniformLocation();
		assert(uniformLoc != -1);
		static if(is(Type == float))
			GL.uniform1f(uniformLoc, Value);
		else static if(is(Type == int) || is(Type == uint))
			GL.uniform1i(uniformLoc, Value);
		else static if(is(Type == Color)) {
			Vector4f colorTmp = value.ToVector4();
			if(value.A != 255) // TODO: Check Type instead.
				GL.uniform4fv(uniformLoc, 1, colorTmp.Elements.ptr);
			else
				GL.uniform3fv(uniformLoc, 1, colorTmp.Elements.ptr);
		} else static if(Type.stringof.length > 6 && Type.stringof[0..6] == "Vector") {
			alias Unqual!(Value.ElementType) ElementType;
			// Stringof to fix compiler errors.
			static assert(ElementType.stringof == "float" || ElementType.stringof == "double" || ElementType.stringof == "int" || ElementType.stringof == "uint",
			              "Element type for ShaderAttribute.value (Vector) must be float, double, int, or uint, not " ~ ElementType.stringof ~ ".");
			mixin("glUniform" ~ to!string(Value.NumElements) ~ ElementType.stringof[0..1] ~ "v(uniformLoc, val.NumElements, val.elements.ptr);");
		} else static if(Type.stringof.length > 6 && Type.stringof[0..6] == "Matrix") {
			alias Unqual!(Value.ElementType) ElementType;
			static assert(ElementType.stringof == "float" || ElementType.stringof == "double" || ElementType.stringof == "int" || ElementType.stringof == "uint",
			              "Element type for ShaderAttribute.value (Matrix) must be float, double, int, or uint, not " ~ ElementType.stringof ~ ".");
			// TODO: Currently assumes NumRows == NumCols. Change to ColsxRows if not the case. But no ColsXRows when Cols == Rows.
			mixin("glUniformMatrix" ~ to!string(Value.NumRows) ~ ElementType.stringof[0..1] ~ "v(uniformLoc, 1, GL_TRUE, val.elementsSingleDim.ptr);");
		} else static if(is(Type == Texture)) {
			static assert(0, "Textures may not be set directly, but instead should have a sampler set with their value and the sampler assigned to the GraphicsDevice.");
		} else static if(is(Type == Sampler))
			GL.uniform1i(UniformLoc, Value.Slot);
		else
			static assert(0, "Unknown type \'" ~ Type.stringof ~ "\' to assign to an attribute.");
	}

	/// Gets the value of this Attribute.
	/// This only applies if this Attribute has a Uniform modifier.
	/// Params:
	/// 	T = The type of the value to return.
	@property T value(T)() {
		// TODO: Use unqual.
		// TODO: Refactor.
		GLuint uniformLoc = GetUniformLocation();
		assert(uniformLoc != -1);
		enum suffixStr = uniformFunSuffix!T;
		alias UniformType = Select!(is(T == Color), Vector4f, T);
		UniformType result;
		static if(is(T == Color))
			result.a = 255;
		mixin("glGetUniform" ~ suffixStr ~ "(_programID, uniformLoc, &result);");
		static if(is(T == Color))
			return Color(result);
		else
			return result;
	}

	private template uniformFunSuffix(Type) {
		static if(is(T == float) || is(T == GLfloat))
			enum uniformFunSuffix = "fv";
		else static if(is(T == int) || is(T == GLint))
			enum uniformFunSuffix = "iv";
		else static if(is(T == double) || is(T == GLdouble))
			enum uniformFunSuffix ="dv";
		else static if(is(T == bool) || is(T == GLboolean))
			enum uniformFunSuffix = "iv";
		else static if(is(T == Vector!(N, ET), size_t N, ET))
			enum uniformFunSuffix = getUniformFunString!(ET);
		else static if(is(T == Matrix!(N, ET), size_t N, ET))
			enum uniformFunSuffix = getUniformFunString!(ET);
		else
			static assert(0, "Unable to get Uniform attribute of type \'" ~ T.stringof ~ "\'.");
	}

	/// Binds this parameter to the given program.
	/// This is required prior to using the attribute.
	void bind(ref Effect program) {
		auto buff = _name.scoped;
		alias QueryDg = int function(ResourceID, void*);
		auto queryFun = cast(QueryDg)(kind == ParameterKind.uniform ? &glGetUniformLocation : &glGetAttribLocation);
		this._programID = program.id;
		this._position = queryFun(_programID, buff.ptr);
	}

private:
	string _name;
	string _fieldType;
	ParameterKind _kind;
	ResourceID _programID;
	size_t _position;
}