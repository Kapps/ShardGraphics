module ShardGraphics.GraphicsDevice;
public import ShardGraphics.RenderTargetCollection;
import std.exception : enforce;
public import ShardGraphics.RenderState;
public import ShardGraphics.SamplerCollection;
public import ShardGraphics.Sampler;
public import gl;
public import ShardTools.Color;
private import ShardTools.Logger;
public  import ShardGraphics.GraphicsErrorHandler;
public import ShardGraphics.VertexDeclaration;
public import ShardGraphics.VertexBufferObject;
public import ShardGraphics.Effect;
public import ShardGraphics.Texture;
public import ShardGraphics.GraphicsAPI;
public import ShardGraphics.Viewport;
//import std.exception;

private import glfw;

// TODO: Deprecate Quads/QuadStrip. Just fix SpriteBatch first.
enum RenderStyle {
	TriangleStrip = GL_TRIANGLE_STRIP,
	Triangles = GL_TRIANGLES,
	TriangleFan = GL_TRIANGLE_FAN,
	Points = GL_POINTS,
	LineStrip = GL_LINE_STRIP,
	QuadStrip = 8,//GL_QUAD_STRIP,
	Quads = 7//GL_QUADS	
}

enum ElementType {
	Int8 = GL_UNSIGNED_BYTE,
	Int16 = GL_UNSIGNED_SHORT,
	Int32 = GL_UNSIGNED_INT
}

enum ClearBits {
	ColorBuffer = GL_COLOR_BUFFER_BIT,
	DepthBuffer = GL_DEPTH_BUFFER_BIT,
	StencilBuffer = GL_STENCIL_BUFFER_BIT,	
}

/// A static helper class used to handle drawing, including caching relevent resources.
static class GraphicsDevice {

static public:	
	static bool DisableCaching = true;

	shared static this() {
		// Can't do anything API related here, because the context is not created.	
		_State = new RenderState();
		SyncLock = new Object();
	}
	
	/// Returns the Graphics API being used for rendering. Only OpenGL is supported at the moment.
	@property GraphicsAPI API() {
		int Major = -1, Minor = -1;
		glGetIntegerv(GL_MAJOR_VERSION, &Major);
		glGetIntegerv(GL_MINOR_VERSION, &Minor);
		return GraphicsAPI(GraphicsRenderer.OpenGL, Major, Minor);
	}

	///	Clears the GraphicsDevice's cache. This is useful when the state of the GraphicsDevice is changed without the use of the GraphicsDevice class.
	/// This attempts to look up values when possible, but this is rarely possible, and only for very few values.
	/// Instead, it will assume all values are set to null or zero.	
	void ClearCache() {		
		// TODO: Look up stuff from ResourcePool.
		// TODO: Consider making the gets a ResourceReference!T : GraphicsResource.
		// This way, we can have an IsExternal property, indicating the resource is unknown (such as when set by an external API).
		// Should have an (implicit?) cast to T, and throw when external and casted.
		_Effect = null;
		_VertexBuffer = null;
		_ActiveDeclaration = null;
		_IndexBuffer = null;
		for(size_t i = 0; i < _Samplers.Capacity; i++)
			_Samplers[i].ClearCache();
		uint ActiveSamplerStore;
		glGetIntegerv(GL_ACTIVE_TEXTURE, cast(int*)&ActiveSamplerStore);
		_ActiveSampler = Samplers[ActiveSamplerStore];		
		Vector4f ClearColorVec;
		glGetFloatv(GL_COLOR_CLEAR_VALUE, ClearColorVec.Elements.ptr);
		_ClearColor = Color(ClearColorVec);
	}

	invariant() {
		debug GraphicsErrorHandler.CheckErrors();
	}

	/// Clears the currently active render target.
	/// Params:
	///		ClearColor = The color to clear the display to.
	///		BitsToClear = The buffers to clear, such as ColorBuffer or DepthBuffer.
	void Clear(Color ClearColor, ClearBits BitsToClear = ClearBits.ColorBuffer | ClearBits.DepthBuffer) {
		if(ClearColor != _ClearColor || DisableCaching) {
			glClearColor(ClearColor.R / 255f, ClearColor.G / 255f, ClearColor.B / 255f, ClearColor.A / 255f);
			_ClearColor = ClearColor;
		}
		glClear(cast(GLenum)BitsToClear);		
		debug GraphicsErrorHandler.CheckErrors();
	}

	/+ /// Sets the specified buffer to be the active VertexBufferObject.
	///	Params:
	///		Buffer = The ID of the buffer to set. A null value clears the active buffer.
	///		IsIndexBuffer = Indicates whether the buffer is an IndexBuffer as opposed to a VertexBuffer.
	void SetActiveBuffer(GLuint Buffer, bool IsIndexBuffer) {
		if(Buffer != _ActiveBuffer) {
			glBindBuffer(IsIndexBuffer ? GL_ELEMENT_ARRAY_BUFFER : GL_ARRAY_BUFFER, Buffer);
			_ActiveBuffer = Buffer;		
			debug GraphicsErrorHandler.CheckErrors();	
		}
	}+/

	/// Gets or sets the given VertexBuffer to be the active VertexBuffer.
	/// This method performs caching, and does not make any graphics API changes unless necessary. If external calls were made to the graphics API without the use of the GraphicsDevice, this may result in false caching.
	/// Params:
	/// 	Buffer = The buffer to set as being active, or null to clear the active buffer.
	@property void Vertices(const VertexBuffer Buffer) {
		if(Buffer !is _VertexBuffer || DisableCaching) {			
			GLuint ID = Buffer is null ? 0 : Buffer.ResourceID;
			glBindBuffer(GL_ARRAY_BUFFER, ID);
			_VertexBuffer = cast()Buffer;			
		}
	}

	/// Ditto	
	@property VertexBuffer Vertices() {
		return _VertexBuffer;
	}

	/// Gets or sets the given IndexBuffer to be the active IndexBuffer.
	/// This method performs caching, and does not make any graphics API changes unless necessary. If external calls were made to the graphics API without the use of the GraphicsDevice, this may result in false caching.
	/// Params:
	/// 	Buffer = The buffer to set as being active, or null to clear the active buffer.
	@property void Indices(const IndexBuffer Buffer) {
		if(Buffer !is _IndexBuffer || DisableCaching) {		
			GLuint ID = Buffer is null ? 0 : Buffer.ResourceID;
			glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, ID);
			_IndexBuffer = cast()Buffer;		
		}
	}	

	/// Ditto
	@property IndexBuffer Indices() {
		return _IndexBuffer;
	}

	/// Gets the active textures for the graphics API.
	@property SamplerCollection Samplers() {
		if(_Samplers is null)
			CreateSamplers();
		return _Samplers;
	}

	/// Gets or sets the currently active Sampler for the GraphicsDevice.
	/// Params:
	/// 	Value = The Sampler to set as being active.
	@property void ActiveSampler(Sampler Value) {
		if(_Samplers is null)
			CreateSamplers();		
		//if(_ActiveSampler !is Value || DisableCaching) {					
		// TODO: Temporarily disabled caching, because the sampler may not have the same texture and uses this method to bind the texture.	
			assert(Value !is null, "Unable to set a null sampler.");
			glActiveTexture(GL_TEXTURE0 +  Value.Slot);			
			uint TextureID = Value.Value is null ? 0 : Value.Value.ResourceID;			
			glBindTexture(GL_TEXTURE_2D, TextureID);			
			_ActiveSampler = Value;
			debug GraphicsErrorHandler.CheckErrors();
		//}
	}

	/// Ditto
	@property Sampler ActiveSampler() {
		if(_Samplers is null)
			CreateSamplers();
		return _ActiveSampler;
	}

	/// Gets or sets the specified effect to be used for drawing.
	/// This method performs caching, and does not make any graphics API changes unless necessary. If external calls were made to the graphics API without the use of the GraphicsDevice, this may result in false caching.
	/// Params:
	///		Effect = The effect to set. A null value clears the active effect.
	@property void Program(Effect Effect) {
		if(Effect !is _Effect || DisableCaching) {
			GLuint ID = Effect is null ? 0 : Effect.ResourceID;
			glUseProgram(ID);		
			_Effect = Effect;
			debug GraphicsErrorHandler.CheckErrors();
		}
	}

	/// Ditto
	@property Effect Program() {
		return _Effect;
	}	

	/// Gets or sets the currently active VertexDeclaration to the specified value, or null to disable it.
	/// This method performs caching, and does not make any graphics API changes unless necessary. If external calls were made to the graphics API without the use of the GraphicsDevice, this may result in false caching.
	/// Params:
	/// 	Declaration = The VertexDeclaration to set as being active.
	@property void VertexElements(VertexDeclaration Declaration) {
		if(Declaration == _ActiveDeclaration && !DisableCaching)
			return;
		if(_ActiveDeclaration !is null) {
			VertexElement[] Elements = _ActiveDeclaration.Elements();
			for(size_t i = 0; i < Elements.length; i++)
				Elements[i].Disable();
		}
		if(Declaration !is null) {
			VertexElement[] Elements = Declaration.Elements();
			for(size_t i = 0; i < Elements.length; i++)
				Elements[i].Enable();
		}
		_ActiveDeclaration = Declaration;
		debug GraphicsErrorHandler.CheckErrors();
	}

	/// Ditto
	@property VertexDeclaration VertexElements() {
		return _ActiveDeclaration;
	}

	/// Draws the elements contained by the currently active VertexBuffer and IndexBuffer.
	/// Params:
	///		RenderStyle = The way which to draw the elements, such as GL_TRIANGLE_STRIP.
	///		ElementCount = The number of elements to draw.
	///		ElementType = The type of the elements to draw, such as GL_UNSIGNED_SHORT.
	void DrawElements(RenderStyle RenderStyle, size_t ElementCount, ElementType ElementType) {
		enforce(_VertexBuffer !is null, "Unable to draw elements without a currently set vertex buffer.");	
		enforce(_IndexBuffer !is null, "Unable to draw elements without a currently set index buffer.");	
		glDrawElements(cast(GLenum)RenderStyle, cast(GLsizei)ElementCount, cast(GLenum)ElementType, null);		
		debug GraphicsErrorHandler.CheckErrors();
	}

	/// Draws the elements contained by the currently active VertexBuffer, without using an IndexBuffer.
	/// Params:
	///		Style = The way which to draw the elements, such as GL_TRIANGLE_STRIP.
	///		ElementCount = The number of elements to draw.
	void DrawArrays(RenderStyle Style, size_t ElementCount) {
		enforce(_VertexBuffer !is null, "Unable to draw arrays without a currently set vertex buffer.");	
		glDrawArrays(cast(GLenum)Style, 0, cast(GLsizei)ElementCount);
		debug GraphicsErrorHandler.CheckErrors();
	}

	void DrawRangeElements(RenderStyle RenderStyle, size_t StartIndex, size_t EndIndex, size_t NumElements, ElementType ElementType, size_t OffsetRendering) {
		assert(_VertexBuffer !is null, "Unable to draw elements without a currently set buffer.");		
		glDrawRangeElements(cast(GLenum)RenderStyle, cast(GLsizei)StartIndex, cast(GLsizei)EndIndex, cast(GLsizei)NumElements, cast(GLenum)ElementType, (cast(ubyte*)0 + OffsetRendering));
		debug GraphicsErrorHandler.CheckErrors();
	}

	/// Gets the render state of the graphics device.
	@property RenderState State() {
		return _State;
	}

	/// Gets the RenderTargets available to be rendered on, or have a RenderTarget attached to.
	@property RenderTargetCollection RenderTargets() {
		if(_RenderTargets is null)
			CreateRenderTargets();
		return _RenderTargets;
	}

	/// Queues the given callback to be invoked by the application at some later time on the main thread.
	/// This operation is thread-safe.
	/// Params:
	/// 	Callback = The callback to invoke.
	void QueueCallback(void delegate() Callback) {
		synchronized(SyncLock) {
			QueuedCalls ~= Callback;
		}
	}

	/// Invokes the callbacks currently queued.
	/// This $(B must) be done from the main graphics thread.
	void InvokeCallbacks() {
		synchronized(SyncLock) {
			foreach(void delegate() Callback; QueuedCalls)
				Callback();
			QueuedCalls = null;
		}
	}

private:
	__gshared VertexBuffer _VertexBuffer;
	__gshared IndexBuffer _IndexBuffer;
	__gshared Effect _Effect;	
	__gshared SamplerCollection _Samplers;
	__gshared Color _ClearColor;
	__gshared VertexDeclaration _ActiveDeclaration;
	__gshared Sampler _ActiveSampler;
	__gshared RenderState _State;
	__gshared RenderTargetCollection _RenderTargets;	
	__gshared void delegate()[] QueuedCalls;	
	__gshared const(Object) SyncLock;

	void CreateSamplers() {
		enforce(_Samplers is null, "Attempted to re-create Samplers.");			
		
		_Samplers = new SamplerCollection();
		_ActiveSampler = _Samplers[0];
	}

	void CreateRenderTargets() {
		enforce(_RenderTargets is null, "Attempted to re-create RenderTargets.");

		_RenderTargets = new RenderTargetCollection();

	}
}
