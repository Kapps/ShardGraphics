module gl;
public import derelict.opengl3.gl3;
public import derelict.glfw3.glfw3;

import std.string;
import ShardTools.Logger;
import std.algorithm;
import std.conv;
import ShardTools.ExceptionTools;
import std.traits;
import std.array;
import std.typetuple;

mixin(MakeException("GlException", "An error occurred during an OpenGL call."));

/// Provides a static struct with opDispatch for easier handling of OpenGL calls.
/// Calls can optionally be logged by using --version=debugGL and all results will be checked with glGetError.
/// Any errors will result in an exception being thrown, with the message containing the call and the arguments.
/// A call that attempts to invoke an extension that is not loaded will be detected and an exception thrown.
static struct GL {
	debug {
		/// Implements opDispatch to implement checked GL calls.
		static auto opDispatch(string method, string file = __FILE__, int line = __LINE__, T...)(T args) {
			auto dg = mixin("gl" ~ method[0].text.toUpper ~ method[1..$]);
			if(!dg)
				throw new GlException("Attempted to invoke extension 'gl" ~ method ~ "' which is not supported.");
			static if(is(ReturnType!dg == void)) {
				dg(args);
				verifySuccess!(file, line)(method, args);
			} else {
				auto result = dg(args);
				verifySuccess!(file, line)(method, args);
				return result;
			}
		}
		
		private static void verifySuccess(string file = __FILE__, int line = __LINE__, T...)(string action, T args) {
			auto error = glGetError();
			if(error != GL_NO_ERROR) {
				// TODO: Prevent allocations in the below.
				string argText;
				foreach(i, arg; args)
					argText ~= arg.text.replace("\\", "\\\\") ~ ", ";
				if(argText.length)
					argText = argText[0..$-2];
				logef("GL call for %s from %s:%s failed with error code %s (%s). Args: [%s]", action, file, line, error, error.errToString, argText);
				throw new GlException("OpenGL call failed. See error log for more details.", file, line);
			}
		}
	} else {
		/// Implements opDispatch to implement unchecked GL calls in release mode.
		static auto opDispatch(string method, T...)(T args) {
			auto dg = mixin("gl" ~ method[0].text.toUpper ~ method[1..$]);
			static if(is(ReturnType!dg == void))
				dg(args);
			else
				return dg(args);
		}
	}
}

/// Returns a string representation of this error.
string errToString(GLenum err) {
	alias ErrTuple = TypeTuple!(
		GL_INVALID_ENUM, GL_INVALID_VALUE, GL_INVALID_OPERATION,
		GL_INVALID_FRAMEBUFFER_OPERATION, GL_OUT_OF_MEMORY
	);
	foreach(i, val; ErrTuple) {
		if(val == err)
			return __traits(identifier, ErrTuple[i]);
	}
	return "Unknown Error";
}