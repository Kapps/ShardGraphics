module ShardGraphics.ModelBone;
private import std.exception;
private import ShardMath.Matrix;


/// Represents a single bone inside a model.
class ModelBone  {

public:
	/// Initializes a new instance of the ModelBone object.
	this(string Name, size_t Index, Matrix4f Transform) {
		this._Name = Name;
		this._Index = Index;
		this._Transform = Matrix4f.Identity;		
	}

	/// Gets the parent bone for this bone, or null if it has no parent.
	@property ModelBone Parent() {
		enforce(ParentAssigned, "Unable to get parent before it is assigned.");
		return _Parent;
	}
	
	/// Initializes the parent bone. If a parent bone has already been set, this throws an exception.
	/// This is here because bones may be recursively dependent, so it may not be possible to know the parent before all bones are created.
	/// Params:
	/// 	Parent = The parentbone to assign.
	void InitializeParent(ModelBone Parent) {
		enforce(!ParentAssigned, "A parent was already assigned.");		
		ParentAssigned = true;
		this._Parent = Parent;
	}

	/// Gets or sets the transform matrix for this bone.
	@property Matrix4f Transform() {
		return _Transform;
	}

	/// Gets the absolute transform of this bone.
	@property Matrix4f AbsoluteTransform() {
		Matrix4f Result = _Transform;
		for(ModelBone Bone = this.Parent; Bone !is null; Bone = Bone.Parent)
			Result *= Bone.Transform;
		return Result;
	}

	/// Ditto
	@property void Transform(Matrix4f Value) {
		_Transform = Value;
	}

	/// Gets the name of this bone.
	@property string Name() {
		return _Name;
	}

	/// The index of this Bone in the owning Model.
	@property size_t Index() const {
		return _Index;
	}
	
private:
	bool ParentAssigned;
	ModelBone _Parent;
	Matrix4f _Transform;
	string _Name;
	size_t _Index;
	size_t _ParentIndex;
}