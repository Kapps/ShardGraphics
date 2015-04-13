	module ShardGraphics.GpuResource;

import ShardTools.ExceptionTools;
import derelict.opengl3.gl3;
import ShardTools.Udas;

mixin(MakeException("ResourceCreationException", "An exception failed while creating the underlying graphics resource."));

//@nogc:

/// Aliased to the API-dependent type of GPU resources.
alias ResourceID = GLuint;

/// Represents a mixin template for a refrence-counted resource with a GPU ID that is
/// automatically freed once the number of references reaches 0.
/// All resources sharing the same GpuResource share the same GPU ID, therefore may all
/// be updated with a single ID assignment for reloading a resource.
/// Note that resources are not created through constructors, but rather through the $(D create) factory method
/// to allow for parameterless constructors.
/// Extensions:
/// 	The following extension points exist for implementing a resource.
/// 	destroyResource(id): Required method to destroy a resource.
/// 	dispose():			 Called when a resource is destroyed with no remaining references to it.
/// 	onResourceChanged(): Called when a new resource ID is assigned.
mixin template GpuResource() {
	import std.typecons;
	import core.atomic;
	import std.c.stdlib;
	import ShardTools.Udas;
	import core.atomic;
	import core.stdc.stdlib;
	import ShardTools.Logger;

	/// Copy constructor to manage reference counts.
	this(this) {
		if(payload)
			atomicOp!"+="(payload.refCount, 1);
	}

	/+/// Wraps an initialized ResourceID in a GpuResource.
	this(ResourceID id) {
		this.id = id;
	}+/

	/// The default constructor is disabled, you must use the $(D create) factory method instead.
	@disable this();

	/+/// Dummy constructor for implementors to instantiate using the factory method.
	private this(bool dummyctor = false) { }+/

	//static assert(__traits(hasMember, typeof(this), "destroyResource"), "The destroyResource(id) member is required for implementing GpuResource.");
	static assert(is(typeof(this) == struct), "GpuResources must be structs.");
	static assert(is(typeof(destroyResource(ResourceID.init))), "GpuResource must implement a destroyResource(ResourceID) function.");

	/// Destructor to adjust reference counts and free the resource if need be.
	~this() {
		if(payload) {
			if(atomicOp!"-="(payload.refCount, 1) == 0) {
				logtf("Destroying %s with ID of %s.", typeid(this), id);
				destroyResource(id);
				payload.id = ResourceID.init;
				free(payload);
				static if(__traits(hasMember, typeof(this), "dispose"))
					dispose();
			}
		}
	}

	/// Gets the API-dependent ID of this resource.
	@property ResourceID id() {
		return payload.id;
	}
	 
	/// Sets the ID of this resource.
	/// If an existing ID is set, that ID is replaced for all shared resources and the reference count is not altered.
	/// The old resource is freed.
	@property protected void id(ResourceID val) {
		debug {
			if(payload && val == payload.id)
				logwf("Assigning same ID (%s) to %s. This is wasteful and results in additional allocations.", val, typeid(this));
		}
		if(payload) {
			destroyResource(id);
			logtf("Changing ID of %s from %s to %s.", typeid(this), id, val);
			payload.id = val;
		} else {
			payload = cast(Payload*)malloc(Payload.sizeof);
			payload.refCount = 1;
			payload.id = val;
			logtf("Initialized %s with ID of %s.", typeid(this), id);
		}

		static if(__traits(hasMember, typeof(this), "onResourceChanged"))
			onResourceChanged();
	}

	/// Gets the number of active references to this resource.
	/// If there is no active resource, returns 0.
	@property size_t refCount() {
		return payload is null ? 0 : payload.refCount;
	}


private:
	Payload* payload;

	shared static struct Payload {
		ResourceID id;
		size_t refCount;
	}
}

version(unittest) size_t numFreed;
version(unittest) import ShardTools.Udas;

@name("GpuResource Refcount Tests")
unittest {
	struct GpuTest {
		mixin GpuResource;
		this(ResourceID id) {
			this.id = id;
		}
		void destroyResource(ResourceID id) {
			numFreed++;
		}
	}
	{
		auto res = GpuTest(3);
		assert(res.id == 3);
		assert(res.refCount == 1);
		auto res2 = res;
		assert(res.payload is res2.payload);
		assert(res.refCount == 2);
		assert(numFreed == 0);
	}
	assert(numFreed == 1);
	
	{
		GLuint b = 4;
		GLuint c = 5;
		auto res = GpuTest(b);
		assert(res.refCount == 1);
		assert(res.id == b);
		auto res2 = res;
		assert(res2.id == b && res2.refCount == res.refCount && res2.refCount == 2);
		assert(numFreed == 1);
		res.id = c;
		assert(numFreed == 2);
		assert(res2.id == c && res2.refCount == res.refCount && res2.refCount == 2);
	}
	assert(numFreed == 3);
}

@name("GpuResource Struct Tests")
unittest {
	static size_t numChanges = 0;
	static size_t numDestroyed = 0;
	static struct Foo {
		int a;
		mixin GpuResource;
		this(int a) {
			this.a = a;
		}
		static auto create() {
			// Workaround for scope bug...
			return typeof(this)(3);
		}
		void onResourceChanged() {
			numChanges++;
		}
		void destroyResource(ResourceID id) {
			numDestroyed++;
		}
	}
	{
		auto f = Foo.create();
		assert(f.refCount == 0);
		f.id = 3;
		assert(f.refCount == 1);
		assert(numChanges == 1);
		assert(numDestroyed == 0);
		f.id = 2;
		assert(numChanges == 2);
		assert(numDestroyed == 1);
	}
	assert(numChanges == 2);
	assert(numDestroyed == 2);
}