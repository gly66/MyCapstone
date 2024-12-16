using System.IO;
using UnityEngine;

public class LoveHeightMap : MonoBehaviour
{
    [Header("Heightmap Settings")]
    public int width = 1024; // Width of the heightmap
    public int height = 1024; // Height of the heightmap
    public string fileName = "HeartHeightmap.png"; // Name of the output PNG file

    [Range(0.0f, 1.0f)] public float heartSize = 0.8f; // Size of the heart (scaling factor)
    [Range(0.0f, 1.0f)] public float pathThickness = 0.1f; // Thickness of the heart path (outline)

    private void Start()
    {
        // Generate the heightmap when the scene starts
        GenerateHeartHeightmap();
        Debug.Log("Heart Heightmap generated: " + fileName);
    }

    private void GenerateHeartHeightmap()
    {
        // Create a new texture
        Texture2D texture = new Texture2D(width, height, TextureFormat.RGB24, false);

        // Loop through every pixel to draw the heart path
        for (int y = 0; y < height; y++)
        {
            for (int x = 0; x < width; x++)
            {
                // Map pixel coordinates to the range [-1, 1]
                float u = (x / (float)width) * 2.0f - 1.0f;
                float v = (y / (float)height) * 2.0f - 1.0f;

                // Check if the pixel lies on the heart path
                bool isHeartPath = IsPointOnHeart(u, v, heartSize, pathThickness);
                texture.SetPixel(x, y, isHeartPath ? Color.red : Color.black);
            }
        }

        // Apply changes to the texture and save it as PNG
        texture.Apply();
        SaveTextureAsPNG(texture, fileName);
    }

    // Check if a given point (u, v) lies on the heart path
    private bool IsPointOnHeart(float u, float v, float size, float thickness)
    {
        // Heart equation: (x^2 + y^2 - 1)^3 - x^2 * y^3 <= 0
        float x = u / size;
        float y = v / size;

        // Calculate the heart equation
        float equation = Mathf.Pow(x * x + y * y - 1, 3) - x * x * y * y * y;

        // If the equation result is within the thickness range, it's part of the path
        return Mathf.Abs(equation) < thickness;
    }

    // Save the texture as a PNG file in the Assets folder
    private void SaveTextureAsPNG(Texture2D texture, string fileName)
    {
        byte[] bytes = texture.EncodeToPNG(); // Convert the texture to PNG format
        string path = Path.Combine(Application.dataPath, fileName); // Define the file path
        File.WriteAllBytes(path, bytes); // Write the PNG file to disk
    }
}
