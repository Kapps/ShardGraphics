module ShardGraphics.ShaderParameterCollection;
public import ShardGraphics.ShaderAttribute;
private import ShardTools.Map;
private import ShardGraphics.Shader;
private import ShardTools.ExceptionTools;

mixin(MakeException("AttributeNotFoundException"));

/// Represents a collection of parameters inside a shader.
class ShaderParameterCollection : Map!(string, ShaderAttribute) {

public:
	/// Initializes a new instance of the ShaderParameterCollection object.
	this(ShaderAttribute[] Attributes) {
		for(size_t i = 0; i < Attributes.length; i++)
			Set(Attributes[i].Name, Attributes[i]);		
	}
	
	/+ /// Creates an array of ShaderAttributes given the name of each attribute.
	/// Params:
	/// 	... = An array of strings representing the names of the attributes.
	ShaderAttribute[] GetAttributesFromNames(...) {
		ShaderAttribute[] Result = new ShaderAttribute[4];
		Result.length = 0;
		size_t Length = _arguments.length;
		string* ptr = cast(string*)_argptr;
		for(size_t i = 0; i < Length; i++) {
			debug assert(_arguments[i] == typeid(string));
			string Current = *(ptr + i);
			ShaderAttribute Attrib = super.Get(Current, null);
			if(Attrib is null)
				throw new AttributeNotFoundException("No attribute with the name of " ~ Current ~ " was found in the collection.");
			Result ~= Attrib;
		}
		return null;
	}+/

	package void Rebind(ShaderAttribute[] Attributes) {
		this.Clear();
		for(int i = 0; i < Attributes.length; i++)
			Set(Attributes[i].Name, Attributes[i]);
	}

private:	

}