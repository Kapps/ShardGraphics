module ShardGraphics.MaterialShader;
private import ShardGraphics.Sampler;
private import std.stdio;
private import std.conv;
private import ShardGraphics.ShaderImporter;
private import ShardContent.ContentLoader;
private import ShardGraphics.Effect;
private import ShardGraphics.Texture;
private import ShardTools.Color;
import ShardMath.Vector;
import ShardMath.Matrix;
public import ShardGraphics.Material;

import ShardGraphics.Shader;

/// A basic effect capable of rendering a material.
/// The shader has some helper methods to be used with a Material, but there is no requirement.
/// The parameters may instead be set one at a time.
/// This is an effect, but it should not have it's parameters altered manually. 
/// Use the properties in this class instead.
class MaterialShader : Effect {

public:
	/// Initializes a new instance of the MaterialShader object.
	this() {
		this._FragmentShader = ContentLoader.Default.Load!(ShaderImporter)("Content/Shaders/MaterialFragShader").Clone();
		this._VertexShader = ContentLoader.Default.Load!(ShaderImporter)("Content/Shaders/MaterialVertShader").Clone();
		Shader[2] Shaders;
		Shaders[0] = _FragmentShader;
		Shaders[1] = _VertexShader;		
		super(Shaders);
		_FragmentShader.Parameters["Texture"].Value = 0;
		// TODO: Set default values from shader. Get all fields I guess? Need a way of telling they're parameter fields.
	}

	/// Sets the parameters for this shader by applying the given material.
	/// Params:
	/// 	material = The material to apply.
	void SetMaterial(Material material) {
		AmbientColor = material.Ambient;
		SpecularColor = material.Specular;
		DiffuseColor = material.Diffuse;
		EmissiveColor = material.Emissive;
		SpecularPower = material.SpecularPower;
		MeshTexture = material.MeshTexture;
	}	

	private static string ParameterMixin(string ParameterType, string ParameterName, ShaderType Type, bool CheckCache) {
		string ShaderField = (Type == ShaderType.PixelShader ? "_FragmentShader" : Type == ShaderType.VertexShader ? "_VertexShader" : "");
		assert(ShaderField.length > 1, "Invalid shader type.");
		string Result = "
				private " ~ ParameterType ~ " _" ~ ParameterName ~ ";
				@property public " ~ ParameterType ~ " " ~ ParameterName ~ "() {
					return _" ~ ParameterName ~ ";
				}
				@property public void " ~ ParameterName ~ "(" ~ ParameterType ~ " Value) {";
		if(CheckCache) {
				Result ~= "
					if(this._" ~ ParameterName ~ " == Value)
						return;
					";
		}
		Result ~= "
					this._" ~ ParameterName ~ " = Value;
					//this." ~ ShaderField ~ ".Parameters.Get(\"" ~ ParameterName ~ "\").Value = Value;
				}
				";		
		return Result;			
	}

	/// Gets or sets the texture to render the material with.
	@property Texture MeshTexture() {
		return _MeshTexture;
	}

	/// Ditto
	@property void MeshTexture(Texture Value) {
		_MeshTexture = Value;
		// TODO: What happens next..?
		// Set the sampler every time this is being drawn?
	}
	
	mixin(ParameterMixin("Color", "AmbientColor", ShaderType.PixelShader, true));
	mixin(ParameterMixin("Color", "SpecularColor", ShaderType.PixelShader, true));
	mixin(ParameterMixin("Color", "DiffuseColor", ShaderType.PixelShader, true));
	mixin(ParameterMixin("Color", "EmissiveColor", ShaderType.PixelShader, true));
	mixin(ParameterMixin("float", "Alpha", ShaderType.PixelShader, false));
	mixin(ParameterMixin("float", "SpecularPower", ShaderType.PixelShader, false));
	mixin(ParameterMixin("Vector3f", "LightDirection", ShaderType.PixelShader, false));
	mixin(ParameterMixin("Vector3f", "LightDiffuse", ShaderType.PixelShader, false));
	mixin(ParameterMixin("Vector3f", "LightSpecular", ShaderType.PixelShader, false));
	mixin(ParameterMixin("Matrix4f", "World", ShaderType.VertexShader, false));
	/+mixin(ParameterMixin("Matrix4f", "View", ShaderType.VertexShader, false));
	mixin(ParameterMixin("Matrix4f", "Projection", ShaderType.VertexShader, false));+/

private:	
	Texture _MeshTexture;	
	Shader _FragmentShader, _VertexShader;
}


/// Provides a structure that contains the data used for the uniforms for a MaterialShader.
struct MaterialShaderUniforms {
	Matrix4f View;
	Matrix4f Projection;	
}