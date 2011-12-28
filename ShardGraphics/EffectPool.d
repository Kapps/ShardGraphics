module ShardGraphics.EffectPool;
private import ShardTools.ReadOnlyCollection;
private import ShardTools.ArrayOps;
private import std.exception;
private import ShardGraphics.UniformBuffer;

public import ShardGraphics.Effect;


/// A Pool that has a collection of Effects inside it that may share similar resources.
/// In particular, all effects in an EffectPool share the same UniformBuffers.
class EffectPool  {
	alias ReadOnlyCollection!(EffectPool, EffectPool[]) EffectPoolCollection;

public:
	/// Initializes a new instance of the EffectPool object.
	this() {		
		static uint NextPoolID = 1;
		this.PoolID = NextPoolID++;
		_AllPools ~= this;		
	}

	/// Gets the default EffectPool to use.
	@property static EffectPool Default() {
		if(_Default is null)
			_Default = new EffectPool();
		return _Default;
	}
	
	/// Adds the given effect to this EffectPool.
	/// Params:
	/// 	Program = The effect to add.
	void RegisterEffect(Effect Program) {
		int BindIndex = 0;
		foreach(string Name; Program.Uniforms) {
			UniformBuffer Buffer = GetUniform(Name);
			if(Buffer is null) {
				Buffer = new UniformBuffer(Program, Name);
				Buffers[Name] = Buffer;
			}
			glUniformBlockBinding(Program.ResourceID, Buffer.Index, BindIndex);//Buffer.ResourceID);			
			BindIndex++;
		}
	}

	/// Gets the UniformBuffer with the given name, or null if not found.
	/// Params:
	/// 	Buffer = The name of the buffer.
	UniformBuffer GetUniform(string Buffer) {
		UniformBuffer* Result = (Buffer in Buffers);
		if(!Result)
			return null;
		return *Result;
	}
	
private:
	uint PoolID = 0;
	UniformBuffer[string] Buffers;
	static EffectPool _Default;
	static EffectPool[] _AllPools;
}