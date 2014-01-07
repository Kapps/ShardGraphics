module ShardGraphics.ShaderImporter;
private import std.exception;
public import ShardContent.ContentImporter;
public import ShardContent.ContentLoader;
private import ShardGraphics.Shader;
private import ShardGraphics.ShaderAttribute;
private import std.stream;
import ShardGraphics.GraphicsDevice;

class ShaderImporter : ContentImporter!(Shader) {

public:
	/// Initializes a new instance of the ShaderImporter object.
	this() {
		
	}
	
	/// Imports the shader from the specified data.
	override ImportResult ImportAsset(StreamReader Data) {
		ShaderType Type;
		ShaderAttribute[] Attributes;
		string[] Blocks;
		string Source;
		ReadData(Data, Type, Attributes, Blocks, Source);
		Shader Result = new Shader(Type, Blocks, Source, Attributes);
		return new ImportResult(Result, true);
	}

	/// Reloads a previously loaded asset with the new data.
	/// It is up to the implementor to notify the asset of the newly changed data, and handle the actual updating.
	/// The result should not change the reference, as multiple objects may reference the same asset. As such, this method returns void.
	/// If ImportAsset always has CanReload be false, this method will never be called.
	/// Params:
	///		Asset = The asset to reload.
	///		Data = The data to import the new version of the asset from.
	override void ReloadAsset(Shader Asset, StreamReader Data) {
		// TODO: Implement.
		ShaderType Type;
		ShaderAttribute[] Attributes;
		string[] Uniforms;
		string Source;
		GraphicsDevice.QueueCallback(() {
			ReadData(Data, Type, Attributes, Uniforms, Source);
			enforce(Type == Asset.Type, "When reloading a shader, it must maintain the same shader type (pixel/vertex/geometry).");
		
			Asset.Reload(Uniforms, Source, Attributes);
		});
	}

private:
	void ReadData(StreamReader Data, out ShaderType Type, out ShaderAttribute[] Attributes, out string[] UniformBlockNames, out string Source) {
		int ShaderTypeNum = Data.Read!int;
		Type = cast(ShaderType)ShaderTypeNum;
		ubyte AttributeCount = Data.Read!ubyte;		
		Attributes = new ShaderAttribute[AttributeCount];		
		for(size_t i = 0; i < AttributeCount; i++) {
			string Name = Data.ReadPrefixed!char().idup;
			string AttribType = Data.ReadPrefixed!char().idup;
			byte Modifier = Data.Read!byte;			
			Attributes[i] = new ShaderAttribute(Name, AttribType, cast(AttributeModifier)Modifier);			
		}
		int NumBlocks = Data.Read!int;
		UniformBlockNames = new string[NumBlocks];
		for(int i = 0; i < NumBlocks; i++)
			UniformBlockNames[i] = Data.ReadPrefixed!char().idup;
		Source = Data.ReadPrefixed!char().idup;
	}

}