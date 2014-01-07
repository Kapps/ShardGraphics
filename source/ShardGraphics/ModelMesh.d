module ShardGraphics.ModelMesh;
public import ShardGraphics.ModelBone;
private import ShardTools.ReadOnlyCollection;
public import ShardGraphics.ModelMeshPart;

/// Represents a single mesh in a Model.
/// A mesh is essentially a single part of a model with it's own transforms.
/// A ModelMesh consists of one or more ModelMeshParts which contain the actual drawing data.
/// A ModelMesh is split into ModelMeshParts by the Effect used for the Part.
class ModelMesh  {

alias ReadOnlyCollection!(ModelMeshPart, ModelMeshPart[]) ModelMeshPartCollection;

public:
	/// Initializes a new instance of the ModelMesh object.
	this(string Name, ModelMeshPart[] Parts, ModelBone ParentBone) {
		this._Name = Name;
		this._Parts = Parts;
		this._ParentBone = ParentBone;
	}	

	/// Gets the bone that this mesh is relative to.
	@property ModelBone ParentBone() {
		return _ParentBone;
	}

	/// Returns a struct to iterate over all unique active effects for this ModelMesh's parts.	
	@property auto Effects() {		
		struct ModelMeshEffectsResult {			
			int opApply(int delegate(Effect) dg) {
				int Result = 0;		
				bool[Effect] CreatedEffects;
				foreach(ModelMeshPart Part; Parts) {
					bool Existed = (Part.ActiveEffect in CreatedEffects) is null;
					if(!Existed) {
						CreatedEffects[Part.ActiveEffect] = true;
						if((Result = dg(Part.ActiveEffect)) != 0)
							break;
					}
				}
				return Result;				
			}			

			this(ModelMeshPart[] Parts) {
				this.Parts = Parts;
			}

			private ModelMeshPart[] Parts;
		}
		return ModelMeshEffectsResult(_Parts);
	}

	/// Gets the parts that this ModelMesh contains.
	@property ModelMeshPartCollection Parts() {
		return ModelMeshPartCollection(_Parts);
	}

	/// Gets the name of this mesh.
	@property string Name() const {
		return _Name;
	}

private:	
	ModelBone _ParentBone;
	ModelMeshPart[] _Parts;	
	string _Name;	
}