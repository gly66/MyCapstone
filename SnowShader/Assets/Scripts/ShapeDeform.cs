using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class ShapeDeform : MonoBehaviour
{
    public LayerMask deformationLayer;  // Layer to detect, e.g., only the object layer
    public float groundOffset = 1f;   // Offset between the snow surface and ground

    private Mesh mesh;
    private Vector3[] originalVertices;
    private Vector3[] modifiedVertices;

    void Start()
    {
        // Get the Mesh of the snow layer and mark it as dynamic
        mesh = GetComponent<MeshFilter>().mesh;
        mesh.MarkDynamic();

        originalVertices = mesh.vertices;
        modifiedVertices = new Vector3[originalVertices.Length];
        originalVertices.CopyTo(modifiedVertices, 0); // Initial copy
    }

    void Update()
    {
        for (int i = 0; i < modifiedVertices.Length; i++)
        {
            // Convert the local vertex position of the snow surface to world coordinates
            Vector3 snowVertexWorldPos = transform.TransformPoint(originalVertices[i]);
            // Calculate the corresponding ground position
            Vector3 groundPosition = new Vector3(snowVertexWorldPos.x, snowVertexWorldPos.y - groundOffset, snowVertexWorldPos.z);

            // Cast a ray upwards from the ground position
            Ray ray = new Ray(groundPosition, Vector3.up);
            if (Physics.Raycast(ray, out RaycastHit hit, groundOffset * 10, deformationLayer))
            {
                Debug.Log("Hit!  : " + modifiedVertices[i]);
                // If the ray hits an object, adjust the vertex y-coordinate to match the object's surface height
                float targetHeight = hit.point.y;
                modifiedVertices[i].y = transform.InverseTransformPoint(new Vector3(snowVertexWorldPos.x, targetHeight, snowVertexWorldPos.z)).y;
            }
        }

        // Update mesh vertices and recalculate normals
        mesh.vertices = modifiedVertices;
        mesh.RecalculateNormals();
        // Debug.Log("Vertex 0 Position: " + modifiedVertices[0]);
    }
}
