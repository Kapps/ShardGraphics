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
	override ImportResult ImportAsset(StreamReader Data) {
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
		Texture SpriteTexture = TexImporter.ImportAsset(Data).AssetImported;
		SpriteSheet Result = new SpriteSheet(SpriteTexture, SpriteMap);
		foreach(SpriteSheetPart Part; Result.Sprites)
			Part.SetParent(Result);
		return new ImportResult(Result, false);
	}

	/// Reloads a previously loaded asset with the new data.
	/// It is up to the implementor to notify the asset of the newly changed data, and handle the actual updating.
	/// The result should not change the reference, as multiple objects may reference the same asset. As such, this method returns void.
	/// If ImportAsset always has CanReload be false, this method will never be called.
	/// Params:
	///		Asset = The asset to reload.
	///		Data = The data to import the new version of the asset from.
	override void ReloadAsset(SpriteSheet Asset, StreamReader Data) {
		// TODO: Implement.
		assert(0);
	}
private:
}