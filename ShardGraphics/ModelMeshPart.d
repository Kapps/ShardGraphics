module ShardGraphics.ModelMeshPart;

public import ShardGraphics.Effect;
public import ShardGraphics.VertexBufferObject;

/// Represents a single part of a ModelMesh to be rendered.
class ModelMeshPart  {

public:
	/// Initializes a new instance of the ModelMeshPart object.
	this(VertexBufferSlice Vertices, IndexBufferSlice Indices, Effect DefaultEffect, VertexDeclaration DefaultDec) {
		this._Vertices = Vertices;	
		this._Indices = Indices;
		this._DefaultEffect = DefaultEffect;
		this._DefaultDec = DefaultDec;
		this._ActiveDec = DefaultDec;
		this._ActiveEffect = DefaultEffect;
	}

	/// Gets the VertexBuffer for this Model.
	@property VertexBufferSlice Vertices() const {
		return _Vertices;
	}

	/// Gets the IndexBuffer for this Model.
	@property IndexBufferSlice Indices() const {
		return _Indices;
	}

	/// Gets or sets the currently active Effect for this Model.
	/// That is, the one that should be used when rendering.
	@property Effect ActiveEffect() {
		return _ActiveEffect;
	}

	/// Gets the default Effect used to render this Model.
	/// This may differ from the active Effect, and is the one that the content processor decided to assign to this Model.
	@property Effect DefaultEffect() {
		return _DefaultEffect;
	}

	/// Gets or sets the VertexDeclaration used to render this Model.
	@property VertexDeclaration ActiveDeclaration() {
		return _ActiveDec;
	}

	/// Gets the default VertexDeclaration used for this Model.
	@property VertexDeclaration DefaultDeclaration() {
		return _DefaultDec;
	}

	/// Assigns a new Effect to be used for rendering this part.
	/// Params:
	/// 	Program = The Effect to assign.
	/// 	Declaration = The new VertexDeclaration to use for the Effect.
	void AssignEffect(Effect Program, VertexDeclaration Declaration) {
		this._ActiveEffect = Program;
		this._ActiveDec = Declaration;
		// TODO: Check if in middle of a render, and if so, throw or update or something.
	}
	
private:
	VertexBufferSlice _Vertices;
	IndexBufferSlice _Indices;
	Effect _DefaultEffect;
	Effect _ActiveEffect;	
	VertexDeclaration _ActiveDec;
	VertexDeclaration _DefaultDec;
}