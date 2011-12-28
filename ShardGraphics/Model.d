module ShardGraphics.Model;
private import ShardMath.Matrix;
private import ShardContent.IAsset;
private import ShardTools.ReadOnlyCollection;
public import ShardGraphics.ModelBone;
private import ShardGraphics.Effect;
private import ShardGraphics.VertexBufferObject;
public import ShardGraphics.ModelMesh;

alias ReadOnlyCollection!(ModelBone, ModelBone[]) ModelBoneCollection;
alias ReadOnlyCollection!(ModelMesh, ModelMesh[]) ModelMeshCollection;

/// Represents a single 3D Model.
/// A Model is essentially a collection of ModelMeshes and the data needed to manipulate them.
class Model : IAsset {

public:
	/// Initializes a new instance of the Model object.
	this(ModelBone[] Bones, ModelMesh[] Meshes, ModelBone RootBone) {
		this._Bones = Bones;
		this._Children = Meshes;
		this._RootBone = RootBone;
	}
		
	/// Provides access to all of the bones contained by this Model, including subchild bones.
	@property ModelBoneCollection Bones() {
		return ModelBoneCollection(_Bones);
	}

	/// Gets the meshes that this model contains.
	@property ModelMeshCollection Meshes() {
		return ModelMeshCollection(_Children);
	}

	/// Gets the root bone for this Model.
	@property ModelBone RootBone() {
		return _RootBone;
	}

	/// Creates a new Model from the given model data.
	/// This is a convenience function to prevent having to store all of the model data and for easier rendering.
	/// Params:
	/// 	Vertices = The vertices the model contains.
	/// 	Indices  = The indices the model contains.
	/// 	Program  = The effect to apply on the model.
	/// 	VertDec  = A vertex declaration for the model.
	static Model CreateSinglePart(VertexBuffer Vertices, IndexBuffer Indices, Effect Program, VertexDeclaration VertDec) {
		VertexBufferSlice VBS = VertexBufferSlice(Vertices, 0, Vertices.SizeInBytes);
		IndexBufferSlice IBS = IndexBufferSlice(Indices, 0, Indices.SizeInBytes);
		ModelMeshPart Part = new ModelMeshPart(VBS, IBS, Program, VertDec);
		ModelBone Root = new ModelBone("Root", 0, Matrix4f.Identity);
		ModelMesh Mesh = new ModelMesh("Mesh", [Part], Root);
		Model Result = new Model([Root], [Mesh], Root);
		return Result;
	}
	
private:
	// TODO: This should store an AbsoluteBoneTransforms that gets automatically updated when a bone is transformed.
	ModelBone[] _Bones;
	ModelMesh[] _Children;
	ModelBone _RootBone;
}