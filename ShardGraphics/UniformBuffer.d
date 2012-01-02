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
		glGetActiveUniformBlockiv(Program.ResourceID, Index, GL_UNIFORM_BLOCK_DATA_SIZE, &_Size);
		GLuint ID;
		glGenBuffers(1, &ID);
		this.ResourceID = ID;		
		glBindBuffer(GL_UNIFORM_BUFFER, ResourceID);
		glBufferData(GL_UNIFORM_BUFFER, Size, null, GL_DYNAMIC_DRAW);				
		glBindBuffer(GL_UNIFORM_BUFFER, 0);
		this._Value = cast(void[])(new ubyte[Size]);
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

	/// Gets or sets the value contained by the buffer.	
	/// Params:
	/// 	Value = The Value to set.
	@property void Set(T)(in T Value) {			
		/*if(!_DataSet) {
			glBindBuffer(GL_UNIFORM_BUFFER, ResourceID);			
			glBindBufferBase(GL_UNIFORM_BUFFER, Index, ResourceID);
			//glBindBufferRange(GL_UNIFORM_BUFFER, Index, ResourceID, 0, T.sizeof);
			_DataSet = true;
			GraphicsErrorHandler.CheckErrors();
		}*/			
		this._Value = cast(void[])Value;
		// This was removed because it's probably more expensive to go through every single field and compare + assign instead of just a single block assign.
		// On the other hand, it would enable shared instead of just std140.
		// For now, using just the below so we can use shared. Consider optimizing for std140.
		//static if(T.sizeof > 128) {			
			T CurrentFull = this.Get!T();
			glBindBuffer(GL_UNIFORM_BUFFER, ResourceID);
			glBindBufferBase(GL_UNIFORM_BUFFER, Index, ResourceID);
			foreach(Index, Field; Value.tupleof) {
				alias typeof(Field) FieldType;
				enum string FieldName = T.tupleof[Index].stringof[3 + T.stringof.length .. $];
				T Current = __traits(getMember, CurrentFull, FieldName);
				T New = __traits(getMember, Value, FieldName);
				if(Current == New)
					continue;
				SetVariableInternal!(FieldName, FieldType)(New);
			}
			glBindBuffer(GL_UNIFORM_BUFFER, 0);
		/*} else {
			// TODO: Static if T.sizeof > 64, go through each property one at a time and update. Make sure this is generated at compile-time.
			// If just 64 or less, easier to just set the whole value.
			// TODO: Consider caching this. Keep in mind though, DirectX doesn't have the concept of uniform buffers(?), so putting it on GraphicsDevice is a bad idea.
			// Also, this isn't something the user needs to worry about what's currently active for, so perhaps there's no point in doing so.
			glBindBuffer(GL_UNIFORM_BUFFER, ResourceID);
			glBufferData(GL_UNIFORM_BUFFER, T.sizeof, &Value, GL_STREAM_DRAW);		
			glBindBuffer(GL_UNIFORM_BUFFER, 0);
		//}*/
		//_Value = Value;
	}

	/// Ditto
	@disable @property const(T) Get(T)() {
		// TODO. This requires mapping the buffer, figuring out sizes, offsets, etc.
		return cast(T)_Value;
	}

	/// Gets or sets a single field in this buffer.
	/// Params:
	/// 	Offset = The offset of the value. Usually gotten by Field.offset.
	/// 	Value = The value to assign.
	void Set(string Name, T)(in T Value) {

		// TODO: Support indexing.
		// TODO: Remove the _DataSet restriction. This can probably be done by BindBufferBase in the EffectPool.

		//enforce(_DataSet, "Value must be set prior to PartialValue being set.");
		//enforce(Value.length + Offset <= T.sizeof);		
		/*T OriginalValue = *(cast(T*)this._Value.ptr);
		if(OriginalValue == Value)
			return;		*/				
		glBindBuffer(GL_UNIFORM_BUFFER, ResourceID);
		// TODO: REMOVE
		//if(!_DataSet) {
			//glBindBufferBase(GL_UNIFORM_BUFFER, Index, ResourceID);
			//_DataSet = true;
		//}
		glBindBufferBase(GL_UNIFORM_BUFFER, Index, ResourceID);
		SetVariableInternal!(Name, T)(Value);
		glBindBuffer(GL_UNIFORM_BUFFER, 0);
		//memcpy((cast(ubyte*)(&_Value)) + Offset, Value.ptr, Value.length);
	}

	/// Ditto
	@disable const(T) Get(string Name, T)() {
		// TODO. See other Get.
		T Val = *(cast(T*)this._Value.ptr);
		return __traits(getMember, Val, Name);
	}

	// Internal variable assigner. Does not perform any checks, nor change the active buffer.
	private void SetVariableInternal(string Name, T)(in T Value) {
		size_t Offset = GetAndSetOffset(Name);
		glBufferSubData(GL_UNIFORM_BUFFER, Offset, T.sizeof, &Value);
		//__traits(getMember, this._Value, Name) = Value;
	}	

	/// Deletes the graphics resource represented by the given ID.
	/// Params:
	/// 	ID = The ID of the resource to delete.
	protected override void DeleteResource(GLuint ID) {
		// Do nothing?
	}

	/// Gets the name of this uniform buffer.
	@property string Name() const {
		return _Name;
	}
		
private:
	///T _Value;
	int[string] NameToOffset;
	void[] _Value;
	int _Index;
	string _Name;
	Effect _Program;	
	int _Size;	
	bool _DataSet = false;

	// Assumes: Buffer is bound. Assigns NameToOffset.
	int GetAndSetOffset(string Name) {
		int* Result = (Name in NameToOffset);
		if(Result)
			return *Result;
		const char* NamePtr = cast(const)toStringz(Name);
		uint Index;
		glGetUniformIndices(_Program.ResourceID, 1, &NamePtr, &Index);
		enforce(Index != GL_INVALID_INDEX, "Unable to get the index for uniform named " ~ Name ~ " within " ~ _Name ~ ".");
		int Offset;
		glGetActiveUniformsiv(_Program.ResourceID, 1, &Index, GL_UNIFORM_OFFSET, &Offset);
		enforce(Offset != -1, "Unable to get offset for uniform named " ~ Name ~ " within " ~ _Name ~ ".");
		NameToOffset[Name] = Offset;
		return Offset;
	}
}