module ShardGraphics.SpriteSheetImporter;
import ShardTools.Map;
import ShardGraphics.TextureImporter;
import ShardGraphics.Texture;
import ShardMath.Rectangle;
public import ShardGraphics.SpriteSheet;
import ShardContent.ContentImporter;
import std.conv;

/// An importer used to import a sprite sheet.
class SpriteSheetImporter : ContentImporter!(SpriteSheet) {

public:
	/// Initializes a new instance of the SpriteSheetImporter object.
	this() {
		
	}
	
	/// Imports an asset from the specified Data.
	/// Params:
	///		Data = The data to import an asset from.
	///		Returns: A newly created instance of T from the specified data.
	override SpriteSheet ImportAsset(StreamReader Data) {
		int SheetCount = Data.Read!int;		
		//SpriteSheetPart[] Parts = new SpriteSheetPart[SheetCount];
		Map!(string, SpriteSheetPart) SpriteMap = new Map!(string, SpriteSheetPart)();
		for(size_t i = 0; i < SheetCount; i++) {
			string Name = Data.ReadPrefixed!char().idup;
			Rectanglei Location = Data.Read!Rectanglei;
			SpriteSheetPart Part = new SpriteSheetPart(null, Location, Name);
			SpriteMap.Set(Part.Name, Part);
		}
		
		TextureImporter TexImporter = new TextureImporter();
		Texture SpriteTexture = TexImporter.ImportAsset(Data);
		SpriteSheet Result = new SpriteSheet(SpriteTexture, SpriteMap);
		foreach(SpriteSheetPart Part; Result.Sprites)
			Part.SetParent(Result);
		return new SpriteSheet(SpriteTexture, SpriteMap);
	}
private:
}