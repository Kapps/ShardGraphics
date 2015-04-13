module ShardGraphics.Effect;

private import std.string;
public import ShardGraphics.UniformBuffer;
public import ShardGraphics.EffectPool;

public import ShardGraphics.GpuResource;
import gl;
public import ShardGraphics.Shader;
private import std.exception;
private import std.conv;
import ShardTools.ExceptionTools;
import ShardTools.Initializers;;
import std.typecons;
import std.container.array;
import core.stdc.stdlib;
import ShardTools.Logger;
import std.algorithm;

/// Represents an effect containing two or more shaders.
struct Effect {

public:

	/// Initializes a new instance of the Effect object.
	/// Params:
	///		shaders		 = The shaders to create the effect with.
	/// 	pool		 = The EffectPool this Effect belongs to. If null, the default EffectPool is used.
	this(EffectPool pool, Shader[] shaders...) {
		if(pool is null)
			pool = EffectPool.global;
		this._pool = pool;
		this._shaders = _shaders.mallocDup;
		this.id = GL.createProgram();
		link();
	}

	mixin GpuResource;

	/// Gets the EffectPool that this Effect belongs to.
	/// All Effects in a pool share the same uniform buffers.
	@property EffectPool pool() {
		return _pool;
	}

	/// Gets a range of the names of the uniforms that this Effect contains.
	@property auto uniforms() {
		return _uniforms[];
	}

	/// Gets the first shader of the specified type.
	///	Params:
	///		shaderType = The type of the shader to get.
	/// Returns:
	///		The first shader of the specified type, or $(D Shader.init) if not found.
	Shader getShader(ShaderType shaderType) {
		auto res = _shaders.filter!(c=>c.type == shaderType);
		return res.empty ? Shader.init : res.front;
	}

	/+package void Relink() {
		link();
	}+/

private:

	void dispose() {
		_shaders.mallocFree();
	}
	
	void destroyResource(ResourceID id) {
		foreach(ref s; _shaders) {
			GL.detachShader(id, s.id);
			s = Shader.init;
		}
		GL.deleteProgram(id);
	}

	void link() {
		compile();
		_uniforms.clear();
		foreach(shader; this._shaders) {
			foreach(name; shader.uniformBlockNames) {
				if(!_uniforms[].canFind(name))
					_uniforms.insertBack(name);
			}
		}
		pool.registerEffect(this);
	}

	void compile() {
		debug {
			bool hasVertexShader = false;
			bool hasFragmentShader = false;
		}
		foreach(s; _shaders) {
			foreach(attribute; s.params[])
				attribute.bind(this);
			GL.attachShader(id, s.id);
			debug {
				if(s.type == ShaderType.vertex) {
					enforceNoGC!(Exception, "A VertexShader already exists on this effect.")(!hasVertexShader);
					hasVertexShader = true;
				}
				if(s.type == ShaderType.fragment) {
					enforceNoGC!(Exception, "A FragmentShader already exists on this effect.")(!hasFragmentShader);
					hasFragmentShader = true;
				}
			}
		}
		debug enforceNoGC!(Exception, "An effect did not have both a VertexShader and a FragmentShader.")(hasVertexShader && hasFragmentShader);
		GL.linkProgram(id);

		int wasSuccess;
		GL.getProgramiv(id, GL_LINK_STATUS, &wasSuccess);
		if(!wasSuccess) {
			int maxLength;
			GL.getProgramiv(id, GL_INFO_LOG_LENGTH, &maxLength);
			char* logBuff = cast(char*)malloc(maxLength + 1);
			scope(exit)
				free(logBuff); // Can't use alloca due to exception.
			GL.getProgramInfoLog(id, maxLength, &maxLength, logBuff);
			logBuff[maxLength] = '\0';
			logwf("Failed to link effect: %s", logBuff);
			throw new Exception("An effect failed to link.");
		}
	}

	Shader[] _shaders;
	EffectPool _pool;
	Array!string _uniforms;
	ResourceID _id;
}