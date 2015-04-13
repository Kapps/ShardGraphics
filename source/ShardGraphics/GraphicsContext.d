module ShardGraphics.GraphicsContext;

/// The base class for a graphics context.
abstract class GraphicsContext {

	/// Marks this context as being the currently active graphics context.
	final void makeActive() {
		makeActiveImpl();
		_current = this;
	}

	/// Override to handle the implementation of setting this context to be marked as active.
	protected abstract void makeActiveImpl();

	/// Gets the currently active graphics context.
	@property static GraphicsContext current() {
		return _current;
	}

	private static __gshared GraphicsContext _current;
}

