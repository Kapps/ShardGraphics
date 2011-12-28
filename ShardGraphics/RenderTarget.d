module ShardGraphics.RenderTarget;
private import ShardGraphics.GraphicsDevice;
private import ShardGraphics.Viewport;
private import std.conv;
private import std.exception;
private import ShardFramework.Game;
private import crc32;
private import std.algorithm;
private import std.array;
private import ShardGraphics.Texture;
private import gl;
private import ShardGraphics.GraphicsResource;


/// Provides a target to perform rendering on, such as a texture or the backbuffer.
class RenderTarget : GraphicsResource {

public:
	/// Creates a new RenderTarget that internally writes to a Texture of size Width, Height, optionally with a depth-buffer.
	/// Params:
	/// 	CreateDepthBuffer = Whether or not this RenderTarget should have a depth buffer associated with it.
	/// 	Width = The width of the RenderTarget. If zero, the viewport width will be used.
	/// 	Height = The height of the RenderTarget. If zero, the viewport height will be used.
	this(int Width = 0, int Height = 0, bool CreateDepthBuffer = true) {		
		if(Width == 0)
			Width = Viewport.Width;
		if(Height == 0)
			Height = Viewport.Height;
		this(Width, Height, true, CreateDepthBuffer);
	}

	/// Creates a new RenderTarget that operates on the existing Texture.
	/// Params:
	/// 	BaseTexture = The Texture to be rendered upon.
	/// 	CreateDepthBuffer = Whether or not this RenderTarget should have a depth buffer associated with it.
	this(Texture BaseTexture, bool CreateDepthBuffer = true) {
		this._TextureData = BaseTexture;
		this(BaseTexture.Width, BaseTexture.Height, false, CreateDepthBuffer);		
	}

	/// If something isn't created, values for it must be set prior to this constructor call. Aka, texture for above ctor.
	private this(int Width, int Height, bool CreateTexture, bool CreateDepth) {		
		this._Width = Width;
		this._Height = Height;		
		this._IsDefault = false;							
		GLuint ID;
		glGenFramebuffers(1, &ID);			
		this.ResourceID = ID;		
		glBindFramebuffer(GL_FRAMEBUFFER, ResourceID);									
		if(CreateDepth)
			CreateDepthBuffer();		
		if(CreateTexture) {
			this._TextureData = new Texture();
			_TextureData.SetData(null, Width, Height, BufferUseHint.Dynamic, BufferAccessHint.ReadWrite);
		}	
		if(_TextureData !is null) {
			const(Texture) Old = GraphicsDevice.ActiveSampler.Value;
			scope(exit)
				GraphicsDevice.ActiveSampler.Value = Old;
			GraphicsDevice.ActiveSampler.Value = _TextureData;
			glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _TextureData.ResourceID, 0);		
		}
		if(HasDepthBuffer) {
			glBindRenderbuffer(GL_RENDERBUFFER, _DepthBufferID);			
			glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _DepthBufferID);		
		}
		GLenum Status = glCheckFramebufferStatus(GL_FRAMEBUFFER);		
		enforce(Status == GL_FRAMEBUFFER_COMPLETE, "Creating a RenderTarget failed with status code " ~ to!string(Status) ~ ".");
		glBindFramebuffer(GL_FRAMEBUFFER, 0);		
		GraphicsErrorHandler.CheckErrors();
	}

	this(bool Dummy) {
		_IsDefault = true;
	}
	
	/// Gets the RenderTarget that indicates the back-buffer, or, more technically, the absence of a RenderTarget.
	/// This RenderTarget may only be assigned to index zero, and always has the same Width and Height as the Viewport.	
	@property static RenderTarget BackBuffer() {		
		if(_BackBuffer is null)
			_BackBuffer = new RenderTarget(true);
		return _BackBuffer;
	}

	/// Deletes the graphics resource represented by the given ID.
	/// Params:
	///		ID = The ID of the resource to delete.
	override void DeleteResource(GLuint ID) {
		if(_IsDefault)
			return;
		glDeleteFramebuffers(1, &ID);
		if(_DepthBufferID != 0)
			glDeleteBuffers(1, &_DepthBufferID);
	}

	/// Gets the Texture associated with this RenderTarget.
	/// This method may return an existing Texture, or create a new one with the values of the RenderTarget.
	/// In particular, the back-buffer always results in a new Texture being created.
	/// A RenderTarget created for a Texture (aka, not the backbuffer) will always return and operate on the same instance.
	Texture GetTexture() {
		if(_TextureData !is null)
			return _TextureData;
		enforce(_IsDefault, "Internal error. No texture set for a non-backbuffer RenderTarget.");
		Texture Result = new Texture();
		Color[] Pixels = uninitializedArray!(Color[])(Width * Height);
		glReadPixels(0, 0, Width, Height, GL_BGRA, GL_UNSIGNED_INT_8_8_8_8_REV, cast(void*)Pixels.ptr);
		Result.SetData(Pixels, Width, Height, BufferUseHint.Static, BufferAccessHint.ReadWrite);
		return Result;
	}
	
	/// Gets a value indicating whether this RenderTarget has a depth buffer.
	@property bool HasDepthBuffer() const {
		if(_IsDefault)
			return true;
		return _DepthBufferID != 0;
	}

	// Private for now. Is this allowed to be changed after the RenderTarget is already in use? When does it take affect?
	/// Creates a depth buffer to be used with this RenderTarget.
	private void CreateDepthBuffer() {		
		enforce(!HasDepthBuffer, "A depth buffer was already set on this RenderTarget.");
		glGenRenderbuffers(1, &_DepthBufferID);			
		glBindRenderbuffer(GL_RENDERBUFFER, _DepthBufferID);		
		glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT, Width, Height);		
		//glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _DepthBufferID);		
		glBindRenderbuffer(GL_RENDERBUFFER, 0);		
	}

	/// Gets the Width of this RenderTarget.
	@property int Width() const {
		if(_IsDefault)
			return Viewport.Width;
		return _Width;
	}

	/// Gets the Height of this RenderTarget.
	@property int Height() const {
		if(_IsDefault)
			return Viewport.Height;
		return _Height;
	}

private:	
	static RenderTarget _BackBuffer;
	GLuint _DepthBufferID;
	Texture _TextureData;
	int _Width;
	int _Height;	
	bool _IsDefault;
}