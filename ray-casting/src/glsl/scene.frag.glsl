#version 450

out vec4 FragColor;

#define PRESCISION 0.000000000001
#define PI 3,1415926
#define N 3

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

struct Plane
{
	vec3 Origin;
	vec3 Normal;
	vec3 Color;
};

struct Material
{
	vec3 Color;
	float Specular;
	bool Reflective;
};

Sphere g_Spheres[N];
Material g_Materials[N];
Plane g_Plane;

uniform float u_ScreenX;
uniform float u_ScreenY;

bool IntersectSphere(in Camera camera, in Sphere sphere, in vec3 direction, out float t0, out float t1)
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

bool IntersectPlane(in Plane plane, in vec3 direction, in Camera camera, out float t)
{
	float denumerator = dot(plane.Normal, direction);

	if (denumerator > PRESCISION)
	{
		float numerator = plane.Normal.x * (plane.Origin.x - direction.x) +
						  plane.Normal.y * (plane.Origin.y - direction.y) +
						  plane.Normal.z * (plane.Origin.z - direction.z);

		t = numerator / denumerator;

		return true;
	}

	return false;
}

vec3 GetNormal(in Sphere sphere, in Camera camera, in float param, in vec3 direction)
{
	vec3 point = (camera.Position + param * direction);
	return normalize(point - sphere.Origin);
}

void DrawSphere(in int index, in Camera camera, in vec3 rayDirection, out vec4 color, out bool intersect)
{
	float t0, t1;

	if (IntersectSphere(camera, g_Spheres[index], rayDirection, t0, t1))
	{
		float t;
		
		if (t0 < t1)
			t = t0;
		else
			t = t1;

		vec3 normal = GetNormal(g_Spheres[index], camera, t, rayDirection);

		color = vec4(g_Materials[index].Color, 1.0) * (-dot(camera.Direction, normal));
		intersect = true;
	}
	else
	{	
		color = vec4(0.0, 0.0, 0.0, 1.0);
		intersect = false;
	}
}

void DrawPlane(in Plane plane, in Camera camera, in vec3 rayDirection, out vec4 color, out bool intersect)
{
	float t;

	if (IntersectPlane(plane, rayDirection, camera, t))
	{
		color = vec4(plane.Color, 1.0);
		intersect = true;
	}
	else
	{
		color = vec4(0.0, 0.0, 0.0, 1.0);
		intersect = false;
	}
}

void SetupScene(out Camera camera)
{
	for (int i = 0; i < N; i++)
	{
		g_Spheres[i].Radius = 3.0;
	}

	g_Spheres[0].Origin = vec3(-15.0, 0.0, -35.0);
	g_Spheres[1].Origin = vec3(0.0, 0.0, -35.0);
	g_Spheres[2].Origin = vec3(15.0, 0.0, -35.0);

	g_Materials[0].Color = vec3(1.0, 0.0, 0.0);
	g_Materials[1].Color = vec3(0.0, 1.0, 0.0);
	g_Materials[2].Color = vec3(0.0, 0.0, 1.0);

	g_Plane.Origin = vec3(0.0,  0.0, 0.0);
	g_Plane.Normal = vec3(0.0, -1.0, 0.0);
	g_Plane.Color  = vec3(0.49,0.5, 0.51);

	camera.Position = vec3(0.0, 0.0, 0.0);
	camera.Direction = vec3(0.0, 0.0, -1.0);
	camera.Fov = radians(90);
}

void DrawScene(in Camera camera, in vec3 rayDirection)
{
	vec4 color;
	vec4 colorPlane;
	bool intersectedPlane;
	bool intersect = false;	

	DrawPlane(g_Plane, camera, rayDirection, colorPlane, intersectedPlane);

	for (int i = 0; i < N; i++)
	{	
		intersect = false;	
		DrawSphere(i, camera, rayDirection, color, intersect);

		if (intersect)
		{
			break;
		}
	}
	
	if (intersect)
		FragColor = color;
	else if (intersectedPlane)
		FragColor = colorPlane;
	else
		FragColor = vec4(0.8,0.91,1.0,1.0);
}

void main()
{
	Camera mainCamera;
	SetupScene(mainCamera);
	
	vec2 resolution = vec2(1920.0, 1080.0);
	float aspectRation = resolution.x / resolution.y;
	vec2 uv = gl_FragCoord.xy / resolution.xy - 0.5;
	uv.x *= aspectRation;

	vec3 direction = normalize(vec3(uv, -1.0) - mainCamera.Position);
	DrawScene(mainCamera, direction);
}
