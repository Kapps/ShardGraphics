module ShardGraphics.ModelBatch;
private import std.array;
private import ShardGraphics.RenderState;
private import ShardGraphics.Sampler;
private import ShardGraphics.MaterialShader;
private import ShardFramework.Camera;
private import ShardGraphics.Model;
private import ShardMath.Matrix;
private import ShardGraphics.SpriteBatch;

/// The state of the ModelBatch; either in a Begin-End block, or idle.
enum ModelRendererState {
	Idle,
	InBeginEndBlock
}

/// Determines how to render a model.
enum ModelRenderMode {
	/// Immediately render the model without batching.
	Immediate,
	/// Batch multiple instances of the same model together.
	/// This requires a VertexShader that supports instancing.
	/// There must also be a shared uniform buffer named Camera containing a mat4 named View and Proj.
	Batched
}

/// Provides efficient rendering of models by instancing through shaders.
class ModelBatch  {

public:
	/// Initializes a new instance of the ModelBatch object.
	this() {
		
	}

	/// Gets the state of this ModelBatch.
	@property ModelRendererState State() const {
		return _State;
	}

	/// Renders the given ModelMeshPart.
	/// This method sets no shader parameters; it is assumed that the caller sets them.
	/// Params:
	/// 	Part = The MeshPart to render.
	/// 	RenderMode = The way to render the ModelMeshPart. At the moment, only Immediate is supported.
	void RenderMeshPart(ModelMeshPart Part, ModelRenderMode RenderMode) {
		//GraphicsDevice.State.AlphaEnabled = true;			
		GraphicsDevice.Program = Part.ActiveEffect;
		GraphicsDevice.Vertices = Part.Vertices.VBO;
		GraphicsDevice.Indices = Part.Indices.VBO;
		GraphicsDevice.VertexElements = Part.ActiveDeclaration;
		GLsizei Size = Part.Vertices.Size, Offset = Part.Vertices.Offset;
		GLsizei VertexSize = Part.ActiveDeclaration.Elements[0].VertexSize;
		GLsizei ElementSize = Part.Indices.VBO.ElementSize;		
		// TODO: Is this correct? Should be... but probably is not. :/
		glDrawElements(GL_TRIANGLES, Size / VertexSize, ElementSize == 2 ? GL_UNSIGNED_SHORT : ElementSize == 4 ? GL_UNSIGNED_INT : 0, cast(void*)(Offset / VertexSize));		
		//glDrawElements(GL_TRIANGLES, Size / ElementSize / 3, GL_UNSIGNED_SHORT, cast(void*)(Offset / VertexSize));		
	}	

	/+ // Removed. Possibly only for now? It's just a dumb way of doing things, too limited and doesn't allow easy changing of effects.
	/// Renders the given model. At the moment, this only renders the model with Immediate mode.
	/// This method only works well when using the default MaterialShader.
	/// For all other shaders, no shader parameters are adjusted and no texture samplers set.
	/// Params:
	/// 	model = The model to render.
	/// 	RenderMode = Determines how to render the model; either batched or immediate.
	/// 	World = The World matrix for the model.
	void RenderModel(Model model, Matrix4f World, ModelRenderMode RenderMode) {
		//GraphicsDevice.State.AlphaEnabled = true;
		GraphicsDevice.State.CullMode = CullFace.CounterClockwise;
		GraphicsDevice.State.PerformDepthTest = true;
			
		// TODO: Actually perform some batching here...
		// At the least use a uniform buffer.
		Matrix4f Projection = Camera.Default.ProjectionMatrix;
		//Matrix4f World = Camera.Default.WorldMatrix;
		Matrix4f View = Camera.Default.ViewMatrix;		
		foreach(ModelMesh Mesh; model.Meshes) {
			Matrix4f MeshWorld = Mesh.ParentBone.Transform * World;
			foreach(ModelMeshPart Part; Mesh.Parts) {
				MaterialShader Program = cast(MaterialShader)Part.ActiveEffect;
				GraphicsDevice.Program = Program;
				Shader VertShader = Program.GetShader(ShaderType.VertexShader);
				Shader FragShader = Program.GetShader(ShaderType.PixelShader);
				//throw new Exception("We can avoid setting any parameters here by using a shared uniform buffer; then rendering can be done with a custom effect too!");
				//VertShader.Parameters["Projection"].Value = Projection;
				//VertShader.Parameters["View"].Value = View;
				VertShader.Parameters["World"].Value = MeshWorld;
				Sampler Samp = GraphicsDevice.Samplers[0];
				GraphicsDevice.ActiveSampler = Samp;
				Samp.Value = Program.MeshTexture;
				FragShader.Parameters["Texture"].Value = 0;
				GraphicsDevice.Vertices = Part.Vertices.VBO;
				GraphicsDevice.Indices = Part.Indices.VBO;
				GraphicsDevice.VertexElements = Part.ActiveDeclaration;
				GLsizei Size = Part.Vertices.Size, Offset = Part.Vertices.Offset;
				GLsizei ElementSize = 2;
				glDrawElements(GL_TRIANGLES, Size / ElementSize, GL_UNSIGNED_SHORT, cast(void*)(Offset / ElementSize));
			}
		}
	}+/
	
	private struct ModelInstance {
		Matrix4f Transform;
		Matrix4f Settings;
	}

	/// Gets the default ModelBatch to use for rendering.
	@property static ModelBatch Default() {
		if(_Default is null)
			_Default = new ModelBatch();
		return _Default;
	}
	
private:	
	static ModelBatch _Default;
	ModelRendererState _State;
}