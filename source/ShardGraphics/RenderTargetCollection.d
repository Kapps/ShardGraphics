module ShardGraphics.RenderTargetCollection;
private import ShardGraphics.GraphicsDevice;
private import std.algorithm;
private import std.array;
private import std.exception;
public import ShardGraphics.RenderTarget;
import gl;

/// Provides a collection of RenderTargets active on the GraphicsDevice.
class RenderTargetCollection  {

public:
	/// Initializes a new instance of the RenderTargetCollection object.
	this() {
		GLint MaxRenderTargets;
		glGetIntegerv(GL_MAX_DRAW_BUFFERS, &MaxRenderTargets);
		this._Capacity = MaxRenderTargets;
		this._Count = 1;
		_Targets = new RenderTarget[_Capacity];
		_Targets[0] = RenderTarget.BackBuffer;
	}

	/// Gets the maximum number of RenderTargets the GraphicsDevice supports.
	@property size_t Capacity() const {
		return _Capacity;
	}

	/// Gets the number of RenderTargets currently set on the GraphicsDevice.
	/// This is always at least one, and is greater than one when using multiple render targets.
	@property size_t Count() const {
		return _Count;
	}

	/// Sets the RenderTarget at the given index to the given value.
	/// It is strongly recommended to set the previously active RenderTarget (which is returned) back instead of assigning the BackBuffer when done.
	/// Params:
	/// 	Index = The index to set the RenderTarget at. When using only a single render-target, this should be zero.
	/// 	Value = The RenderTarget to assign, or null to assign the backbuffer.
	/// Returns:
	/// 	The RenderTarget that was assigned prior to this assignment overwriting it.
	RenderTarget Set(size_t Index, RenderTarget Value) {
		if(Index != 0)
			throw new Exception("Multiple render-targets are not yet supported.");
		if(_Targets[Index] is Value && !GraphicsDevice.DisableCaching)
			return Value;
		auto Old = _Targets[Index];
		_Targets[Index] = Value;
		if(Index == 0) {
			if(Value is null || Value is RenderTarget.BackBuffer) {
				glBindFramebuffer(GL_FRAMEBUFFER, 0);				
				_Targets[0] = RenderTarget.BackBuffer;
				//glViewport(0, 0, Game.Instance.Window.Size.X, Game.Instance.Window.Size.Y);
			} else {
				glBindFramebuffer(GL_FRAMEBUFFER, Value.ResourceID);
				//glViewport(0, 0, Value.Width, Value.Height);
			}
		}		
		return Old;			
		/+UpdateMRT();
		if(_Targets[Index] !is null) {
			// Clear the old one. Remember we're relying on this for the below part.
			_Targets[Index] = null;
		}		
		if(Value !is null) {
			// Set the new one. Remember that this means we're using multiple render-targets.
			// Should this throw an exception when AA is enabled?
		} else if(Index == 0) {
			// Go back to the backbuffer.
			
		}+/
	}

	private void UpdateMRT() {
		RenderTarget[] SetTargets = array(filter!"a !is null"(_Targets));
		if(SetTargets.length == 0) {
			
		}
	}

	RenderTarget opIndex(size_t Index) {
		return _Targets[Index];
	}
	
private:
	RenderTarget[] _Targets;
	int _Capacity;
	int _Count;
}