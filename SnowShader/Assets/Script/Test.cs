using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class Test : MonoBehaviour
{
    private Mesh mesh;
    private Vector3[] originalVertices;
    private Vector3[] modifiedVertices;

    void Start()
    {
        // 获取雪层的Mesh并标记为动态
        mesh = GetComponent<MeshFilter>().mesh;
        mesh.MarkDynamic();

        originalVertices = mesh.vertices;
        modifiedVertices = new Vector3[originalVertices.Length];
        originalVertices.CopyTo(modifiedVertices, 0); // 初始复制
    }

    void Update()
    {
        for (int i = 0; i < modifiedVertices.Length; i++)
        {
            modifiedVertices[i].y = -0.5f+i/100; // 修改顶点高度
        }

        mesh.vertices = modifiedVertices; // 更新Mesh
        mesh.RecalculateNormals(); // 重新计算法线

        // 打印第一个顶点以调试
        Debug.Log("Vertex 0 Position: " + modifiedVertices[0]);
    }
}
