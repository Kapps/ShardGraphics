module ShardGraphics.SpriteSheetPart;
import ShardMath.Rectangle;
import ShardGraphics.SpriteSheet;

/// Represents a single sprite inside a sprite sheet.
class SpriteSheetPart  {

public:
	/// Initializes a new instance of the SpriteSheetPart object.
	this(SpriteSheet Parent, Rectanglei Location, string Name) {
		this._Parent = Parent;
		this._Location = Location;
		this._Name = Name;
	}

	/// Gets the location within the parent texture, in pixels, of this part.
	@property Rectanglei Location() const {
		return _Location;
	}

	/// Gets the name of this sprite part.
	@property string Name() const {	
		return _Name;
	}

	/// Gets the parent sprite sheet owning this part.
	@property SpriteSheet Parent() {
		return _Parent;
	}

	package void SetParent(SpriteSheet Sheet) {
		this._Parent = Sheet;
	}
	
private:
	Rectanglei _Location;
	string _Name;
	SpriteSheet _Parent;
}