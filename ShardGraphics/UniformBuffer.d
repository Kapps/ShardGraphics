module ShardGraphics.UniformBuffer;
private import ShardMath.Matrix;
private import ShardGraphics.GraphicsErrorHandler;
private import std.exception;
private import ShardGraphics.Effect;
private import ShardGraphics.Shader;
import std.string;
private import gl;
private import std.c.string : memcpy;

/// Provides access to a buffer containing the uniform variables for one or more shaders.
/// This can be useful as an optimization when multiple shaders use the same values (such as a global WorldViewProjection matrix or lighting).
class UniformBuffer : GraphicsResource {

public:
	/// Initializes a new instance of the UniformBuffer object.
	/// Params:
	/// 	Fields = The fields in the uniform buffer.
	/// 	UniformIndex = The index of the uniform buffer within the shader.
	/// 	Name = The name of the uniform buffer.
	/// 	Program = The effect containing this buffer.
	this(Effect Program, string Name) {				
		this._Name = Name;
		this._Program = Program;
		this._Index = glGetUniformBlockIndex(Program.ResourceID, toStringz(Name));		
		enforce(_Index >= 0, "Unable to get the uniform index for " ~ Name ~ ".");
		glGetActiveUniformBlockiv(Program.ResourceID, Index, 0x8A40, &_Size);
		GLuint ID;
		glGenBuffers(1, &ID);
		this.ResourceID = ID;		
		glBindBuffer(GL_UNIFORM_BUFFER, ResourceID);
		glBufferData(GL_UNIFORM_BUFFER, Size, null, GL_STATIC_DRAW);
		glBindBuffer(GL_UNIFORM_BUFFER, 0);
		/+glBindBuffer(GL_UNIFORM_BUFFER, ResourceID);
		glBufferData(GL_UNIFORM_BUFFER, T.sizeof, null, GL_STREAM_DRAW);		
		glBindBuffer(GL_UNIFORM_BUFFER, 0);+/
	}

	/// Gets the index (or ID) associated with this buffer.
	@property int Index() const {
		return _Index;
	}

	/// Gets the size, in bytes, of this Uniform buffer.
	@property int Size() const {
		return _Size;
	}

	/// Sets the value contained by the buffer.
	/// Params:
	/// 	Value = The Value to set.
	@property void Value(T)(in T Value) {			
		if(!_DataSet) {
			glBindBuffer(GL_UNIFORM_BUFFER, ResourceID);			
			glBindBufferBase(GL_UNIFORM_BUFFER, Index, ResourceID);
			//glBindBufferRange(GL_UNIFORM_BUFFER, Index, ResourceID, 0, T.sizeof);
			_DataSet = true;
			GraphicsErrorHandler.CheckErrors();
		}	
		// TODO: Static if T.sizeof > 64, go through each property one at a time and update. Make sure this is generated at compile-time.
		// If just 64 or less, easier to just set the whole value.
		// TODO: Consider caching this. Keep in mind though, DirectX doesn't have the concept of uniform buffers(?), so putting it on GraphicsDevice is a bad idea.
		glBindBuffer(GL_UNIFORM_BUFFER, ResourceID);
		glBufferData(GL_UNIFORM_BUFFER, T.sizeof, &Value, GL_STREAM_DRAW);		
		glBindBuffer(GL_UNIFORM_BUFFER, 0);
		//_Value = Value;
	}

	/// Sets a single property of this buffer to the given value.
	/// Params:
	/// 	Offset = The offset of the value. Usually gotten by Field.offset.
	/// 	Value = The value to assign.
	void SetPartialValue(T)(uint Offset, in T Value) {
		enforce(_DataSet, "Value must be set prior to PartialValue being set.");
		//enforce(Value.length + Offset <= T.sizeof);
		glBindBuffer(GL_UNIFORM_BUFFER, ResourceID);
		glBufferSubData(GL_UNIFORM_BUFFER, Offset, T.sizeof, &Value);
		glBindBuffer(GL_UNIFORM_BUFFER, 0);
		//memcpy((cast(ubyte*)(&_Value)) + Offset, Value.ptr, Value.length);
	}

	/+ /// Ditto
	@property T Value() const {
		return _Value;
	}+/

	/// Deletes the graphics resource represented by the given ID.
	/// Params:
	/// 	ID = The ID of the resource to delete.
	protected override void DeleteResource(GLuint ID) {
		
	}
		
private:
	///T _Value;
	int _Index;
	string _Name;
	Effect _Program;
	bool _DataSet = false;
	int _Size;
}