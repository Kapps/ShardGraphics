module ShardGraphics.Texture;
import std.stdio : writeln;
private import std.math;
private import ShardTools.ImageSaver;
private import std.file;
private import std.array;
private import ShardMath.Rectangle;

public import ShardGraphics.GraphicsResource;
import ShardGraphics.GraphicsErrorHandler;
public import gl;
public import ShardTools.Color;

private import ShardGraphics.GraphicsDevice;
public import ShardGraphics.VertexBufferObject;
import std.conv;
import std.exception;

enum TextureWrap {
	Repeat = GL_REPEAT,
	ClampToEdge = GL_CLAMP_TO_EDGE,
	MirroredRepeat = GL_MIRRORED_REPEAT
}

enum TextureFilter {
	Nearest = GL_NEAREST,
	Linear = GL_LINEAR,
	NearestMipmapNearest = GL_NEAREST_MIPMAP_NEAREST,
	LinearMipmapNearest = GL_LINEAR_MIPMAP_NEAREST,
	NearestMipmapLinear = GL_NEAREST_MIPMAP_LINEAR,
	LinearMipmapLinear = GL_LINEAR_MIPMAP_LINEAR
}

/// Represents a single 2D texture.
class Texture : GraphicsResource {

public:

	/// Initializes a new instance of the Texture object.
	/// Params:
	/// 	Data = The data to set on the texture.
	/// 	Width = The width, in pixels, of the texture.
	/// 	Height = The height, in pixels, of the texture.
	this() {
		GLuint ID;
		glGenTextures(1, &ID);
		assert(ID != 0);
		this.ResourceID = ID;		
	}

	/// Gets or sets how the texture should be wrapped, horizontally (aka s).
	@property TextureWrap HorizontalWrap() {
		TextureWrap Result;
		mixin(GetTempSetMixin());
		glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, cast(int*)&Result);
		return Result;
	}

	/// Ditto
	@property void HorizontalWrap(TextureWrap Value) {			
		mixin(GetTempSetMixin());
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, cast(int)Value);		
	}

	/// Gets or sets how the texture should be wrapped, vertically (aka t).
	@property TextureWrap VerticalWrap() {
		TextureWrap Result;
		mixin(GetTempSetMixin());
		glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, cast(int*)&Result);
		return Result;
	}

	/// Ditto
	@property void VerticalWrap(TextureWrap Value) {			
		mixin(GetTempSetMixin());
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, cast(int)Value);		
	}	

	/// Gets or sets the min filter used for the texture.
	@property TextureFilter MinFilter() {
		TextureFilter Result;
		mixin(GetTempSetMixin());		
		glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, cast(int*)&Result);
		return Result;
	}

	/// Ditto
	@property void MinFilter(TextureFilter Value) {
		mixin(GetTempSetMixin());
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, cast(int)Value);
	}

	/// Gets or sets the mag filter used for the texture.
	/// Only Linear or Nearest are allowed.
	@property TextureFilter MagFilter() {
		TextureFilter Result;
		mixin(GetTempSetMixin());		
		glGetTexParameteriv(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, cast(int*)&Result);
		return Result;
	}

	/// Ditto
	@property void MagFilter(TextureFilter Value) {
		mixin(GetTempSetMixin());
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, cast(int)Value);
	}
	
	/// Gets or sets the maximum anisotropy level for this texture.
	@property uint MaxAnisotropy() {
		mixin(GetTempSetMixin());
		uint Result;
		glGetTexParameteriv(GL_TEXTURE_2D, 0x84FE, cast(int*)&Result);
		return Result;
	}
	
	/// Ditto
	@property void MaxAnisotropy(uint Value) {
		mixin(GetTempSetMixin());
		glTexParameteri(GL_TEXTURE_2D, 0x84FE, Value);
	}
		
	/// Sets the pixel data for this texture.	
	/// Params:
	/// 	Data		= The data to set on the texture. This is allowed to be null to simply allocate data for the texture, to be set at a later time. This value is not stored, just copied.
	/// 	Width		= The width, in pixels, of the texture.
	/// 	Height		= The height, in pixels, of the texture.
	///		UseHint		= A hint indicating the way this texture will be used.
	///		AccessHint	= A hint indicating the way this texture will be accessed.
	void SetData(Color[] Data, uint Width, uint Height, BufferUseHint UseHint, BufferAccessHint AccessHint) {			
		assert(!IsDeleted);
		GLenum Style = UseHint + AccessHint;
		debug EnsureValidStyle(Style);				
		IsDataSet = true;
		this._Width = Width;
		this._Height = Height;				
		mixin(GetTempSetMixin());		
		glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA8, Width, Height, 0, GL_BGRA, GL_UNSIGNED_BYTE, Data.ptr);				
		/+glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);	
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
		glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_NEAREST);+/
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_BASE_LEVEL, 0);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAX_LEVEL, cast(int)log2(Width) + 1);		
		glGenerateMipmap(GL_TEXTURE_2D);		
		GraphicsErrorHandler.CheckErrors();
	}

	/*void GenerateMipmaps() {
		debug assert(IsDataSet);		
		//glGenerateMipmap(GL_TEXTURE_2D);		
	}*/

	/// Deletes the graphics resource represented by the given ID.
	/// Params:
	/// 	ID = The ID of the resource to delete.
	protected override void DeleteResource(GLuint ID) {		
		if(GraphicsDevice.ActiveSampler.Value is this)
			GraphicsDevice.ActiveSampler.Value = null;
		glDeleteTextures(1, &ID);
	}

	/// Gets the width, in pixels, of this texture. Returns zero if no data is set.
	@property int Width() const {
		return _Width;
	}

	/// Gets the height, in pixels, of this texture. Returns zero if no data is set.
	@property int Height() const {
		return _Height;
	}

	/// Saves this Texture as an image to the given filepath, as an uncompressed tga file.
	/// The file path should not have an extension, as a .tga extension is automatically appended.
	/// Params:
	/// 	FilePath = The path to create the image at.
	void SaveToDisk(string FilePath) const {
		FilePath = FilePath ~ ".png";
		Color[] Data = GetData();
		foreach(ref Color Pixel; Data) {
			// HACK: Instead of actually fixing it to allow the PNG saver to use BGRA, we just swap B and R. -_-
			ubyte OldR = Pixel.R;
			Pixel.R = Pixel.B;
			Pixel.B = OldR;
		}		
		ImageSaver.savePNG(FilePath, Data, Width, Height);
	}

	/// Gets the pixel data for this texture.	
	Color[] GetData() const {
		const(Texture) Old = GraphicsDevice.ActiveSampler.Value;
		scope(exit)
			GraphicsDevice.ActiveSampler.Value = Old;		
		GraphicsDevice.ActiveSampler.Value = this;
		enforce(!IsDeleted, "Texture was deleted.");
		enforce(IsDataSet, "No data set yet.");
		Color[] Result = new Color[Width * Height];		
		glGetTexImage(GL_TEXTURE_2D, 0, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, cast(void*)Result.ptr);
		// HACK: Output is upside down. Fix this...
		for(int y = 0; y < Height / 2; y++) {
			int TargetHeight = Height - y - 1;
			for(int x = 0; x < Width; x++) {
				int Index = TargetHeight * Width + x;
				int OldIndex = y * Width + x;
				Color Curr = Result[Index];
				Result[Index] = Result[OldIndex];
				Result[OldIndex] = Curr;
			}
		}
		return Result;
	}

	~this() {
		writeln("test");
	}

private:
	bool IsDataSet = false;
	int _Width;
	int _Height;
	bool _DeleteTexture = false;

	void EnsureActive() {
		enforce(GraphicsDevice.ActiveSampler !is null && GraphicsDevice.ActiveSampler.Value is this, "This operation requires that the active sampler on the GraphicsDevice has it's value set to this texture.");;		
	}

	void EnsureValidStyle(GLenum Style) {		
		debug assert(
			Style == GL_STATIC_DRAW || Style == GL_STATIC_COPY || Style == GL_STATIC_READ ||
			Style == GL_DYNAMIC_DRAW || Style == GL_DYNAMIC_COPY || Style == GL_DYNAMIC_READ ||
			Style == GL_STREAM_DRAW || Style == GL_STREAM_COPY || Style == GL_STREAM_READ
		);		
	}

	private static string GetTempSetMixin() {
		return
		"const(Texture) Old = GraphicsDevice.ActiveSampler.Value;
		scope(exit)
			GraphicsDevice.ActiveSampler.Value = Old;
		GraphicsDevice.ActiveSampler.Value = this; ";
	}

}