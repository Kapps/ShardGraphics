module ShardGraphics.GLReflection;
private import ShardTools.Color;
private import std.traits;
private import gl;

/// Gets the number of GL elements in the given type.
/// Vector3f for example, would return 3.
GLsizei GetElementSize(T)() {
	alias Unqual!(T) FieldType;		
	static if(is(FieldType == float) || is(FieldType == int) || is(FieldType == uint) || is(FieldType == double))
		return 1;
	else static if(is(FieldType == Color))
		return 3;
	else static if(FieldType.stringof.length > 6 && FieldType.stringof[0..6] == "Vector")			
		return FieldType.NumElements;
	else static if(FieldType.stringof.length > 6 && FieldType.stringof[0..6] == "Matrix")
		return FieldType.NumRows; // TODO: If that ever changes to not NumCols...
	else
		static assert(0, "Unknown type to get the size of.");		
}

/// Gets the GL type for the given type.
/// Vector3f for example, would return GL_FLOAT.
GLenum GetElementType(T)() {
	alias Unqual!(T) FieldType;
	static if(is(FieldType == float))
		return GL_FLOAT;
	else static if(is(FieldType == int) || is(FieldType == uint)) 
		return GL_INT;
	else static if(is(FieldType == double))
		return GL_DOUBLE;
	else static if(is(FieldType == Color))
		return GL_FLOAT;
	else static if(FieldType.stringof.length > 6 && (FieldType.stringof[0..6] == "Vector" || FieldType.stringof[0..6] == "Matrix")) {				
		return GetElementType!(FieldType.ElementType);		
	} else
		static assert(0, "Unknown type to get the element type for.");		
}