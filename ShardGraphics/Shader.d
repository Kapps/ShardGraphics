module ShardGraphics.Shader;
public import ShardGraphics.GraphicsResource;
public import ShardGraphics.ShaderParameterCollection;
public import ShardGraphics.ShaderAttribute;
public import gl;
private import ShardGraphics.GraphicsDevice;
private import ShardGraphics.GraphicsErrorHandler;
private import std.exception;

public import ShardGraphics.VertexDeclaration;

/// Represents the type of shader being used.
public enum ShaderType {	
	PixelShader = GL_FRAGMENT_SHADER,
	VertexShader = GL_VERTEX_SHADER,
	GeometryShader = GL_GEOMETRY_SHADER
}

/// Represents a single shader inside an effect.
final class Shader : GraphicsResource {

public:
	/// Initializes a new instance of the Shader object.
	/// Params:
	///		Type = The type of this shader, such as VertexShader.
	///		Source = The source code to compile the shader with.
	///		Attributes = The attributes the shader contains.
	this(ShaderType Type, string[] UniformBlockNames, in char[] Source, ShaderAttribute[] Attributes) {
		assert(Type == ShaderType.PixelShader || Type == ShaderType.VertexShader || Type == ShaderType.GeometryShader);
		this._Type = Type;
		this._Parameters = new ShaderParameterCollection(Attributes);
		this._Source = Source.idup;
		this.UniformBlockNames = UniformBlockNames.dup;		
		GLuint ID = glCreateShader(cast(GLenum)Type);
		this.ResourceID = ID;
		GenerateShader(Source);				
	}

	/// Gets the parameters this Shader contains.
	@property ShaderParameterCollection Parameters() {
		return _Parameters;
	}

	/// Gets the type of this Shader, a value from the ShaderType enum.
	@property ShaderType Type() const {
		return _Type;
	}

	/// Gets the Effect owning this Shader, provided that this Shader has been successfully linked to an Effect.
	@property Effect Parent() {
		return _Parent;
	}

	@property package void Parent(Effect Value) {
		_Parent = Value;
	}

	/// Deletes the graphics resource represented by the given ID.
	/// Params:
	/// 	ID = The ID of the resource to delete.
	protected override void DeleteResource(GLuint ID) {		
		glDeleteShader(ID);					
	}	

	/// Creates a copy of this Shader, but does not copy over the uniform parameters.
	Shader Clone() {
		ShaderAttribute[] Attribs = this.Parameters.Values.dup;
		for(size_t i = 0; i < Attribs.length; i++)
			Attribs[i] = new ShaderAttribute(Attribs[i].Name, Attribs[i].Type, Attribs[i].Modifiers);
		return new Shader(Type, UniformBlockNames, _Source, Attribs);
	}

	package string[] UniformBlockNames;

	package void Reload(string[] UniformBlockNames, in char[] Source, ShaderAttribute[] Attributes) {
		this._Parameters.Rebind(Attributes);
		this._Source = Source.idup;
		this.UniformBlockNames = UniformBlockNames.dup;
		GenerateShader(Source);
		if(Parent)
			Parent.Relink();
	}
	
private:

	void GenerateShader(in char[] Source) {		
		const char* SourcePtr = Source.ptr;
		enforce(Source != null, "The source for the shader was null.");
		GLint* length = new GLint();
		*length = cast(int)Source.length;
		glShaderSource(ResourceID, 1, &SourcePtr, length);
		glCompileShader(ResourceID);		
		int Result;
		glGetShaderiv(ResourceID, GL_COMPILE_STATUS, &Result);
		if(Result != GL_TRUE) {
			char[2048] ErrorMessage;
			int ActualSize;
			glGetShaderInfoLog(ResourceID, 2048, &ActualSize, ErrorMessage.ptr);
			throw new Exception("A shader failed to compile. Details: \'" ~ ErrorMessage[0..ActualSize].idup ~ "\'.");
		}			
	}

	ShaderType _Type;
	ShaderParameterCollection _Parameters;
	string _Source;
	Effect _Parent;
}