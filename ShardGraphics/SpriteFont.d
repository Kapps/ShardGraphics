module ShardGraphics.SpriteFont;
import ShardMath.Vector;
import ShardMath.Rectangle;
import ShardGraphics.Texture;

import ShardGraphics.GraphicsResource;
import ShardContent.IAsset;

/// A bitwise enum representing the style of a font.
enum FontStyle {
	Regular = 0,
	Bold = 1,
	Italic = 2,
	Underline = 4,
	Strikeout = 8
}

/// Represents a collection of bitmap characters that makes up a font.
class SpriteFont : IAsset {

public:
	/// Initializes a new instance of the SpriteFont object.	
	this(string FontName, int StartIndex, int EndIndex, const Texture FontTexture, Rectanglef[] CharacterLocations, float Size) {
		this._FontName = FontName;
		this._StartIndex = StartIndex;
		this._EndIndex = EndIndex;
		this._FontTexture = FontTexture;
		this._Size = Size;
		this.FontLocations = CharacterLocations;		
	}

	/// Gets the size, in pixels, of the given character.
	/// Params:
	/// 	c = The character to get the size of.
	const Vector2f MeasureCharacter(char c) {
		size_t index = cast(size_t)c - cast(size_t)_StartIndex;	
		assert(ContainsCharacter(c));
		return FontLocations[index].Size;
	}
	
	/// Returns the size, in pixels, of the given text. No wrapping is performed.
	/// Params:
	/// 	Text = The text to measure the size of.
	const Vector2f MeasureString(string Text) {
		Vector2f Result;
		foreach(char c; Text)
			Result += MeasureCharacter(c);
		return Result;
	}

	/// Checks if the given character is supported by this SpriteFont.
	/// Params:
	/// 	c = The character to check if supported.
	const bool ContainsCharacter(char c) {
		size_t index = cast(size_t)c - cast(size_t)_StartIndex;	
		return index < FontLocations.length;
	}	

	/// Gets the name of this font.
	const @property string FontName() {
		return _FontName;
	}
	
	/// Gets the character code of the first character in this font.
	const @property int StartIndex() {
		return _StartIndex;
	}

	/// Gets the character code of the last (inclusive) character in this font.
	const @property int EndIndex() {
		return _EndIndex;
	}

	/// Gets the underlying texture used to draw this font.
	@property const(Texture) FontTexture() const {
		return _FontTexture;
	}

	/// Gets the size, in points, of this font.
	const @property float Size() {
		return _Size;
	}

	/// Returns the location of the given character within the font texture.
	/// Params:
	/// 	c = The character to return the location of.
	const Rectanglef CharacterLocation(char c) {
		assert(ContainsCharacter(c));
		size_t index = cast(size_t)c - cast(size_t)_StartIndex;
		return FontLocations[index];
	}

private:
	string _FontName;
	int _StartIndex;
	int _EndIndex;
	const Texture _FontTexture;
	Rectanglef[] FontLocations;
	float _Size;
}