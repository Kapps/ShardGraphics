module ShardGraphics.Effect;
private import ShardTools.ArrayOps;
private import std.string;
public import ShardGraphics.UniformBuffer;
public import ShardGraphics.EffectPool;

public import ShardGraphics.GraphicsResource;
public import gl;
public import ShardGraphics.Shader;
public import ShardGraphics.GraphicsDevice;
private import ShardGraphics.GraphicsErrorHandler;
private import std.exception;
private import std.conv;

/// Represents an effect containing two or more shaders.
class Effect : GraphicsResource {

public:

	/// Initializes a new instance of the Effect object.
	/// Params:
	///		Shaders = The shaders to create the effect with.	
	this(Shader[] Shaders...) {		
		this(EffectPool.Default, Shaders);
	}

	/// Initializes a new instance of the Effect object.
	/// Params:
	///		Shaders		 = The shaders to create the effect with.
	/// 	Pool		 = The EffectPool this Effect belongs to. If null, the default EffectPool is used.	
	this(EffectPool Pool, Shader[] Shaders...) {
		if(Pool is null)
			Pool = EffectPool.Default;
		this._Pool = Pool;
		this.Shaders = cast(Shader[])Shaders.dup;		
		Compile();
		foreach(Shader shader; this.Shaders) {
			foreach(string Name; shader.UniformBlockNames) {
				if(!Contains(_Uniforms, Name))
					_Uniforms ~= Name;
			}
		}
		Pool.RegisterEffect(this);
	}	

	/// Gets the first shader of the specified type.
	///	Params:
	///		ShaderType = The type of the shader to get.
	/// Returns:
	///		The first shader of the specified type, or null if not found.
	Shader GetShader(ShaderType ShaderType) {
		for(size_t i = 0; i < Shaders.length; i++) {
			if(Shaders[i].Type == ShaderType)
				return Shaders[i];
		}
		return null;
	}

	/// Deletes the graphics resource represented by the given ID.
	/// Params:
	/// 	ID = The ID of the resource to delete.
	protected override void DeleteResource(uint ID){		
		if(GraphicsDevice.Program is this)
			GraphicsDevice.Program = null;
		for(size_t i = 0; i < Shaders.length; i++) {	
			if(Shaders[i]) // Make sure it's not null because we're being closed and dtor for it already called.
				glDetachShader(ID, Shaders[i].ResourceID);
		}
		glDeleteProgram(ID);		
	}

	/// Gets the EffectPool that this Effect belongs to.
	/// All Effects in a pool share the same uniform buffers.
	@property EffectPool Pool() {
		return _Pool;
	}

	/// Gets a collection of the names of the Uniforms that this Effect contains.
	@property const(string[]) Uniforms() const {
		return _Uniforms;
	}
	
private:
	void Compile() {
		GLuint ID = glCreateProgram();
		debug assert(ID != 0);
		ResourceID = ID;		
		debug {
			bool HasVertexShader = false;
			bool HasPixelShader = false;
		}
		foreach(Shader; Shaders) {			
			foreach(ShaderAttribute Attribute; Shader.Parameters.Values)
				Attribute.Bind(this);
			glAttachShader(ID, Shader.ResourceID);
			debug {
				if(Shader.Type == ShaderType.VertexShader) {
					enforce(!HasVertexShader, "A VertexShader already exists on this effect.");
					HasVertexShader = true;
				}
				if(Shader.Type == ShaderType.PixelShader) {
					enforce(!HasPixelShader, "A FragmentShader already exists on this effect.");
					HasPixelShader = true;
				}
			}						
		}
		debug enforce(HasVertexShader && HasPixelShader, "An effect did not have both a VertexShader and a FragmentShader.");
		glLinkProgram(ID);

		debug {
			int WasSuccess;					
			glGetProgramiv(ID, GL_LINK_STATUS, &WasSuccess);
			if(!WasSuccess) {
				int MaxLength;					
				glGetProgramiv(ID, GL_INFO_LOG_LENGTH, &MaxLength);
				MaxLength++;
				char[] InfoLog = new char[MaxLength];
				glGetProgramInfoLog(ID, MaxLength, &MaxLength, InfoLog.ptr);
				throw new Exception("An effect failed to link. " ~ to!string(InfoLog) ~ ".");
			}
		}
		/+foreach(Shader; Shaders)
			foreach(ShaderAttribute Attribute; Shader.Parameters.Values)
				Attribute.NotifyLinked(ResourceID);+/
		GraphicsErrorHandler.CheckErrors();
	}

	Shader[] Shaders;
	EffectPool _Pool;
	string[] _Uniforms;
}