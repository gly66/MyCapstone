using UnityEngine;

public class SnowSplashController : MonoBehaviour
{
    public ParticleSystem snowSplashPrefab; // 飞溅效果的粒子系统 Prefab
    public float splashIntensity = 10f; // 飞溅强度
    public float maxSpeed = 10f; // 小球的最大速度

    private ParticleSystem snowSplashInstance;
    private Rigidbody rb;

    private void Start()
    {
        rb = GetComponent<Rigidbody>();

        // 实例化飞溅效果
        snowSplashInstance = Instantiate(snowSplashPrefab, transform.position, Quaternion.identity);
        snowSplashInstance.transform.parent = transform; // 将飞溅效果绑定到小球
    }

    private void Update()
    {
        if (snowSplashInstance != null)
        {
            // 根据小球的速度调整飞溅强度
            float speed = rb.velocity.magnitude;
            float intensity = Mathf.Clamp01(speed / maxSpeed) * splashIntensity;

            var emission = snowSplashInstance.emission;
            emission.rateOverTime = intensity; // 动态设置发射数量

            // 根据小球的速度调整飞溅范围
            var shape = snowSplashInstance.shape;
            shape.radius = Mathf.Clamp(speed / maxSpeed, 0.1f, 1f); // 动态设置飞溅范围
        }
    }

    private void OnDestroy()
    {
        // 销毁飞溅效果实例
        if (snowSplashInstance != null)
        {
            Destroy(snowSplashInstance.gameObject);
        }
    }
}