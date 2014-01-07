module ShardGraphics.Sampler;

public import ShardGraphics.Shader;
public import ShardGraphics.Texture;
private import ShardGraphics.GraphicsDevice;

/// Represents a single sampler bound to the graphics API.
class Sampler  {
 
public:
	/// Initializes a new instance of the Sampler object.
	/// Params:
	///		TextureSlot = The slot to bind this texture to. Must be greater than zero and less than GraphicsDevice.Textures.Capacity.
	package this(int TextureSlot) {
		//assert(TextureSlot >= 0 && TextureSlot < GraphicsDevice.Samplers.Capacity);
		// Currently we create this in the GraphicsDevice.Samplers accessor. So this will create a stack overflow. We can guarantee it anyways.
		_Slot = TextureSlot;
	}

	/// Gets the slot that this texture is bound to.
	@property int Slot() const {
		return _Slot;
	}

	/// Sets the texture for this sampler to the specified value, or null to clear the texture.
	/// This method sets this sampler as the active sampler on the GraphicsDevice.
	/// This method performs caching, and does not make any graphics API changes unless necessary. If external calls were made to the graphics API without the use of the Sampler, this may result in false caching.
	/// Params:
	/// 	Value = The value to assign to the index.	
	@property void Value(const Texture value) {
		_Value = cast(Texture)value;
		GraphicsDevice.ActiveSampler = this;						
	}

	/// Ditto
	@property const(Texture) Value() const {
		return cast(const)_Value;
	}

	package void ClearCache() {
		_Value = null;
	}
	
private:
	Texture _Value;
	int _Slot;
}