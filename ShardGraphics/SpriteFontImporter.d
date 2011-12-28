module ShardGraphics.SpriteFontImporter;
import ShardGraphics.TextureImporter;
import ShardMath.Rectangle;
import ShardGraphics.SpriteFont;
import ShardContent.ContentImporter;


/// An importer used to import a SpriteFont.
class SpriteFontImporter : ContentImporter!(SpriteFont) {

public:
	/// Initializes a new instance of the SpriteFontImporter object.
	this() {
		
	}

	/// Imports an asset from the specified Data.
	/// Params:
	///		Data = The data to import an asset from.
	///	Returns: A newly created instance of T from the specified data.
	public override SpriteFont ImportAsset(StreamReader Data) {
		float Size = Data.Read!float;
		string Name = Data.ReadPrefixed!char().idup;
		ubyte Style = Data.Read!ubyte;
		int StartIndex = Data.Read!int, EndIndex = Data.Read!int;
		// Font Info:		
		int Count = EndIndex - StartIndex;
		Rectanglef[] Locations = new Rectanglef[Count + 1]; // Inclusive
		for(size_t i = 0; i <= Count; i++)
			Data.ReadInto(&Locations[i], Rectanglef.sizeof);			
		
		// Texture:
		TextureImporter TextureImport = new TextureImporter();		
		Texture FontTexture = TextureImport.ImportAsset(Data);

		SpriteFont Result = new	SpriteFont(cast(immutable)Name, StartIndex, EndIndex, FontTexture, Locations, Size);
		return Result;
	}
	
private:
}