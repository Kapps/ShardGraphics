module ShardGraphics.RenderState;
private import ShardGraphics.GraphicsDevice;
import gl;

enum BlendStyle {
	 None = 0,
	 InvertSource = GL_ONE_MINUS_SRC_ALPHA,
	 SourceAlpha = GL_SRC_ALPHA,
	 InvertDestination = GL_ONE_MINUS_DST_ALPHA,
	 DestinationAlpha = GL_DST_ALPHA,
	 One = GL_ONE,
	 Zero = GL_ZERO
}

enum CullFace {
	None = 0,
	Clockwise = 1,
	CounterClockwise = 2
}

/// Reprsents the render state of the GraphicsDevice.
class RenderState  {

public:
	/// Initializes a new instance of the RenderState object.
	this() {
		
	}

	/// Gets the blend function for the source alpha.
	@property const BlendStyle SourceAlpha() {
		return _SrcBlend;
	}

	/// Gets the blend function for the destination alpha.
	@property const BlendStyle DestinationAlpha() {
		return _DstBlend;
	}

	/// Gets a value indicating whether alpha blending is enabled.
	@property const bool AlphaEnabled() {
		return _SrcBlend != BlendStyle.None && _DstBlend != BlendStyle.None;
	}

	/// Sets the blend function for the source and destination alpha, or none to disable alpha blending.
	void SetAlpha(BlendStyle Source, BlendStyle Destination) {
		if(_SrcBlend == Source && _DstBlend == Destination && !GraphicsDevice.DisableCaching)
			return;
		bool WasEnabled = AlphaEnabled;
		if(Source == BlendStyle.None)
			Source = BlendStyle.One;
		if(Destination == BlendStyle.None)
			Destination = BlendStyle.Zero;
		glBlendFunc(cast(GLenum)Source, cast(GLenum)Destination);
		_SrcBlend = Source;
		_DstBlend = Destination;
		if(WasEnabled != AlphaEnabled) {
			if(AlphaEnabled)
				glEnable(GL_BLEND);
			else
				glDisable(GL_BLEND);
		}
	}

	/// Gets or sets a value indicating whether to preform depth testing, discarding polygons that are rendered behind existing ones.
	@property const bool PerformDepthTest() {
		return _DepthTestEnabled;
	}

	/// Ditto
	@property void PerformDepthTest(bool Value) {
		if(Value == _DepthTestEnabled && !GraphicsDevice.DisableCaching)
			return;
		if(Value)
			glEnable(GL_DEPTH_TEST);
		else
			glDisable(GL_DEPTH_TEST);
		this._DepthTestEnabled = Value;		
	}

	/// Gets or sets how to cull vertices from rendered objects.
	@property CullFace CullMode() const {
		return _CullMode;
	}

	/// Ditto
	@property void CullMode(CullFace Value) {
		if(_CullMode == Value && !GraphicsDevice.DisableCaching)
			return;
		if(_CullMode == CullFace.None)
			glDisable(GL_CULL_FACE);
		else {
			glEnable(GL_CULL_FACE);
			glCullFace(GL_BACK);
			GLenum Style = Value == CullFace.Clockwise ? GL_CW : GL_CCW;
			glFrontFace(Style);
		}
	}

	/// Gets or sets whether anti-aliasing is enabled.
	@property bool AntiAliasing() const {
		return _AntiAliasing;
	}

	/// Ditto
	@property void AntiAliasing(bool Value) {	
		if(Value == _AntiAliasing && !GraphicsDevice.DisableCaching)
			return;
		if(Value)
			glEnable(GL_MULTISAMPLE);
		else
			glDisable(GL_MULTISAMPLE);
		// TODO: Apply changes.
		//Game.Instance.Window.ApplyChanges();
	}

	/// Gets or sets the level of anti-aliasing to use, provided that anti-aliasing is enabled.
	@property int MultiSampleCount() const {
		return _MultiSampleCount;
	}

	/// Ditto
	@property void MultiSampleCount(int Value) {
		if(Value == _MultiSampleCount)
			return;
		// TODO: Validate that this is a supported amount of samples.
		_MultiSampleCount = Value;
		//Game.Instance.Window.ApplyChanges();
	}
	
private:
	BlendStyle _SrcBlend;
	BlendStyle _DstBlend;
	CullFace _CullMode;
	bool _DepthTestEnabled;
	bool _AntiAliasing = false;
	int _MultiSampleCount = 4;
}