module ShardGraphics.VertexDeclaration;
private import ShardGraphics.GLReflection;
private import std.traits;
private import ShardTools.Reflection;
private import std.exception;

public import ShardGraphics.VertexElement;
private import ShardGraphics.GraphicsErrorHandler;
private import ShardGraphics.GraphicsDevice;


/// Represents a collection of VertexElements that make up a VertexDeclaration.
class VertexDeclaration {

public:
	/// Initializes a new instance of the VertexDeclaration object.
	/// Params:
	/// 	Elements = The elements to create a VertexDeclaration from.
	this(VertexElement[] Elements...) {
		enforce(Elements.length > 0, "A vertex declaration must have one or more vertex elements.");
		this._Elements = Elements.dup;		
		_Stride = Elements[0].VertexSize;
	}

	/// Creates a VertexDeclaration for the given VertexShader.
	/// Params:
	/// 	T = The type of the vertices.
	/// 	VertShader = The vertex shader to create a declaration for.
	/// 	FieldToParameterMap = A map that indicates what shader attribute each field in T corresponds to. 
	///			For example, a shader with InPosition and a VertexPosition struct with a Position field, would have a value of "Position":"InPosition". Any fields not within this map are ignored.
	///			If null, no fields are skipped and it is assumed that the field is the same name as the shader value.
	static VertexDeclaration CreateForShader(T)(Shader VertShader, string[string] FieldToParameterMap) {
		VertexElement[] Elements = new VertexElement[FieldToParameterMap.length];
		size_t Next = 0;
		//T dummy = T.init;		
		//foreach(Field; Fields) {		
		T dummy = T.init;			
		foreach(Index, Field; dummy.tupleof) {
			alias typeof(Field) FieldType;			
			enum string FieldName = T.tupleof[Index].stringof[3 + T.stringof.length .. $];
			// alias typeof(__traits(getMember, T, Field)) FieldType;
			//alias typeof(mixin("T.init." ~ FixedName)) FieldType;		
			string ShaderAttrib;
			if(FieldToParameterMap !is null) {
				string* ShaderAttribPtr = (FieldName in FieldToParameterMap);
				if(ShaderAttribPtr is null)
					continue;
				ShaderAttrib = *ShaderAttribPtr;
			} else
				ShaderAttrib = FieldName;			
			ShaderAttribute Attrib = VertShader.Parameters[ShaderAttrib];
			enforce(Attrib !is null, "Did not find a corresponding attribute for " ~ ShaderAttrib ~ ".");			
			GLenum VertType = GetElementType!(FieldType)();
			enforce(VertType != 0, "Unable to figure out type mapping for " ~ FieldName ~ ".");
			GLsizei VertSize = GetElementSize!(FieldType)();
			enforce(VertSize != 0, "Unable to calculate number of elements for " ~ FieldName ~ ".");	
			VertexElement Element = VertexElement(Attrib.Position, VertType, VertSize, T.sizeof, __traits(getMember, dummy, FieldName).offsetof);
			if(FieldToParameterMap)
				Elements[Next++] = Element;
			else
				Elements ~= Element;
		}
		enforce(FieldToParameterMap == null || Next == Elements.length, "Did not match all parameters.");
		return new VertexDeclaration(Elements);
	}	

	invariant() {
		GraphicsErrorHandler.AssertErrors();
	}

	/// Gets the elements for this VertexDeclaration.
	@property VertexElement[] Elements() {
		return _Elements;
	}

	/// Gets the stride between each individual vertex.
	@property size_t Stride() const {
		return _Stride;	
	}
	
private:
	VertexElement[] _Elements;
	size_t _Stride;
}
