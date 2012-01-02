module ShardGraphics.ShaderImporter;
public import ShardContent.ContentImporter;
public import ShardContent.ContentLoader;
private import ShardGraphics.Shader;
private import ShardGraphics.ShaderAttribute;
private import std.stream;

class ShaderImporter : ContentImporter!(Shader) {

public:
	/// Initializes a new instance of the ShaderImporter object.
	this() {
		
	}
	
	/// Imports the shader from the specified data.
	override ImportResult ImportAsset(StreamReader Data) {
		int ShaderTypeNum = Data.Read!int;
		ubyte AttributeCount = Data.Read!ubyte;		
		ShaderAttribute[] Attributes = new ShaderAttribute[AttributeCount];		
		for(size_t i = 0; i < AttributeCount; i++) {
			string Name = Data.ReadPrefixed!char().idup;
			string Type = Data.ReadPrefixed!char().idup;
			byte Modifier = Data.Read!byte;			
			Attributes[i] = new ShaderAttribute(Name, Type, cast(AttributeModifier)Modifier);			
		}
		int NumBlocks = Data.Read!int;
		string[] Blocks = new string[NumBlocks];
		for(int i = 0; i < NumBlocks; i++)
			Blocks[i] = Data.ReadPrefixed!char().idup;
		string Source = Data.ReadPrefixed!char().idup;		
		Shader Result = new Shader(cast(ShaderType)ShaderTypeNum, Blocks, Source, Attributes);
		return new ImportResult(Result, false);
	}

	/// Reloads a previously loaded asset with the new data.
	/// It is up to the implementor to notify the asset of the newly changed data, and handle the actual updating.
	/// The result should not change the reference, as multiple objects may reference the same asset. As such, this method returns void.
	/// If ImportAsset always has CanReload be false, this method will never be called.
	/// Params:
	///		Asset = The asset to reload.
	///		Data = The data to import the new version of the asset from.
	override void ReloadAsset(Shader Asset, StreamReader Data) {
		// TODO: Implement
		assert(0, "Not yet implemented.");
	}

private:
}