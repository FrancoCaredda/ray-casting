#version 450

out vec4 FragColor;

#define PRESCISION 0.000000000001
#define PI 3,1415926

uniform float u_Time;

struct Camera
{
	vec3 Direction;
	vec3 Position;
	float Fov;
};

struct Sphere
{
	vec3 Origin;
	float Radius;
};

struct DirectionalLight
{
	vec3 Direction;
	vec3 Color;
};

bool Intersect(in Camera camera, in Sphere sphere, in vec3 direction, out float t0, out float t1)
{
	float a = direction.x * direction.x + direction.y * direction.y + direction.z * direction.z;
	float b = 2 * camera.Position.x * direction.x + 2 * camera.Position.y * direction.y + 2 * camera.Position.z * direction.z 
			  - 2 * sphere.Origin.x * direction.x - 2 * sphere.Origin.y * direction.y - 2 * sphere.Origin.z * direction.z;
	float c = direction.x * direction.x + sphere.Origin.x * sphere.Origin.x + 
			  direction.y * direction.y + sphere.Origin.y * sphere.Origin.y + 
			  direction.z * direction.z + sphere.Origin.z * sphere.Origin.z -
			  sphere.Radius * sphere.Radius;

	float D = b * b - 4 * a * c;

	if (D > 0)
	{
		t0 = (-b + sqrt(D)) / (2 * a);
		t1 = (-b - sqrt(D)) / (2 * a);
	}
	else if (abs(D) < PRESCISION)
	{
		t0 = t1 = -b / (2*a);
	}
	else
	{
		return false;
	}

	return true;
}

vec3 GetNormal(in Sphere sphere, in float param, in vec3 direction)
{
	return sphere.Origin + param * direction;
}

void main()
{
	Camera camera;
	camera.Direction = vec3(0.0, 0.0, -1.0);
	camera.Position = vec3(0.0, 0.0, 0.0);
	camera.Fov = radians(90.0);

	DirectionalLight light;
	light.Direction = normalize(vec3(1.0, 1.0, -1.0));
	light.Color = vec3(1.0, 1.0, 1.0);

	vec2 resolution = vec2(1920.0, 1080.0);
	float aspectRation = resolution.x / resolution.y;
	vec2 uv = vec2((2 * ((gl_FragCoord.x + 0.5) / resolution.x) - 1) * aspectRation * tan(camera.Fov / 2.0), 
		(1 - 2 * ((gl_FragCoord.y + 0.5) / resolution.y)) * tan(camera.Fov / 2.0));


	vec3 direction = normalize(vec3(uv, -1.0) - camera.Position);
	Sphere sphere;
	sphere.Origin = vec3(0.0, 0.0, -10.0);
	sphere.Radius = 5.0;

	float t0, t1;

	if (Intersect(camera, sphere, direction, t0, t1))
	{
		float k = (t0 < t1) ? t0 : t1;

		vec3 point = camera.Position + k * direction;
		vec3 normal = normalize(point - sphere.Origin);

		FragColor = vec4(1.0, 0.0, 1.0, 1.0) * (-dot(normal, light.Direction)) * vec4(light.Color, 1.0);
	}
	else
	{
		FragColor = vec4(0.0, 0.0, 0.0, 1.0);
	}
}
