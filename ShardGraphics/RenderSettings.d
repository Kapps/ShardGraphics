module ShardGraphics.RenderSettings;
private import std.variant;


enum RenderQuality {
	VeryLow = 0,
	Low = 1,
	Medium = 2,
	High = 3,
	VeryHigh = 4
}

/// Provides information on how to render a scene.
class RenderSettings  {

public:
	/// Initializes a new instance of the RenderSettings object.
	this() {
		
	}

	/// Gets or sets the render quality.
	@property RenderQuality Quality() const {
		return _Quality;
	}

	/// Ditto
	@property void Quality(RenderQuality Quality) {
		_Quality = Quality;
	}

	/// Gets the setting with the given key, as type T.
	void Get(T)(string Key) {	
		return _AdditionalSettings[Key].get!T;
	}
	
	/// Sets the setting with the given key to the specified value.
	void Set(T)(string Key, T Value) {
		_AdditionalSettings[Key] = Variant(Value);
	}	
	
private:
	Variant[string] _AdditionalSettings;
	RenderQuality _Quality;
}