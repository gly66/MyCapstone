using System.IO;
using UnityEngine;

public class LoveHeightMap : MonoBehaviour
{
    [Header("Heightmap Settings")]
    public int width = 1024;
    public int height = 1024;
    public string fileName = "RandomHeightmap.png";

    [Range(1f, 100f)] public float scale = 20f; // 控制噪声的频率
    public Vector2 offset; // 噪声偏移

    private void Start()
    {
        offset = new Vector2(Random.Range(0f, 1000f), Random.Range(0f, 1000f));
        GenerateRandomHeightmap();
        Debug.Log("Random Heightmap generated: " + fileName);
    }

    private void GenerateRandomHeightmap()
    {
        Texture2D texture = new Texture2D(width, height, TextureFormat.RGB24, false);

        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                float u = (float)x / width * scale + offset.x;
                float v = (float)y / height * scale + offset.y;

                float noise = Mathf.PerlinNoise(u, v);
                texture.SetPixel(x, y, new Color(noise, noise, noise)); // 灰度图
            }
        }

        texture.Apply();
        SaveTextureAsPNG(texture, fileName);
    }

    private void SaveTextureAsPNG(Texture2D texture, string fileName)
    {
        byte[] bytes = texture.EncodeToPNG();
        string path = Path.Combine(Application.dataPath, fileName);
        File.WriteAllBytes(path, bytes);
    }
}
