module ShardGraphics.Shader;

public import ShardGraphics.GpuResource;
public import ShardGraphics.ShaderParameter;
private import std.exception;

import ShardTools.Initializers;
import ShardTools.Logger;
import std.typecons;
import ShardGraphics.GpuResource;
import ShardTools.ExceptionTools;
import derelict.opengl3.gl3;
import gl;

/// Represents the type of shader being used.
public enum ShaderType {
	fragment = GL_FRAGMENT_SHADER,
	vertex = GL_VERTEX_SHADER,
	geometry = GL_GEOMETRY_SHADER
}

/// Represents a single shader inside an effect.
struct Shader {

public:

	/// Creates a new Shader with the given pre-populated data.
	this(ShaderType type, string[] uniformBlockNames, string source, ShaderParameter[] params) {
		//assert(type == ShaderType.fragment || type == ShaderType.vertex || type == ShaderType.geometry);
		this._type = type;
		this._params = ShaderParameterCollection(params);
		this._source = source;
		this._uniformBlockNames = uniformBlockNames;
		this.id = GL.createShader(cast(GLenum)type);
		generateShader(source);
	}

	mixin GpuResource;

	/// Gets the parameters that0 this Shader contains.
	@property ShaderParameterCollection params() {
		return _params;
	}

	/// Gets a range of strings containing all of the names of the uniform blocks this shader uses.
	@property auto uniformBlockNames() {
		return _uniformBlockNames;
	}

	/// Gets the type of this Shader, a value from the ShaderType enum.
	@property ShaderType type() const {
		return _type;
	}

	// TODO: Implement these when necessary.
	/+/// Creates a copy of this Shader, but does not copy over the uniform params.
	Shader Clone() {
		ShaderAttribute[] attribs = this.params.Values.dup;
		for(size_t i = 0; i < attribs.length; i++)
			attribs[i] = new ShaderAttribute(attribs[i].name, attribs[i].type, attribs[i].modifiers);
		return new Shader(type, uniformBlockNames, _source, attribs);
	}

	package void reload(string[] uniformBlockNames, in char[] source, ShaderAttribute[] attributes) {
		this._params.Rebind(Attributes);
		this._source = source.idup;
		this.uniformBlockNames = uniformBlockNames.dup;
		GenerateShader(source);
		if(Parent)
			Parent.Relink();
	}+/

private:
	ShaderType _type;
	ShaderParameterCollection _params;
	string _source;
	string[] _uniformBlockNames;

	void destroyResource(ResourceID id) {
		GL.deleteShader(id);
	}

	void generateShader(in char[] source) {
		source.enforceNoGC();
		// Must be lvalues:
		auto sPtr = source.ptr;
		auto sLen = cast(GLint)source.length;
		GL.shaderSource(id, 1, &sPtr, &sLen);
		GL.compileShader(id);
		int result;
		GL.getShaderiv(id, GL_COMPILE_STATUS, &result);
		if(result != GL_TRUE) {
			char[2048] msg;
			int logLength;
			GL.getShaderInfoLog(id, 2048, &logLength, msg.ptr);
			logwf("Failed to compile shader: %s", msg[0..logLength]);
			throw new Exception("A shader failed to compile.");
		}
	}
}

/// Stores access to the params used for a shader.
struct ShaderParameterCollection {

	/// Indicates the number of params available.
	@property size_t length() {
		return _params.length;
	}

	/// Returns the parameter with the given index.
	@property ShaderParameter opIndex(size_t index) {
		return _params[index];
	}

	/// Returns the parameter with the given name.
	@property ShaderParameter opIndex(string name) {
		// TODO: This needs to not be O(N).
		foreach(param; _params) {
			if(param.name == name)
				return param;
		}
		return ShaderParameter.init;
	}

	/// Gets the underlying array of the parameter collection.
	ShaderParameter[] opSlice() {
		return _params;
	}

	/// Wraps the given parameters in a collection.
	this(ShaderParameter[] params) {
		this._params = params;
	}

private:
	ShaderParameter[] _params;
}