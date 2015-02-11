module ShardGraphics.EffectPool;
private import std.string;
private import ShardTools.ReadOnlyCollection;
private import ShardTools.ArrayOps;
private import std.exception;
private import ShardGraphics.UniformBuffer;
import ShardTools.SpinLock;
import gl;

public import ShardGraphics.Effect;
import std.container.array;
import ShardTools.HashTable;
import ShardTools.ScopeString;


/// A Pool that has a collection of Effects inside it that may share similar resources.
/// In particular, all effects in an EffectPool share the same UniformBuffers.
/// Bugs:
/// 	At this time only the global EffectPool is supported.
final class EffectPool  {
	alias ReadOnlyCollection!(EffectPool, EffectPool[]) EffectPoolCollection;

public:
	/// Initializes a new instance of the EffectPool object.
	private this() {
		static __gshared uint nextID = 1;
		this.id = nextID++;
		_allPools ~= this;
	}

	~this() {
		buffers.clear();
		bufferToIndex.clear();
	}

	/// Gets the global EffectPool to use.
	/// All effects are part of this pool unless specified otherwise.
	@property static EffectPool global() {
		if(_global is null)
			_global = new EffectPool();
		return _global;
	}

	/// Registers the given UniformBuffer to be applied in the EffectPool.
	/// This will be automatically called for unregistered uniforms on effects registered by $(D registerEffect).
	void registerUniform(UniformBuffer buffer) {
		_lock.lock();
		scope(exit)
			_lock.unlock();
		auto bindIndex = cast(int)buffers.length;
		buffers[buffer.name] = buffer;
		bufferToIndex[buffer.name] = bindIndex;
	}

	/// Adds the given effect to this EffectPool.
	/// Params:
	/// 	effect = The effect to add.
	void registerEffect(ref Effect effect) {
		//int bindIndex = 0;
		foreach(string name; effect.uniforms) {
			UniformBuffer buffer = getUniform(name);
			int bindIndex = bufferToIndex[name];
			if(buffer == UniformBuffer.init) {
				buffer = UniformBuffer.fromEffect(effect, name);
				bindIndex = cast(int)buffers.length;
				bufferToIndex[name] = bindIndex;
				buffers[name] = buffer;
			} else
				bindIndex = bufferToIndex[name];
			// TODO: Make sure that it's the same uniform block, and not just one with the same name!
			//int index = glGetUniformBlockIndex(effect.id, toStringz(buffer.name));
			//glUniformBlockBinding(effect.id, index, bindIndex++
			// TODO: Remove index, and make it dependent per effect, which it seems to be, as programs can have multiple indices.
			// But what do we bind to?
			//glUniformBlockBinding(effect.id, index, bindIndex++);
			int index = GL.getUniformBlockIndex(effect.id, buffer.name.scoped.ptr);
			GL.uniformBlockBinding(effect.id, index, bindIndex);
		}
	}

	/// Gets the UniformBuffer with the given name, or null if not found.
	/// Params:
	/// 	buffer = The name of the buffer.
	UniformBuffer getUniform(string buffer) {
		UniformBuffer* result = (buffer in buffers);
		if(!result)
			return UniformBuffer.init;
		return *result;
	}

private:
	uint id = 0;
	HashTable!(string, int) bufferToIndex;
	HashTable!(string, UniformBuffer) buffers;
	SlimSpinLock _lock;
	static __gshared EffectPool _global;
	static __gshared Array!EffectPool _allPools;
}