module ShardGraphics.StockModels;
private import ShardMath.Matrix;
private import ShardMath.Quaternion;
private import std.math;
private import std.exception;
private import ShardGraphics.Model;


/// A static helper used to instantiate predefined models programatically.
/// All stock models use the ModelVertex structure as their vertices.
@disable class StockModels  {

public static:


	/+ /// Creates a Quad that stretches from [-1, 1], taking up the whole screen when rendered with no projection or view matrices.	
	/// Params:
	/// 	Program = The program to use for rendering the Model. The VertexDeclaration will match the program.
	Model Quad(Effect Program) {
		// TODO: Remember this needs to use Triangles.
	}+/

	/// Creates a Dome model with a radius of one.
	/// Params:
	/// 	Program = The program to use for rendering the Model. The VertexDeclaration will match the program.
	/// 	Resolution = Indicates the quality of the dome; the higher the resolution, the more vertices used.
	Model Dome(Effect Program, int Resolution) {
		enforce(Resolution >= 1, "Resolution must be positive.");
		float Radius = 1;
		int NumVertices = 1 + 4 * Resolution * Resolution;
		ModelVertex[] VertexData = new ModelVertex[NumVertices];
		float VertSweep = 45;
		float VertRadians = (90 - VertSweep) / (180 * PI);
		Radius /= cos(VertRadians);
		float ZAdjust = Radius * sin(VertRadians);
		float HeightScale = 1;
		Vector3f Origin = Vector3f(0, -0.3f, 0);
		VertexData[0].Position = Vector3f(0, 0, (Radius - ZAdjust) * HeightScale) + Origin;
		float HorizSweep = 90.0f / Resolution;
		VertSweep /= Resolution;
		int Vertex = 1;
		for(int i = 0; i < Resolution; i++) {
			Vector3f Point = Vector3f(0, 0, Radius);
			Matrix4f Rotation = Quaternion.FromYawPitchRoll(0, VertSweep * (i + 1), 0).ToMatrix();
		}
		throw new Exception("Not yet supported.");
	}
}

struct ModelVertex {
	Vector3f Position;
	Vector2f TexCoords;
}