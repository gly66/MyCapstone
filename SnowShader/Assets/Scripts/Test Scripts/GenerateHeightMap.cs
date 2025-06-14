using UnityEngine;
using System.IO;

public class GenerateHeightMap : MonoBehaviour
{
    public int textureWidth = 1024;  // Width of the heightmap
    public int textureHeight = 1024; // Height of the heightmap
    public int pathWidth = 10;       // The width of the paths
    public string saveFileName = "GeneratedHeightMap.png";  // The filename for the saved PNG

    void Start()
    {
        // Create a blank black heightmap texture
        Texture2D heightMap = new Texture2D(textureWidth, textureHeight);
        GenerateMyHeightMap(heightMap);
        SaveTextureAsPNG(heightMap, saveFileName);
    }

    // Generate the heightmap with random red paths (red represents the path, black is background)
    void GenerateMyHeightMap(Texture2D texture)
    {
        // Initialize all pixels as black
        Color black = Color.black;
        Color red = Color.red;

        for (int y = 0; y < textureHeight; y++)
        {
            for (int x = 0; x < textureWidth; x++)
            {
                texture.SetPixel(x, y, black);
            }
        }

        // Randomly decide whether to generate 1 or 2 paths
        int pathCount = Random.Range(1, 3);
        for (int i = 0; i < pathCount; i++)
        {
            // Randomize the start and end points within the texture boundaries
            Vector2 startPoint = new Vector2(Random.Range(0, textureWidth), Random.Range(0, textureHeight / 4)); // Start in the top quarter
            Vector2 endPoint = new Vector2(Random.Range(0, textureWidth), Random.Range(textureHeight * 3 / 4, textureHeight)); // End in the bottom quarter
            DrawRandomPath(texture, startPoint, endPoint, red);
        }

        texture.Apply(); // Apply the pixel changes to the texture
    }

    // Draw a random path from startPoint to endPoint
    void DrawRandomPath(Texture2D texture, Vector2 startPoint, Vector2 endPoint, Color pathColor)
    {
        Vector2 currentPosition = startPoint;
        while ((int)currentPosition.y < endPoint.y)
        {
            // Draw the current point in the path
            DrawPathSegment(texture, currentPosition, pathColor);

            // Randomly move to the left, right, or straight down
            int direction = Random.Range(-1, 2); // -1: left, 0: straight down, 1: right

            // Update the path position, ensuring it stays within texture bounds
            currentPosition.x = Mathf.Clamp(currentPosition.x + direction, 0, textureWidth - 1);
            currentPosition.y++;

            // Introduce some variation in the direction change
            if (Random.value > 0.9f) // 10% chance of slightly larger movement
            {
                currentPosition.x = Mathf.Clamp(currentPosition.x + Random.Range(-1, 2), 0, textureWidth - 1);
            }
        }
    }

    // Draw a segment of the path with a defined width
    void DrawPathSegment(Texture2D texture, Vector2 position, Color pathColor)
    {
        for (int y = (int)position.y - pathWidth / 2; y <= (int)position.y + pathWidth / 2; y++)
        {
            for (int x = (int)position.x - pathWidth / 2; x <= (int)position.x + pathWidth / 2; x++)
            {
                // Ensure the path segment is within the texture boundaries
                if (x >= 0 && x < textureWidth && y >= 0 && y < textureHeight)
                {
                    texture.SetPixel(x, y, pathColor);
                }
            }
        }
    }

    // Save the texture as a PNG file
    void SaveTextureAsPNG(Texture2D texture, string fileName)
    {
        byte[] bytes = texture.EncodeToPNG();
        string filePath = Path.Combine(Application.dataPath, fileName);
        File.WriteAllBytes(filePath, bytes);
        Debug.Log("Height map saved to: " + filePath);
    }
}
