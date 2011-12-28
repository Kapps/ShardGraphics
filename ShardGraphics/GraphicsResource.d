module ShardGraphics.GraphicsResource;
import gl;
import ShardTools.IDisposable;
import ShardGraphics.GraphicsErrorHandler;

/// The base class for any graphics-related resource.
abstract class GraphicsResource {

public:
	/// Initializes a new instance of the GraphicsResource object.
	this() {
		this.ResourceID = 0;
	}

	/// Initializes a new instance of the GraphicsResource object.
	/// Note that once this object is deleted, the resource will be deleted as well.
	/// Params:
	///		ResourceID = The pre-created ID to assign for this resource.
	this(GLuint ResourceID) {
		this._ResourceID = ResourceID;
	}

	invariant() {
		GraphicsErrorHandler.CheckErrors();
	}

	/// Gets the ID for this resource.
	/// A value of 0 indicates no resource is created, or it is disposed of.
	@property final GLuint ResourceID() const {
		return _ResourceID;
	}
	
	/+ /// Called after the graphics context has been recreated, causing this asset to have to be recreated as well.
	protected abstract void RecreateAsset();+/

	/// Deletes the graphics resource represented by the given ID.
	/// Params:
	/// 	ID = The ID of the resource to delete.
	protected abstract void DeleteResource(GLuint ID);

	/// Sets the resource ID to the specified value, deleting the old value if needed.
	@property protected final void ResourceID(GLuint ID) {
		if(_ResourceID != 0)
			DeleteResource(_ResourceID);
		_ResourceID = ID;
	}	

	/// Gets a value indicating whether this resource has been deleted.
	@property const bool IsDeleted() {
		return _Disposed;
	}

	~this() {
		if(_ResourceID != 0)
			DeleteResource(_ResourceID);
		_Disposed = true;
		_ResourceID = 0;
	}
	
private:
	GLuint _ResourceID;
	bool _Disposed;
}