using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class CameraDepth : MonoBehaviour
{
    public Camera orthoCam;
    // Start is called before the first frame update
    void Start()
    {

        // 绑定 RenderTexture 到相机
        orthoCam.depthTextureMode = DepthTextureMode.Depth;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
