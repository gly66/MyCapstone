using UnityEngine;

public class SnowTrailAccumulator : MonoBehaviour
{
    public Material accumulationMaterial; // Material for blending the trails
    public Material snowMaterial; // Material for the snow shader

    public RenderTexture trailTexture; // RenderTexture to store the current heightmap
    public RenderTexture tempTexture; // Temporary RenderTexture for accumulation

    void Start()
    {

    }

    void Update()
    {


        // Accumulate the trail into the current heightmap
        AccumulateTrail();
        snowMaterial.SetTexture("_TrailMap", trailTexture);

        //rendering happens after update
    }

    void AccumulateTrail()
    {
        // Use the temporary texture to store the blending result
        Graphics.Blit(trailTexture, tempTexture, accumulationMaterial);

        // Write the blending result back to the trail texture
        Graphics.Blit(tempTexture, trailTexture);
    }

}
