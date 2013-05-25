module ShardGraphics.GraphicsErrorHandler;
public import gl;
private import ShardTools.Logger;
private import std.conv;

/// A helper class for checking for graphics errors.
static class GraphicsErrorHandler {

public:

	/// A helper method to call CheckErrors only in Debug mode.
	/// Note that it is possible this method may not be inlined if called from an external library or module.
	static void AssertErrors(in char[] FileName = __FILE__, int LineNumber = __LINE__) {
		debug CheckErrors(FileName, LineNumber);		
	}
	
	/// Queries OpenGL to see if any errors have occurred, logging an error and throwing an exception if they have.	
	static void CheckErrors(in char[] FileName = __FILE__, int LineNumber = __LINE__) {		
		GLenum Error = glGetError();
		if(Error == GL_NO_ERROR)
			return;		
		string LoggedMessage = ("GraphicsDevice CheckErrors failed in " ~ FileName ~ "(" ~ to!string(LineNumber) ~ "). "
			~ "Error code: " ~ to!string(Error) ~ ". Details: \'" ~ GetErrorDescription(Error) ~ "\'.").idup;
		Logger.Default.LogMessage("errors", LoggedMessage);		
		throw new Exception("GraphicsDevice CheckErrors failed. Details: \'" ~ GetErrorDescription(Error) ~ "\'.", FileName.idup, LineNumber);
	}

	/// Gets a description for the specified error.
	/// Params:
	///		Error = The error to get a description for.
	static string GetErrorDescription(GLenum Error) {
		switch(Error) {
			case GL_INVALID_ENUM:
				return "Passed in an enum that the function could not handle.";
			case GL_INVALID_VALUE:
				return "An invalid value was passed into a GL function.";
			case GL_INVALID_OPERATION:
				return "The function was invalid due to the state of the context.";
			/+case GL_STACK_OVERFLOW:
				return "A stack push caused an overflow.";
			case GL_STACK_UNDERFLOW:
				return "A stack pop caused an underflow.";+/
			case GL_OUT_OF_MEMORY:
				return "There was insufficient memory to handle the operation.";
			/*case GL_TABLE_TOO_LARGE:
				return "The graphics imaging table was too large.";
			case GL_INVALID_FRAMEBUFFER_OPERATION:
				return "An invalid framebuffer operation occurred.";*/
			case GL_NO_ERROR:
				return "";
			default:
				return "An unknown error occurred.";
		}
	}

private:
}