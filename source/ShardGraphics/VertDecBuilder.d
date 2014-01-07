module ShardGraphics.VertDecBuilder;
public import ShardGraphics.VertexDeclaration;
public import ShardGraphics.VertexElement;

/// A helper class for building vertex declarations. Not yet implemented.
@disable
struct VertDecBuilder  {
public:	
	void AppendElement(Type)(in char[] Name) {
		if(Element == null) {
			Elements = new VertexElement[0];
			Elements.capacity = 16;
		}
		GLenum Type;		
		Elements ~= Element;	
	}
private:
	VertexElement[] Elements;
	int TotalSize;
	int CurrentOffset;
}