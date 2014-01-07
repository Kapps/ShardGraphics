module ShardGraphics.SpriteSheet;
import ShardTools.Map;
import ShardGraphics.Texture;
public import ShardGraphics.SpriteSheetPart;

/// Represents a texture capable of containing multiple, smaller, textures.
class SpriteSheet {

public:
	/// Initializes a new instance of the SpriteSheet object.
	/// Params:
	/// 	SheetTexture = The full texture to use for the sprite sheet.
	/// 	Parts = A map of sprite, by name, for this sprite sheet.
	this(const Texture SheetTexture, Map!(string, SpriteSheetPart) Parts) {
		this.Parts = Parts;
		this._SheetTexture = SheetTexture;
	}

	/// Gets the SpriteSheetPart with the given name.
	/// Params:
	/// 	PartName = The name of the part to get.
	SpriteSheetPart GetPart(string PartName) {
		return Parts.Get(PartName);
	}

	/// Gets the names of the available parts.
	@property string[] PartNames() {
		return Parts.Keys;
	}

	/// Gets all of the sprites this SpriteSheet contains.
	@property SpriteSheetPart[] Sprites() {
		return Parts.Values;
	}

	/// Gets the full texture being used for the sprite sheet.
	@property const(Texture) SheetTexture() {
		return _SheetTexture;
	}
	
private:
	const Texture _SheetTexture;
	Map!(string, SpriteSheetPart) Parts;
}