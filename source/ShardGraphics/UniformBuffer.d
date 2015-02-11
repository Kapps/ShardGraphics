module ShardGraphics.UniformBuffer;
private import std.traits;
private import ShardMath.Matrix;
private import std.exception;
private import ShardGraphics.Effect;
private import ShardGraphics.Shader;
import std.string;
private import derelict.opengl3.gl3;
private import std.c.string : memcpy;
import core.stdc.stdlib : malloc, free;
import ShardGraphics.GpuResource;
import ShardTools.ScopeString : ScopeString, scoped;
import ShardTools.Logger;
import ShardGraphics.GraphicsBuffer;
import std.typecons;
import ShardTools.HashTable;
import core.memory;
import gl;

// TODO: Wrap in UniformObject!T(Buffer).

/// Provides access to a buffer containing the uniform variables for one or more shaders.
/// This can be useful as an optimization when multiple shaders use the same values (such as a global WorldViewProjection matrix or lighting).
/// Unlike uniform variables, UniformBuffers are not attached directly to an effect.
/// Instead they are bound to an $(D EffectPool), and effects are registered within that pool.
/// Bugs:
/// 	EffectPool support not yet implemented; all shaders share the same set of uniform blocks.
struct UniformBuffer {

public:
	/// Initializes a new instance UniformBuffer from the specified prepopulated data.
	this(GLuint programID, string name, size_t index, HashTable!(string, size_t) offsets) {
		this._name = name;
		this._buffer = UniformBufferStore(BufferModifyHint.frequent, BufferAccessHint.readWrite);
		this._offsets = offsets;
		this._blockIndex = cast(uint)index;

		int size;
		GL.getActiveUniformBlockiv(programID, _blockIndex, GL_UNIFORM_BLOCK_DATA_SIZE, &size);
		buffer.allocData(size);
	}

	/// Gets the name of this uniform buffer.
	@property string name() const {
		return _name;
	}
	
	/// Gets the size, in bytes, of this Uniform buffer.
	@property size_t size() {
		return buffer.size;
	}
	
	/// Returns the GraphicsBuffer used to store data for this uniform block.
	@property UniformBufferStore buffer() {
		return _buffer;
	}

	/// Returns a struct containing the offsets of elements within this buffer.
	/// The returned struct includes only `opIndex` and `length` members.
	@property auto offsets() {
		static struct Result {
			this(HashTable!(string, size_t) offsets) {
				this.offsets = offsets;
			}
			@property size_t length() {
				return offsets.length;
			}
			size_t opIndex(string name) {
				return offsets[name];
			}
			private HashTable!(string, size_t) offsets;
		}
		return Result(_offsets);
	}

	/// Returns a new UniformBuffer with the given name, loading data from the instance of the buffer on the given Effect.
	/// If no buffer with the given name is found, $(D UniformBuffer.init) is returned.
	static UniformBuffer fromEffect(ref Effect effect, string name) {
		GLint numBlocks;
		GL.getProgramiv(effect.id, GL_ACTIVE_UNIFORM_BLOCKS, &numBlocks);
		for(uint i = 0; i < numBlocks; i++) {
			ScopeString!256 nameBuff;
			GLsizei nameLen;
			GL.getActiveUniformBlockName(effect.id, i, 256 - 1, &nameLen, nameBuff.ptr);
			if(nameBuff.ptr[0..nameLen] == name)
				return createBuffer(effect.id, name, i);
		}
		return UniformBuffer.init;
	}

	/// Sets the value of a single field in this buffer.
	/// Note that this method requires a HashTable lookup, so if the offset remains
	/// constant (shared layout), it is more efficient to set the buffer data directly.
	void set(T)(string name, in T value) if(is(T == struct) && !hasIndirections!T) {
		auto offset = _nameToOffset[name];
		auto data = cast(ubyte[])(&value[0..1]);
		buffer.setOffsetData(data, offset);
	}

	/+/// Gets or sets the value contained by the buffer.
	/// Params:
	/// 	value = The value to set.
	@property void set(T)(in T value) {
		/*if(!_dataSet) {
			glBindBuffer(GL_UNIFORM_BUFFER, id);
			glBindBufferBase(GL_UNIFORM_BUFFER, index, id);
			//glBindBufferRange(GL_UNIFORM_BUFFER, index, id, 0, T.sizeof);
			_dataSet = true;
			GraphicsErrorHandler.CheckErrors();
		}*/
		this._value = cast(void[])value;
		// This was removed because it's probably more expensive to go through every single field and compare + assign instead of just a single block assign.
		// On the other hand, it would enable shared instead of just std140.
		// For now, using just the below so we can use shared. Consider optimizing for std140.
		//static if(T.sizeof > 128) {
		T CurrentFull = this.get!T();
		glBindBuffer(GL_UNIFORM_BUFFER, id);
		//glBindBufferBase(GL_UNIFORM_BUFFER, index, id);
		glBindBufferBase(GL_UNIFORM_BUFFER, EffectPool.Default.BufferToIndex[this], id);
		foreach(index, field; value.tupleof) {
			alias typeof(field) FieldType;
			enum string FieldName = T.tupleof[index].stringof[3 + T.stringof.length .. $];
			T Current = __traits(getMember, CurrentFull, FieldName);
			T New = __traits(getMember, value, FieldName);
			if(Current == New)
				continue;
			setVariableInternal!(FieldName, FieldType)(New);
		}
		glBindBuffer(GL_UNIFORM_BUFFER, 0);
		/*} else {
			// TODO: Static if T.sizeof > 64, go through each property one at a time and update. Make sure this is generated at compile-time.
			// If just 64 or less, easier to just set the whole value.
			// TODO: Consider caching this. Keep in mind though, DirectX doesn't have the concept of uniform buffers(?), so putting it on GraphicsDevice is a bad idea.
			// Also, this isn't something the user needs to worry about what's currently active for, so perhaps there's no point in doing so.
			glBindBuffer(GL_UNIFORM_BUFFER, id);
			glBufferData(GL_UNIFORM_BUFFER, T.sizeof, &value, GL_STREAM_DRAW);
			glBindBuffer(GL_UNIFORM_BUFFER, 0);
		//}*/
		//_value = value;
	}+/

private:
	string _name;
	UniformBufferStore _buffer;
	HashTable!(string, size_t) _offsets;
	uint _blockIndex;

	static UniformBuffer createBuffer(GLuint programID, string name, uint blockIndex) {
		GLint numIndices;
		GL.getActiveUniformBlockiv(programID, blockIndex, GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS, &numIndices);
		GLint* indices = cast(GLint*)malloc(numIndices * GLint.sizeof);
		scope(exit)
			free(indices); // Can't use alloca + exceptions on Win64.
		GL.getActiveUniformBlockiv(programID, blockIndex, GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES, indices);
		GLint blockSize;
		GL.getActiveUniformBlockiv(programID, blockIndex, GL_UNIFORM_BLOCK_DATA_SIZE, &blockSize);
		
		auto offsets = HashTable!(string, size_t)(0, 1); // Non-resizing.
		offsets.reserve(numIndices);
		for(size_t j = 0; j < numIndices; j++) {
			auto index = cast(GLuint)indices[j];
			GLint offset;
			GL.getActiveUniformsiv(programID, 1, &index, GL_UNIFORM_OFFSET, &offset);
			GLsizei uniformNameLen;
			GL.getActiveUniformsiv(programID, 1, &index, GL_UNIFORM_NAME_LENGTH, &uniformNameLen);
			// GC allocation for convenience, generally not called after loading after all.
			char* uniformNameBuff = cast(char*)GC.malloc(uniformNameLen + 1);
			GL.getActiveUniform(programID, index, uniformNameLen, null, null, null, uniformNameBuff);
			uniformNameBuff[uniformNameLen] = '\0';
			
			string offName = cast(string)uniformNameBuff[0..uniformNameLen];
			offsets[offName] = offset;
		}
		return UniformBuffer(blockIndex, name, blockSize, offsets);
	}

	/+// Assumes: Buffer is bound. Assigns nameToOffset.
	int getAndSetOffset(string name) {
		int* Result = (name in nameToOffset);
		if(Result)
			return *Result;
		auto buff = ScopeString!256(name);
		auto buffPtr = buff.ptr; // lvalue
		uint index;
		glGetUniformIndices(_program.id, 1, &buffPtr, &index);
		enforce(index != GL_INVALID_INDEX, "Unable to get the index for uniform named " ~ name ~ " within " ~ _name ~ ".");
		int offset;
		glGetActiveUniformsiv(_program.id, 1, &index, GL_UNIFORM_OFFSET, &offset);
		enforce(offset != -1, "Unable to get offset for uniform named " ~ name ~ " within " ~ _name ~ ".");
		nameToOffset[name] = offset;
		return offset;
	}+/
}