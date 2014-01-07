module ShardGraphics.SpriteVertex;

public import ShardTools.Color;
public import ShardMath.Vector;


/// Represents a vertex containing a Position, Texture, and Color element.
struct SpriteVertex {		

	/// The position element for this vertex, in normalized screen coordinates (0 to 1).
	Vector2f Position;
	/// The color tint to use for this sprite.
	Color ColorTint;
	/// The normalized texture coordinates for this Vertex (0 to 1), where X is U and Y is V.
	Vector2f TexCoords;
	
	this(Vector2f Position, Color ColorTint, Vector2f TexCoords) {
		this.Position = Position;
		this.ColorTint = ColorTint;
		this.TexCoords = TexCoords;
	}
}