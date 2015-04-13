module ShardGraphics.Tester;
import derelict.glfw3.glfw3;
import derelict.opengl3.gl3;
import ShardGraphics.Window;
import ShardMath.Vector;
import core.thread;
import ShardGraphics.Display;
import std.stdio;
import ShardTools.Logger;
import ShardTools.ConsoleLogger;
import core.thread;
import std.datetime;
import ShardGraphics.GraphicsBuffer;
import ShardGraphics.VertexDeclaration;
import gl;

void main() {
	registerLogger(new ConsoleLogger());
	log("Added console logger.");
	DerelictGL3.load();
	log("Loaded OpenGL.");
	DerelictGLFW3.load();
	log("Loaded GLFW.");
	glfwInit();
	auto display = Display.primary;
	logf("Primary display is %s.", display);
	WindowHints hints;
	hints.borderless = false;
	hints.fullscreen = false;
	auto window = new Window("Test Window", Vector2i(640, 480), display, hints);
	log("Initialized GLFW.");
	auto ver = DerelictGL3.reload();
	logf("Reloaded OpenGL to version %s.", ver);
	auto vbuff = VertexBuffer(BufferModifyHint.infrequent, BufferAccessHint.writeOnly);
	auto ibuff = IndexBuffer(BufferModifyHint.infrequent, BufferAccessHint.writeOnly);
	auto vdata = [
		Vector3f(-1f, -1f, 0f),
		Vector3f(0f, -1f, 1f),
		Vector3f(1f, -1f, 0f),
		Vector3f(0, 1, 0)
	];
	vbuff.setData(vdata);
	int[] idata = [
		0, 3, 1,
		1, 3, 2,
		2, 3, 0,
		0, 1, 2
	];
	ibuff.setData(idata);
	auto lastChange = Clock.currTime();
	size_t numFrames = 0;
	auto vertDec = createDeclaration!Vector3f();
	writeln(vertDec);
	while(!glfwWindowShouldClose(window.handle)) {
		numFrames++;
		glfwPollEvents();
		GL.bindBuffer(GL_ARRAY_BUFFER, vbuff.id);
		log("1");
		/+GL.enableVertexAttribArray(0);
		GL.vertexAttribPointer(0, 3, GL_FLOAT, false, 0, null);
		GL.vertexArrayVertexBuffer(vertDec.id, 0, vbuff.id, 0, cast(int)Vector3f.sizeof);+/
		log("3");
		GL.vertexArrayAttribFormat(vertDec.id, 0, 3, GL_FLOAT, false, 0);
		GL.enableVertexAttribArray(vertDec.id);
		log("2");
		GL.bindBuffer(GL_ELEMENT_ARRAY_BUFFER, ibuff.id);
		log("4");
		GL.drawElements(GL_TRIANGLES, 1, GL_UNSIGNED_INT, null);
		"5".log;
		//glDrawArrays(GL_TRIANGLES, 0, 3);
		glfwSwapBuffers(window.handle);
		if(Clock.currTime() - lastChange > 1.seconds) {
			logf("FPS was %s.", numFrames);
			numFrames = 0;
			hints.borderless = !hints.borderless;
			//window.recreateWindow(display, hints);
			lastChange = Clock.currTime();
		}
	}
}