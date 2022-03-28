#define BUFFER_SIZE 256

#include "GL/glew.h"
#include "glfw3.h"

#include <iostream>
#include <string>
#include <fstream>

bool LoadSourceCode(const std::string& filename, std::string& outSource)
{
	std::ifstream file(filename);

	if (!file.is_open())
		return false;

	char Buffer[BUFFER_SIZE] = { 0 };

	while (file.good())
	{
		file.getline(Buffer, BUFFER_SIZE);

		outSource += Buffer;
		outSource += "\n";

		memset(Buffer, 0, strlen(Buffer));

		if (file.eof() || file.fail())
			break;
	}

	file.close();

	return true;
}

void ShaderInfoLog(uint32_t shader)
{
	char Buffer[BUFFER_SIZE] = { 0 };

	int status;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &status);

	if (status == false)
	{
		glGetShaderInfoLog(shader, BUFFER_SIZE, nullptr, Buffer);
		std::cout << Buffer << std::endl;
	}
}

void ShaderProgramInfoLog(uint32_t shader, GLenum param)
{
	char Buffer[BUFFER_SIZE] = { 0 };

	int status;
	glGetProgramiv(shader, param, &status);

	if (status == false)
	{
		glGetProgramInfoLog(shader, BUFFER_SIZE, nullptr, Buffer);
		std::cout << Buffer << std::endl;
	}
}

int main(int argc, char** argv)
{
	if (!glfwInit())
		return -1;

	glfwWindowHint(GLFW_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_VERSION_MINOR, 5);
	GLFWwindow* window = glfwCreateWindow(1920, 1080, "ray-casting", nullptr, nullptr);

	if (window == nullptr)
		return -2;

	glfwMakeContextCurrent(window);

	if (glewInit() != GLEW_OK)
		return -3;

	float vertexData[] = {
		-1.0f, -1.0f,
		-1.0f,  1.0f,
		 1.0f, -1.0f,
		 1.0f,  1.0f
	};

	uint32_t indecies[] = { 0, 1, 2, 2, 1, 3 };

	uint32_t vertexBuffer;
	glCreateBuffers(1, &vertexBuffer);
	glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
	glBufferData(GL_ARRAY_BUFFER, sizeof(vertexData), vertexData, GL_STATIC_DRAW);

	uint32_t indexBuffer;
	glCreateBuffers(1, &indexBuffer);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(indecies), indecies, GL_STATIC_DRAW);

	uint32_t vertexArray;
	glCreateVertexArrays(1, &vertexArray);
	glBindVertexArray(vertexArray);
	glVertexAttribPointer(0, 2, GL_FLOAT, false, 2 * sizeof(float), nullptr);
	glEnableVertexAttribArray(0);

	uint32_t vertexShader = glCreateShader(GL_VERTEX_SHADER),
		fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);

	std::string vertexSource, fragmentSource;
	
	LoadSourceCode("src/glsl/scene.vert.glsl", vertexSource);
	LoadSourceCode("src/glsl/scene.frag.glsl", fragmentSource);

	const char* const cVertexSource = vertexSource.c_str();
	const char* const cFragmentSource = fragmentSource.c_str();

	glShaderSource(vertexShader, 1, &cVertexSource, nullptr);
	glShaderSource(fragmentShader, 1, &cFragmentSource, nullptr);

	glCompileShader(vertexShader);
	glCompileShader(fragmentShader);

	ShaderInfoLog(vertexShader); 
	ShaderInfoLog(fragmentShader);

	uint32_t shaderProgram = glCreateProgram();
	glAttachShader(shaderProgram, vertexShader);
	glAttachShader(shaderProgram, fragmentShader);

	glLinkProgram(shaderProgram);
	glValidateProgram(shaderProgram);

	ShaderProgramInfoLog(shaderProgram, GL_LINK_STATUS);
	ShaderProgramInfoLog(shaderProgram, GL_VALIDATE_STATUS);

	uint32_t uniformTime = glGetUniformLocation(shaderProgram, "u_Time");

	while (!glfwWindowShouldClose(window))
	{
		glClear(GL_COLOR_BUFFER_BIT);
		
		glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
		glUseProgram(shaderProgram);

		glDrawElements(GL_TRIANGLES,
			sizeof(indecies) / sizeof(indecies[0]), 
			GL_UNSIGNED_INT, 
			nullptr);

		glfwSwapBuffers(window);
		glfwPollEvents();
	}

	glfwDestroyWindow(window);
	glfwTerminate();

	return 0;
}