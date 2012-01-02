module ShardGraphics.ShaderAttribute;
private import ShardGraphics.Sampler;
private import ShardGraphics.Effect;

public import ShardGraphics.Shader;
public import ShardGraphics.GraphicsResource;
public import ShardMath.Vector;
import ShardTools.ExceptionTools;
import gl;
import std.string;
import std.conv;
import std.traits;
import ShardGraphics.GraphicsErrorHandler;
private import ShardGraphics.Texture;
private import ShardTools.Logger;

mixin(MakeException("InvalidDataTypeException"));

/// An enum representing the type of a vertex element.
public enum VertexType : GLint {
	Single = 1,
	Double = 2,
	Boolean = 4,
	Integer = 8,		
	Vector2f = Single | VertexSize.One,
	Vector3f = Single | VertexSize.Two,
	Vector2d = Double | VertexSize.Two,
	Vector3d = Double | VertexSize.Three,
	Vector2b = Boolean | VertexSize.Two,
	Vector3b = Boolean | VertexSize.Three,
	Vector2i = Integer | VertexSize.Two,
	Vector3i = Integer | VertexSize.Three,
	Matrix2f = Single | VertexSize.Four,
	Matrix3f = Single | VertexSize.Nine,
	Matrix4f = Single | VertexSize.Sixteen,
	Matrix2d = Double | VertexSize.Four,
	Matrix3d = Double | VertexSize.Nine,
	Matrix4d = Double | VertexSize.Sixteen
}

/// Represents the size of a vertex.
public enum VertexSize {
	/// A single element.
	One = 16,
	/// A two-dimensional vector.
	Two = 32,
	/// A three-dimensional vector.
	Three = 64,
	/// A four-dimensional vector or two-dimensional matrix.
	Four = 128,
	/// A three-dimensional matrix.
	Nine = 256,
	/// A four-dimensional matrix.
	Sixteen = 512,
}

enum AttributeModifier : GLuint {
	None = 0,
	Uniform = 2,	
	Attribute = 4
}


/// Represents a single attribute inside a shader.
class ShaderAttribute {

public:
	/// Initializes a new instance of the ShaderAttribute object.
	/// Params:
	/// 	Name = The name of this attribute.
	/// 	Type = The type of this attribute.
	/// 	Modifiers = The modifiers for this attribute.
	this(in char[] Name, in char[] Type, AttributeModifier Modifiers) {
		this._Name = Name.idup;
		this._Type = Type.idup;
		this._Modifiers = Modifiers;
	}

	/+package void NotifyLinked(GLuint Program) {
		this.Program = Program;
		if(Modifiers != AttributeModifier.Uniform)
			this._Position = glGetAttribLocation(Program, _Name.ptr);
		else
			this._Position = -1;
	}+/

	package void Bind(Effect Program) {			
		this.Program = Program;		
		this._Position = -2;
	}

	/// Gets the name of the type of this attribute.
	@property string Type() const {
		return _Type;
	}

	/// Gets the name of this attribute.
	@property string Name() const {
		return _Name;
	}
	
	/// Gets the position this shader is bound to.
	@property int Position() {
		if(this._Position == -2) {
			if(IsUniform())
				_Position = GetUniformLocation();
			else
				_Position = glGetAttribLocation(Program.ResourceID, toStringz(_Name));
		}
		return _Position;
	}

	/// Gets the modifiers applied to this attribute.
	@property AttributeModifier Modifiers() const {
		return _Modifiers;	
	}

	/// Assigns the specified Value to this Attribute.
	/// This only applies if this Attribute has a Uniform modifier.
	/// Params:
	/// 	T = The type of the value to assign.
	/// 	Value = The value to assign to this attribute.
	 @property void Value(T)(T[] Value) {
		mixin(EnsureProgramSetMixin());
		GLuint UniformLoc = GetUniformLocation();
		assert(UniformLoc != -1);
		static if(is(T == float) || is(T == GLfloat))
			glUniform1fv(UniformLoc, Value.ptr, Value.length);
		else
			static assert(0, "Unknown type \'" ~ to!string(typeid(T)) ~ "\' to assign to an attribute.");
	}

	private static string EnsureProgramSetMixin() {
		//return "";
		return "Effect OldEffect = GraphicsDevice.Program; scope(exit) GraphicsDevice.Program = OldEffect; GraphicsDevice.Program = this.Program;";
	}

	/// Assigns the specified Value to this Attribute.
	/// This only applies if this Attribute has a Uniform modifier.
	/// If setting multiple values, performance will be better if the effect is already set on the graphics device.
	/// Params:
	/// 	T = The type of the value to assign.
	/// 	Value = The value to assign to this attribute.
	@property void Value(T)(T Value) {		
		mixin(EnsureProgramSetMixin());
		alias Unqual!T Type;
		GLuint UniformLoc = GetUniformLocation();
		assert(UniformLoc != -1);		
		static if(is(Type == float))
			glUniform1f(UniformLoc, Value);
		else static if(is(Type == int) || is(Type == uint))
			glUniform1i(UniformLoc, Value);
		else static if(is(Type == Color)) {						
			Vector4f ColorTmp = Value.ToVector4();
			if(Value.A != 255) // TODO: Check Type instead.
				glUniform4fv(UniformLoc, 1, ColorTmp.Elements.ptr);
			else
				glUniform3fv(UniformLoc, 1, ColorTmp.Elements.ptr);			
		} else static if(Type.stringof.length > 6 && Type.stringof[0..6] == "Vector") {
			alias Unqual!(Value.ElementType) ElementType;
			// Stringof to fix compiler errors.
			static assert(ElementType.stringof == "float" || ElementType.stringof == "double" || ElementType.stringof == "int" || ElementType.stringof == "uint", 
				"Element type for ShaderAttribute.Value (Vector) must be float, double, int, or uint, not " ~ ElementType.stringof ~ ".");			
			mixin("glUniform" ~ to!string(Value.NumElements) ~ ElementType.stringof[0..1] ~ "v(UniformLoc, Value.NumElements, Value.Elements.ptr);");
		} else static if(Type.stringof.length > 6 && Type.stringof[0..6] == "Matrix") {
			alias Unqual!(Value.ElementType) ElementType;
			static assert(ElementType.stringof == "float" || ElementType.stringof == "double" || ElementType.stringof == "int" || ElementType.stringof == "uint", 
						"Element type for ShaderAttribute.Value (Matrix) must be float, double, int, or uint, not " ~ ElementType.stringof ~ ".");			
			// TODO: Currently assumes NumRows == NumCols. Change to ColsxRows if not the case. But no ColsXRows when Cols == Rows.			
			mixin("glUniformMatrix" ~ to!string(Value.NumRows) ~ ElementType.stringof[0..1] ~ "v(UniformLoc, 1, GL_TRUE, Value.ElementsSingleDim.ptr);");
		} else static if(is(Type == Texture))
			static assert(0, "Textures may not be set directly, but instead should have a sampler set with their value and the sampler assigned to the GraphicsDevice.");
		else static if(is(Type == Sampler))
			glUniform1i(UniformLoc, Value.Slot);
		else
			static assert(0, "Unknown type \'" ~ Type.stringof ~ "\' to assign to an attribute.");
	}	

	/// Gets the value of this Attribute.
	/// This only applies if this Attribute has a Uniform modifier.
	/// Params:
	/// 	T = The type of the value to return.
	@property T Value(T)() {		
		// TODO: Use unqual.
		GLuint UniformLoc = GetUniformLocation();
		assert(UniformLoc != -1);
		static if(is(T == float) || is(T == GLfloat)) {
			float Result;
			glGetUniformfv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == int) || is(T == GLint)) {
			int Result;
			glGetUniformiv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == double) || is(T == GLdouble)) {
			double Result;
			glGetUniformdv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == bool) || is(T == GLboolean)) {
			bool Result;
			glGetUniformiv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == Vector2f)) {
			// TODO: Make all of these vectors just a mixin...
			Vector2f Result;
			glGetUniformfv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == Vector3f)) {
			Vector3f Result;
			glGetUniformfv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == Vector4f)) {
			Vector4f Result;
			glGetUniformfv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == Vector2i)) {
			Vector2i Result;
			glGetUniformiv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == Vector3i)) {
			Vector3i Result;
			glGetUniformiv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == Vector4i)) {
			Vector4i Result;
			glGetUniformiv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == Vector2d)) {
			Vector2d Result;
			glGetUniformdv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == Vector3d)) {
			Vector3d Result;
			glGetUniformdv(Program, UniformLoc, &Result);
			return Result;
		} else static if(is(T == Vector4d)) {
			Vector4d Result;
			glGetUniformdv(Program, UniformLoc, &Result);
			return Result;
		} else
			static assert(0, "Unable to get Uniform attribute of type \'" ~ T.stringof ~ "\'.");
		/*static if(is(T == Vector2b)) {
			Vector2b Result;
			glGetUniformiv(Program, UniformLoc, &Result);
			return Result;
		}
		static if(is(T == Vector3b)) {
			Vector3b Result;
			glGetUniformiv(Program, UniformLoc, &Result);
			return Result;
		}
		static if(is(T == Vector4b)) {
			Vector4b Result;
			glGetUniformiv(Program, UniformLoc, &Result);
			return Result;
		}*/
		//static assert(0, "Unable to get Uniform attribute of type \'" ~ to!string(typeid(T)) ~ "\'.");
	}

	/// Gets the uniform location of this shader.
	/// This method returns -1 if this attribute is not uniform.
	GLuint GetUniformLocation() {
		assert(IsUniform());
		if(_Position == -2)
			_Position = glGetUniformLocation(Program.ResourceID, toStringz(_Name));
		return _Position;
	}

	invariant() {
		GraphicsErrorHandler.AssertErrors();
	}

	/// Returns whether this ShaderAttribute contains the Uniform modifier.
	@property bool IsUniform() const {
		return (_Modifiers & AttributeModifier.Uniform) == AttributeModifier.Uniform;
	}
	
private:
	Effect Program;
	GLuint _Position;
	string _Name;
	string _Type;	
	AttributeModifier _Modifiers;	
}

/// Unused and untested.
enum : string {
	Void = "void",
	Bool = "bool",
	Int = "int",
	UInt = "uint",
	Float = "float",
	Double = "double",
	Vector2F = "vec2",
	Vector3F = "vec3",
	Vector4F = "vec4",
	Vector2B = "bvec2",
	Vector3B = "bvec3",
	Vector4B = "bvec4",
	Vector2D = "dvec2",
	Vector3D = "dvec3",
	Vector4D = "dvec4",
	Vector2I = "ivec2",
	Vector3I = "ivec3",
	Vector4I = "ivec4",
	Vector2U = "uvec2",
	Vector3U = "uvec3",
	Vector4U = "uvec4",
	Matrix2x2F = "mat2x2",
	Matrix2x3F = "mat2x3",
	Matrix2x4F = "mat2x4",
	Matrix3x2F = "mat3x2",
	Matrix3x3F = "mat3x3",
	Matrix3x4F = "mat3x4",
	Matrix4x2F = "mat4x2",
	Matrix4x3F = "mat4x3",
	Matrix4x4F = "mat4x4",
	vec2 = Vector2F,
	vec3 = Vector3F,
	vec4 = Vector4F,
	mat2 = Matrix2x2F,
	mat3 = Matrix3x3F,
	mat4 = Matrix4x4F,
	Matrix2x2D = "dmat2x2",
	Matrix2x3D = "dmat2x3",
	Matrix2x4D = "dmat2x4",
	Matrix3x2D = "dmat3x2",
	Matrix3x3D = "dmat3x3",
	Matrix3x4D = "dmat3x4",
	Matrix4x2D = "dmat4x2",
	Matrix4x3D = "dmat4x3",
	Matrix4x4D = "dmat4x4",
	vec2d = Vector2D,
	vec3d = Vector3D,
	vec4d = Vector4D,
	mat2d = Matrix2x2D,
	mat3d = Matrix3x3D,
	mat4d = Matrix4x4D,
	Sampler1D = "sampler1D",
	Sampler2D = "sampler2D",
	Sampler3D = "sampler3D",
	SamplerCube = "samplerCube",
	Sampler2DRect = "sampler2DRect",
	Sampler1DShadow = "sampler1DShadow",
	Sampler2DShadow = "sampler2DShadow",
	Sampler2DRectShadow = "sampler2DRect",
	Sampler1DArray = "sampler1DArray",
	Sampler2DArray = "sampler2DArray",
	Sampler1DArrayShadow = "sampler1DArrayShadow",
	Sampler2DArrayShadow = "sampler2DArrayShadow",
	SamplerBuffer = "samplerBuffer",
	Sampler2DMS = "sampler2DMS",
	Sampler2DMSArray = "sampler2DMSArray",
	SamplerCubeArray = "samplerCubeArray",
	SamplerCubeArrayShadow = "samplerCubeArrayShadow",
	Sampler1DI = "isampler1D",
	Sampler2DI = "isampler2D",
	Sampler3DI = "isampler3D",
	SamplerCubeI = "isamplerCube",
	Sampler2DRectI = "isampler2DRect",
	Sampler1DArrayI = "isampler1DArray",
	Sampler2DArrayI = "isampler2DArray",
	SamplerBufferI = "isamplerBuffer",
	Sampler2DMSI = "isampler2DMS",
	Sampler2DMSArrayI = "isampler2DMSArray",
	SamplerCubeArrayI = "isamplerCubeArray",
	Sampler1DU = "usampler1D",
	Sampler2DU = "usampler2D",
	Sampler3DU = "usampler3D",
	SamplerCubeU = "usamplerCube",
	Sampler2DRectU = "usampler2DRect",
	Sampler1DArrayU = "usampler1DArray",
	Sampler2DArrayU = "usampler2DArray",
	SamplerBufferU = "usamplerBuffer",
	Sampler2DMSU = "usampler2DMS",
	Sampler2DMSArrayU = "usampler2DMSArray",
	SamplerCubeArrayU = "usamplerCubeArray"
}

/+class ShaderAttribute {
	
}+/

/+
	public VertexType ParsedType() const {
		VertexType Result = cast(VertexType)0;
		bool IsMatrix = false;
		char[] Type = this._Type.dup;
		if(startsWith(Type, "mat")) {
			Result = VertexType.Single;
			IsMatrix = true;
		} else if(startsWith(Type, "dmat")) {
				Result = VertexType.Double;		
				IsMatrix = true;
		} else if(startsWith(Type, "vec"))
			Result = VertexType.Single;
		else if(Type.startsWith("bvec"))
			Result = VertexType.Boolean;
		else if(Type.startsWith("dvec"))
			Result = VertexType.Double;
		else if(Type.startsWith("ivec"))
			Result = VertexType.Integer;			
				
		if(Type.endsWith("2"))
			if(IsMatrix)
				Result |= VertexSize.Four;
			else
				Result |= VertexSize.Two;
		else if(Type.endsWith("3"))
			if(IsMatrix)
				Result |= VertexSize.Nine;				
			else
				Result |= VertexSize.Three;
		else if(Type.endsWith("4"))
			if(IsMatrix)
				Result |= VertexSize.Sixteen;
			else
				Result |= VertexSize.Four;			
		
		if(Result % 16 == 0)
			throw new InvalidDataTypeException("Unable to parse the VertexType defined by \'" ~ this._Type ~ "\'.");
			
		return Result;	
	}+/