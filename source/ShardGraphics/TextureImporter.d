module ShardGraphics.TextureImporter;
private import ShardGraphics.GraphicsDevice;

public import ShardContent.ContentImporter;
public import ShardGraphics.Texture;
import std.stream;
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
	override ImportResult ImportAsset(StreamReader Data) {
		byte Params;
		ushort Width, Height;
		Color[] TextureData;
		ReadData(Data, Params, Width, Height, TextureData);		
		Texture Result = new Texture();
		Result.SetData(TextureData, Width, Height, BufferUseHint.Static, BufferAccessHint.WriteOnly);
		return new ImportResult(Result, true);
	}

	/// Reloads a previously loaded asset with the new data.
	/// It is up to the implementor to notify the asset of the newly changed data, and handle the actual updating.
	/// The result should not change the reference, as multiple objects may reference the same asset. As such, this method returns void.
	/// If ImportAsset always has CanReload be false, this method will never be called.
	/// Params:
	///		Asset = The asset to reload.
	///		Data = The data to import the new version of the asset from.
	override void ReloadAsset(Texture Asset, StreamReader Data) {
		byte Params;
		ushort Width, Height;
		Color[] TextureData;
		ReadData(Data, Params, Width, Height, TextureData);				
		GraphicsDevice.QueueCallback(() {
			Asset.SetData(TextureData, Width, Height, BufferUseHint.Static, BufferAccessHint.WriteOnly);
		});
	}
	
private:

	void ReadData(StreamReader Data, out byte Params, out ushort Width, out ushort Height, out Color[] Pixels) {
		Params = Data.Read!byte;
		Width = Data.Read!ushort, Height = Data.Read!ushort;					
		int Size = 4;		
		Pixels = Data.ReadArray!Color(Width * Height);		
		//Data.ReadInto(TextureData.ptr, Width * Height * Size);		
	}
}