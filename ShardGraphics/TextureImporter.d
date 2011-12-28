module ShardGraphics.TextureImporter;

public import ShardContent.ContentImporter;
public import ShardGraphics.Texture;
import std.stream;
import std.intrinsic;
import ShardGraphics.VertexBufferObject;

class TextureImporter : ContentImporter!(Texture) {

public:
	/// Initializes a new instance of the TextureImporter object.
	this() {
		
	}

	/// Imports an asset from the specified Data.
	/// Params:
	///		Data = The data to import an asset from.
	///	Returns: A newly created instance of T from the specified data.
	override Texture ImportAsset(StreamReader Data) {
		byte Params = Data.Read!byte;
		ushort Width = Data.Read!ushort, Height = Data.Read!ushort;			
		Color[] TextureData = new Color[Width * Height];		
		int Size = 4;
		Data.ReadInto(TextureData.ptr, Width * Height * Size);		
		Texture Result = new Texture();
		Result.SetData(TextureData, Width, Height, BufferUseHint.Static, BufferAccessHint.WriteOnly);
		return Result;
	}
	
private:
}