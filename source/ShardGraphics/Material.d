module ShardGraphics.Material;
private import ShardGraphics.Texture;
private import ShardTools.Color;


/// Represents the material used for a model. This object is immutable, and is generally used for just default values.
class Material  {

public:
	
	/// Creates a new Material with the given values.
	/// Params:
	/// 	Ambient = The ambient color for this material.
	/// 	Diffuse = The diffuse color for this material.
	/// 	Specular = The specular color for this material.
	/// 	Emissive = The emissive color for this material.
	/// 	SpecularPower = Determines how strong the specular color is.
	/// 	MeshTexture = The texture to use for this material. Can be null.
	/// 	Alpha = The alpha value for this material, from 0 to 1.
	this(Color Ambient, Color Diffuse, Color Specular, Color Emissive, float SpecularPower, Texture MeshTexture, float Alpha = 1) {
		this.Ambient = Ambient;
		this.Diffuse = Diffuse;
		this.Specular = Specular;
		this.Emissive = Emissive;
		this.SpecularPower = SpecularPower;
		this._MeshTexture = MeshTexture;
		this.Alpha = Alpha;
	}

	/// The ambient color for this material.
	const Color Ambient;
	/// The diffuse color for this material.
	const Color Diffuse;
	/// The specular color for this material.
	const Color Specular;
	/// The emissive color for this material.
	const Color Emissive;
	/// Determines how strong the specular color is.
	const float SpecularPower;
	/// The texture to use for this material. Can be null.
	@property Texture MeshTexture() {
		return _MeshTexture;
	}
	/// The alpha value for this material, from 0 to 1.
	const float Alpha;

	private Texture _MeshTexture;
}