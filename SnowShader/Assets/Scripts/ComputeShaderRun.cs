using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

public class ComputeShaderRun : MonoBehaviour
{
    public ComputeShader computeShader;
    public Material snowMaterial;
    public RenderTexture currentHeightMap; 
    public RenderTexture accumulatedHeightMap;
    // Start is called before the first frame update
    void Start()
    {

        accumulatedHeightMap = new RenderTexture(1024, 1024, 0,RenderTextureFormat.RFloat);
        accumulatedHeightMap.enableRandomWrite = true;
        accumulatedHeightMap.Create();



    }

    // Update is called once per frame
    void Update()
    {
        int kernelHandle = computeShader.FindKernel("HeightMapCompute");
        computeShader.SetTexture(kernelHandle, "currentHeightMap", currentHeightMap);
        computeShader.SetTexture(kernelHandle, "accumulatedHeightMap", accumulatedHeightMap);
        computeShader.Dispatch(kernelHandle, currentHeightMap.width / 8, currentHeightMap.height / 8, 1);
        snowMaterial.SetTexture("_TrailMap", accumulatedHeightMap);
        //string filePath = Application.dataPath + "/HeightMap.png";
        //SaveToFile(accumulatedHeightMap, filePath);

    }

    Texture2D SaveToTexture2D(RenderTexture renderTexture)
    {
        // 创建一个 Texture2D
        Texture2D tex = new Texture2D(renderTexture.width, renderTexture.height, TextureFormat.RFloat, false);

        // 从 RenderTexture 读取像素数据
        RenderTexture.active = renderTexture;
        tex.ReadPixels(new Rect(0, 0, renderTexture.width, renderTexture.height), 0, 0);
        tex.Apply();
        RenderTexture.active = null;

        return tex;
    }

    void SaveToFile(RenderTexture renderTexture, string filePath)
    {
        Texture2D tex = SaveToTexture2D(renderTexture);

        // 将 Texture2D 保存为 PNG 文件
        byte[] data = tex.EncodeToPNG();
        System.IO.File.WriteAllBytes(filePath, data);

        Debug.Log("Saved to: " + filePath);
    }
}
