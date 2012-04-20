module ShardGraphics.SamplerCollection;
import ShardGraphics.Sampler;
public import ShardTools.List;
public import ShardGraphics.Texture;
private import gl;

/// Represents a collection of samplers contained on the GraphicsDevice.
final class SamplerCollection {

public:
	/// Initializes a new instance of the SamplerCollection object.
	package this() {
		GLint MaxTextures;
		glGetIntegerv(GL_MAX_TEXTURE_IMAGE_UNITS, &MaxTextures);
		this.Samplers = new Sampler[MaxTextures];
		for(size_t i = 0; i < Samplers.length; i++)
			Samplers[i] = new Sampler(cast(int)i);
	}

	/// Gets the number of elements in this collection. 
	/// This is the total number of textures the GraphicsDevice is capable of storing.
	size_t Capacity() const {
		return Samplers.length;
	}

	/// Returns whether this collection contains the specified element.
	/// Params:
	///		Element = The element to check for containment.
	bool Contains(in Sampler Element) const {
		return this.IndexOf(Element) != -1;
	}

	/// Returns the index of the specified element in this collection, or -1 if it was not found.
	///	Params:
	///		Element = The element to get the index of.
	size_t IndexOf(in Sampler Element) const {
		for(size_t i = 0; i < Samplers.length; i++)
			if(Samplers[i] is Element)
				return i;
		return -1;
	}

	/// Returns the cached texture at the specified, zero-based, index.
	/// Params:
	///		Index = The zero-based index to get the element at.
	Sampler At(size_t Index) {
		assert(Index >= 0 && Index < Samplers.length);
		return Samplers[Index];
	}

	/* /// Sets the texture at the specified location to the specified value, or null to clear that texture.
	/// This method performs caching, and does not make any graphics API changes unless necessary. If external calls were made to the graphics API without the use of the GraphicsDevice, this may result in false caching.
	/// Params:
	/// 	Index = The index to assign the texture to.
	/// 	Value = The value to assign to the index.
	void Set(size_t Index, Texture Value) {
		assert(Index >= 0 && Index < Samplers.length);
		Texture Old = Textures[Index];
		if(Old is Value)
			return;		
		GLuint ID = Value is null ? 0 : Value.ResourceID;
		glBindTexture(GL_TEXTURE_2D, ID);	
		Textures[Index] = Value;
	}*/
	
	/// Implements the Index operator by getting the element At the specified index.
	/// Params:
	///		Index = The index to get the element at.
	final Sampler opIndex(size_t Index) {	
		return At(Index);
	}
	
private:
	Sampler[] Samplers;

}