module ShardGraphics.SpriteBatch;
import ShardGraphics.RenderState;
import ShardGraphics.SpriteFont;
import ShardGraphics.SpriteSheetPart;
import ShardGraphics.ShaderImporter;
import ShardGraphics.GraphicsErrorHandler;
import ShardGraphics.TextureImporter;
import ShardContent.ContentLoader;
import ShardGraphics.Effect;
import ShardFramework.Game;
public import ShardGraphics.Texture;

import ShardGraphics.VertexBufferObject;

public import ShardMath.Rectangle;
public import ShardGraphics.Shader;
private import ShardTools.Map;
import std.exception;

enum SpriteBatchState {
	Idle,
	InBeginEndBlock
}

/// A class used to draw multiple sprites in a batch.
class SpriteBatch {

public:
	/// Initializes a new instance of the SpriteBatch object.
	this() {
		SpriteMapping = new Map!(const(Texture), SpriteVertex[])();
		Shader VertShader = ContentLoader.Default.Load!(ShaderImporter)("Content/Shaders/SpriteBatchVert");
		Shader FragShader = ContentLoader.Default.Load!(ShaderImporter)("Content/Shaders/SpriteBatchFrag");
		Shader[2] Shaders;
		Shaders[0] = VertShader;
		Shaders[1] = FragShader;
		this.Program = new Effect(Shaders);
		ShaderAttribute InPosition = VertShader.Parameters.Get("InPosition");
		ShaderAttribute InTexCoords = VertShader.Parameters.Get("InTexCoords");
		ShaderAttribute InColor = VertShader.Parameters.Get("InColor");
		VertexElement[3] Elements;
		SpriteVertex tmpVert; // Hack to get aroudn .offsetof requiring an instance.
		Elements[0] = VertexElement(InColor.Position, GL_FLOAT, 4, SpriteVertex.sizeof, tmpVert.Color.offsetof);
		Elements[1] = VertexElement(InPosition.Position, GL_FLOAT, 2, SpriteVertex.sizeof, tmpVert.Position.offsetof);		
		Elements[2] = VertexElement(InTexCoords.Position, GL_FLOAT, 2, SpriteVertex.sizeof, tmpVert.TexCoords.offsetof);		
		VertDec = new VertexDeclaration(Elements);		

		GraphicsDevice.Program = Program;
		ShaderAttribute TextureAttribute = FragShader.Parameters.Get("SpriteTexture");
		GraphicsDevice.ActiveSampler = GraphicsDevice.Samplers[0];
		TextureAttribute.Value = GraphicsDevice.ActiveSampler.Slot;
		GraphicsDevice.Program = null;
		GraphicsErrorHandler.CheckErrors();

		VertBuffer = new VertexBuffer();
		Indices = new IndexBuffer();
	}

	/// Gets a default instance of the SpriteBatch class.
	/// This object should never manually have it's state changed.
	static @property SpriteBatch Default() {
		if(_Default is null) { // Lazily create it because we can't do it inside a static ctor since the graphics device is not created.
			_Default = new SpriteBatch();
		}
		return _Default;
	}

	/// Prepares this SpriteBatch for rendering.
	void Begin() {
		enforce(_State == SpriteBatchState.Idle, "State must be in Idle to begin.");
		_State = SpriteBatchState.InBeginEndBlock;				
		SpriteMapping.Clear();
		CachedViewport.X = Viewport.Width;
		CachedViewport.Y = Viewport.Height;		
	}

	/// Ends the SpriteBatch, submitting the sprites for rendering.
	void End() {
		enforce(_State == SpriteBatchState.InBeginEndBlock, "State must be in BeginEndBlock to end.");
		GraphicsDevice.State.SetAlpha(BlendStyle.SourceAlpha, BlendStyle.InvertSource);
		GraphicsDevice.State.PerformDepthTest = false;
		foreach(const Texture Key; SpriteMapping.Keys) {
			SpriteVertex[] Vertices = SpriteMapping.Get(Key, null);
			size_t NumElements = cast(size_t)(Vertices.length / 4);
			GraphicsDevice.Vertices = VertBuffer;

			GraphicsDevice.ActiveSampler = GraphicsDevice.Samplers[0];
			GraphicsDevice.ActiveSampler.Value = Key;				
					
			GraphicsDevice.VertexElements = this.VertDec;
			GraphicsDevice.Program = this.Program;

			VertBuffer.SetData(Vertices, SpriteVertex.sizeof, BufferUseHint.Stream, BufferAccessHint.WriteOnly);			
			size_t IndiceIndex = 0;
			/*ushort[] Indices = new ushort[NumElements * 6];			
			for(int i = 0; i < NumElements; i++) {				
				Indices[IndiceIndex++] = cast(ushort)((NumElements * 6) + 2); /// /_|
				Indices[IndiceIndex++] = cast(ushort)((NumElements * 6) + 1);
				Indices[IndiceIndex++] = cast(ushort)((NumElements * 6) + 3);

				Indices[IndiceIndex++] = cast(ushort)((NumElements * 6) + 2); // |_\
				Indices[IndiceIndex++] = cast(ushort)((NumElements * 6) + 0);
				Indices[IndiceIndex++] = cast(ushort)((NumElements * 6) + 1);
			}*/			
			ushort[] Indices = new ushort[NumElements * 4];
			for(size_t i = 0; i < Indices.length; i++)
				Indices[i] = cast(ushort)i;
			GraphicsDevice.Indices = this.Indices;
			this.Indices.SetData(Indices, 2, BufferUseHint.Stream, BufferAccessHint.WriteOnly);			

			GraphicsDevice.DrawElements(RenderStyle.Quads, 4 * NumElements, ElementType.Int16);

			GraphicsDevice.Indices = null;
			GraphicsDevice.Vertices = null;
			GraphicsDevice.Program = null;
			GraphicsDevice.ActiveSampler.Value = null;
		}		
		_State = SpriteBatchState.Idle;
	}
	
	/// Draws the given text at the given location.
	/// Params:
	/// 	Text = The text to draw.
	/// 	Font = The font to draw the text with.
	/// 	Location = The starting location to draw the text at. The origin is 0, 0, which is the bottom left of the screen.
	/// 	TextColor = The color of the text to draw.
	void DrawString(string Text, const SpriteFont Font, Vector2f Location, Color TextColor) {
		// TODO: Can improve the performance of this.

		Vector2f CurrPos = Location;
		foreach(char c; Text) {
			Rectanglef CharLocation = Font.CharacterLocation(c);
			Vector2f CurrMeasurement = Font.MeasureCharacter(c);			
			Draw(Font.FontTexture, Rectanglef(CurrPos.X, CurrPos.Y, CurrMeasurement.X, CurrMeasurement.Y), TextColor, CharLocation);
			CurrPos.X += CurrMeasurement.X;
		}
	}

	/// Draws the given SpriteSheetPart at the specified location.
	/// Params:
	/// 	Part = The SpriteSheetPart to draw.
	/// 	Location = The location to draw the part at. The origin is 0, 0, which is the bottom left of the screen.
	/// 	ColorTint = The color to tint the sprite with.
	void Draw(SpriteSheetPart Part, Rectanglef Location, Color ColorTint) {
		Draw(Part.Parent.SheetTexture, Location, ColorTint, cast(Rectanglef)Part.Location);
	}

	/// Adds the sprite to the collection of sprites to be rendered.
	/// Params:
	/// 	Sprite = The sprite to render.
	/// 	Location = The location to render the sprite at. The origin is 0, 0, which is the bottom left of the screen.
	/// 	ColorTint = The color tint to apply to this vertex.
	/// 	SourceRect = The rectangle, within Sprite, to draw. If set to Rectanglef.init, it is ignored.
	void Draw(const Texture Sprite, Rectanglef Location, Color ColorTint, Rectanglef SourceRect = Rectanglef.init) {		
		SpriteVertex[] Vertices = SpriteMapping.Get(Sprite, new SpriteVertex[0]);		
		//Location.Y = ScreenSize.Y - Location.Y;
		Location.Width = (Location.Right - (CachedViewport.X / 2f)) / (CachedViewport.X / 2f);
		Location.Height = (Location.Bottom - (CachedViewport.Y / 2f)) / (CachedViewport.Y / 2f);
		Location.X = (Location.X - (CachedViewport.X / 2f)) / (CachedViewport.X / 2f);
		Location.Y = (Location.Y - (CachedViewport.Y / 2f)) / (CachedViewport.Y / 2f);				
		if(SourceRect != Rectanglef.init) {			
			SourceRect.Width = SourceRect.Right / Sprite.Width;
			SourceRect.Height = SourceRect.Bottom / Sprite.Height;
			SourceRect.X /= Sprite.Width;
			SourceRect.Y /= Sprite.Height;
		} else {
			SourceRect.Width = 1;
			SourceRect.Height = 1;
			SourceRect.X = 0;
			SourceRect.Y = 0;
		}
		size_t Index = Vertices.length;
		Vertices.length = Vertices.length + 4;

		Vertices[Index].Position = Vector2f(Location.X, Location.Height); // Bottomleft
		Vertices[Index].Color = ColorTint.ToVector4();
		Vertices[Index].TexCoords = Vector2f(SourceRect.X, SourceRect.Y);	
		Index++;

		Vertices[Index].Position = Vector2f(Location.X, Location.Y); // Topleft
		Vertices[Index].Color = ColorTint.ToVector4();
		Vertices[Index].TexCoords = Vector2f(SourceRect.X, SourceRect.Height);
		Index++;

		Vertices[Index].Position = Vector2f(Location.Width, Location.Y); // Topright
		Vertices[Index].Color = ColorTint.ToVector4();
		Vertices[Index].TexCoords = Vector2f(SourceRect.Width, SourceRect.Height);
		Index++;		
		
		Vertices[Index].Position = Vector2f(Location.Width, Location.Height); // Bottomright
		Vertices[Index].Color = ColorTint.ToVector4();
		Vertices[Index].TexCoords = Vector2f(SourceRect.Width, SourceRect.Y);

		SpriteMapping.Set(Sprite, Vertices);
	}

	/// Gets the state of this SpriteBatch.
	@property SpriteBatchState State() {
		return _State;
	}
	
private:
	SpriteBatchState _State;
	Map!(const(Texture), SpriteVertex[]) SpriteMapping;	
	Effect Program;
	VertexDeclaration VertDec;
	VertexBuffer VertBuffer;
	IndexBuffer Indices;
	Vector2i CachedViewport;	
	
	static __gshared SpriteBatch _Default;

	struct SpriteVertex {
		Vector4f Color;
		Vector2f Position;		
		Vector2f TexCoords;		
	}

}