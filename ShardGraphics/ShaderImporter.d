module ShardGraphics.ShaderImporter;
public import ShardContent.ContentImporter;
public import ShardContent.ContentLoader;
public import ShardContent.IAsset;
private import ShardGraphics.Shader;
private import ShardGraphics.ShaderAttribute;
private import std.stream;

class ShaderImporter : ContentImporter!(Shader) {

public:
	/// Initializes a new instance of the ShaderImporter object.
	this() {
		
	}
	
	/// Imports the shader from the specified data.
	override Shader ImportAsset(StreamReader Data) {
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
		return new Shader(cast(ShaderType)ShaderTypeNum, Blocks, Source, Attributes);
	}

private:
}