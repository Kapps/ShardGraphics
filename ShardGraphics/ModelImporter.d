module ShardGraphics.ModelImporter;
private import ShardGraphics.TextureImporter;
private import ShardGraphics.MaterialShader;
private import ShardMath.Matrix;
private import ShardTools.StreamReader;
private import std.stream;
public import ShardGraphics.Model;
private import ShardContent.ContentImporter;


/// A ContentImporter used to import a Model.
class ModelImporter : ContentImporter!(Model) {

public:
	/// Initializes a new instance of the ModelImporter object.
	this() {
		
	}

	private enum MaterialFlags : int {
		Ambient = 1,
		Specular = 2,
		Diffuse = 4,
		Emissive = 8,
		SpecularPower = 16,
		Alpha = 32,
		Texture = 64
	}

	private ModelBone[] ReadBones(StreamReader Stream) {
		int BoneLength = Stream.Read!int;		
		ModelBone[] Bones = new ModelBone[BoneLength];
		int[] BoneParentIndices = new int[BoneLength];
		for(int i = 0; i < BoneLength; i++) {
			int Index = Stream.Read!int;
			int ParentIndex = Stream.Read!int;
			BoneParentIndices[i] = ParentIndex;
			string Name = Stream.ReadPrefixed!char().idup;
			Matrix4f Transform = Stream.Read!Matrix4f;
			ModelBone Bone = new ModelBone(Name, Index, Transform);
			Bones[i] = Bone;
		}
		for(int i = 0; i < BoneLength; i++) {
			ModelBone Bone = Bones[i];
			int ParentIndex = BoneParentIndices[i];
			Bone.InitializeParent(ParentIndex == -1 ? null : Bones[ParentIndex]);			
		}
		return Bones;
	}

	private VertexElement ReadElement(StreamReader Stream, int Position, int Stride) {
		int Offset = Stream.Read!int;
		GLenum Format = cast(GLenum)Stream.Read!int;
		int Count = Stream.Read!int;
		return VertexElement(Position, Format, Count, Stride, Offset);
	}
	/// Imports an asset from the specified Data.
	/// Params:
	///		Data = The data to import an asset from.
	/// Returns: A newly created instance of T from the specified data.
	override Model ImportAsset(StreamReader Stream) {		
		ModelBone[] Bones = ReadBones(Stream);

		VertexBuffer[int] VBs;
		IndexBuffer[int] IBs;
		string[ModelMeshPart] TexturePaths;
		int RootIndex = Stream.Read!int;
		int NumMeshes = Stream.Read!int;
		ModelMesh[] Meshes = new ModelMesh[NumMeshes];
		for(int i = 0; i < NumMeshes; i++) {
			string Name = Stream.ReadPrefixed!char().idup;
			Vector3f BSphereCenter = Stream.Read!Vector3f;
			float BSphereRadius = Stream.Read!float;
			int ParentBoneIndex = Stream.Read!int;
			int MeshPartCount = Stream.Read!int;
			ModelMeshPart[] Parts = new ModelMeshPart[MeshPartCount];
			for(int j = 0; j < MeshPartCount; j++) {				
				int VBID = Stream.Read!int;
				int VBOffset = Stream.Read!int;
				int VBSize = Stream.Read!int;				
				int IBID = Stream.Read!int;
				int IBOffset = Stream.Read!int;
				int IBSize = Stream.Read!int;				
				VertexBuffer* VB = (VBID in VBs);				
				if(!VB) {
					VertexBuffer Created = new VertexBuffer();
					VB = &Created;
					VBs[VBID] = *VB;
				}
				IndexBuffer* IB = (IBID in IBs);
				if(!IB) {
					IndexBuffer Created = new IndexBuffer();
					IB = &Created;					
					IBs[IBID] = *IB;
				}
				VertexBufferSlice VBSlice = VertexBufferSlice(*VB, VBOffset, VBSize);
				IndexBufferSlice IBSlice = IndexBufferSlice(*IB, IBOffset, IBSize);
				/+Effect OldEffect = GraphicsDevice.Program;
				scope(exit)
					GraphicsDevice.Program = OldEffect;+/
				MaterialShader ModelEffect = new MaterialShader();
				//GraphicsDevice.Program = ModelEffect;				
				// TODO: Separate materials into MaterialProcessor, tied into ShaderProcessor.
				// TODO: Should a MeshPart have a DefaultMaterial, that has these values set?
				// If so, probably wouldn't need a bunch of MaterialShaders.
				// And if that's the case, every model with the same material could be
				// instanced with the same MaterialShader. Need a fast way of calculating if same though, such as hashing it somehow.
				// Remember the hash won't change.
				string TexturePath;
				MaterialFlags Flags = cast(MaterialFlags)Stream.Read!int;
				if((Flags & MaterialFlags.Ambient) != 0)
					ModelEffect.AmbientColor = Color(Stream.Read!Vector3f);
				if((Flags & MaterialFlags.Specular) != 0)
					ModelEffect.SpecularColor = Color(Stream.Read!Vector3f);
				if((Flags & MaterialFlags.Diffuse) != 0)
					ModelEffect.DiffuseColor = Color(Stream.Read!Vector3f);
				if((Flags & MaterialFlags.Emissive) != 0)
					ModelEffect.EmissiveColor = Color(Stream.Read!Vector3f);
				if((Flags & MaterialFlags.SpecularPower) != 0)
					ModelEffect.SpecularPower = Stream.Read!float;
				if((Flags & MaterialFlags.Alpha) != 0)
					ModelEffect.Alpha = Stream.Read!float;
				if((Flags & MaterialFlags.Texture) != 0) {
					TexturePath = Stream.ReadPrefixed!char().idup;					
				}
				// TODO: Less hard-coded way of this. Example: ModelVertexDeclaration that has named vertex elements for USAGE + USAGEINDEX. Ex: Part.Declaration.GetElement("POSITION0").
				// The material associated with it would then request specific elements, with the option of removing unused elements from vertices.
				Shader VertShader = ModelEffect.GetShader(ShaderType.VertexShader);				
				int VertexStride = Stream.Read!int;			
				int posPosition = VertShader.Parameters["InPosition"].Position;
				int posNormals = VertShader.Parameters["InNormals"].Position;
				int posTexCoords = VertShader.Parameters["InTexCoords"].Position;	
				VertexElement PositionElement = ReadElement(Stream, posPosition, VertexStride);
				VertexElement NormalElement = ReadElement(Stream, posNormals, VertexStride);
				VertexElement TexCoordElement = ReadElement(Stream, posTexCoords, VertexStride);
				VertexDeclaration VertDec = new VertexDeclaration([PositionElement, NormalElement, TexCoordElement]);
				ModelMeshPart Part = new ModelMeshPart(VBSlice, IBSlice, ModelEffect, VertDec);
				Parts[j] = Part;				
				if(TexturePath)
					TexturePaths[Part] = TexturePath;				
			}

			ModelMesh Mesh = new ModelMesh(Name, Parts, Bones[ParentBoneIndex]);
			Meshes[i] = Mesh;
		}
		int VBCount = Stream.Read!int;
		for(int i = 0; i < VBCount; i++) {
			int VBID = Stream.Read!int;
			uint VertexStride = Stream.Read!uint;
			VertexBuffer VB = VBs[VBID];						
			ubyte[] VBData = Stream.ReadPrefixed!ubyte;
			VB.SetData(VBData, VertexStride, BufferUseHint.Static, BufferAccessHint.WriteOnly);
		}
				
		int IBCount = Stream.Read!int;
		for(int i = 0; i < IBCount; i++) {
			int IBID = Stream.Read!int;			
			IndexBuffer IB = IBs[IBID];
			int IndiceSize = Stream.Read!int;
			ubyte[] IndiceData = Stream.ReadPrefixed!ubyte;
			IB.SetData(IndiceData, IndiceSize, BufferUseHint.Static, BufferAccessHint.WriteOnly);			
		}
		
		int TextureCount = Stream.Read!int;
		Texture[] LoadedTextures = new Texture[TextureCount];
		for(int i = 0;  i < TextureCount; i++) {
			string TexturePath = Stream.ReadPrefixed!char().idup;
			TextureImporter TexImporter = new TextureImporter();
			Texture texture = TexImporter.ImportAsset(Stream);
			foreach(ModelMeshPart Part; TexturePaths.keys) {
				if(TexturePaths[Part] == TexturePath) {
					MaterialShader PartShader = cast(MaterialShader)Part.ActiveEffect;
					PartShader.MeshTexture = texture;
				}
			}
			LoadedTextures[i] = texture;
		}

		Model Result = new Model(Bones, Meshes, Bones[RootIndex]);
		return Result;
	}
	
private:
}