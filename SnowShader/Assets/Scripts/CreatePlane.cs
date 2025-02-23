using UnityEngine;

[RequireComponent(typeof(MeshFilter), typeof(MeshRenderer))]
public class CreatePlane : MonoBehaviour
{
    public int resolution = 100; // Resolution£¬100x100 now
    public float size = 1f;     // Plane Size 10*10 now

    void Start()
    {
        GeneratePlane();
    }
    private void Update()
    {

    }
    void GeneratePlane()
    {
        Mesh mesh = new Mesh();
        GetComponent<MeshFilter>().mesh = mesh;

        // Create vertices and uvs
        Vector3[] vertices = new Vector3[(resolution + 1) * (resolution + 1)];
        Vector2[] uvs = new Vector2[vertices.Length];

        for (int i = 0; i <= resolution; i++)
        {
            for (int j = 0; j <= resolution; j++)
            {
                float x = (float)j / resolution;
                float y = (float)i / resolution;

                vertices[i * (resolution + 1) + j] = new Vector3(x * size - size / 2f, 0, y * size - size / 2f);
                uvs[i * (resolution + 1) + j] = new Vector2(x, y);
            }
        }

        // Creating a Triangular Index
        int[] triangles = new int[resolution * resolution * 6];
        int index = 0;

        for (int i = 0; i < resolution; i++)
        {
            for (int j = 0; j < resolution; j++)
            {
                int topLeft = i * (resolution + 1) + j;
                int topRight = topLeft + 1;
                int bottomLeft = topLeft + resolution + 1;
                int bottomRight = bottomLeft + 1;

                // The first triangle
                triangles[index++] = topLeft;
                triangles[index++] = bottomLeft;
                triangles[index++] = topRight;

                // The second triangle
                triangles[index++] = topRight;
                triangles[index++] = bottomLeft;
                triangles[index++] = bottomRight;
            }
        }

        // Apply Grid Data
        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.triangles = triangles;

        // Automatic calculation of normals to ensure proper illumination
        mesh.RecalculateNormals();
    }
}
