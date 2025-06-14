using UnityEngine;

public class CameraFollow : MonoBehaviour
{
    public Transform ball;    // 小球
    public float distance = 5f;  // 相机到小球的固定距离
    public float height = 2f;   // 相机相对小球的高度
    public float smoothSpeed = 10f; // 平滑移动速度

    void LateUpdate()
    {
        if (ball == null) return;

        // 计算相机在小球后方的目标位置
        Vector3 direction = (transform.position - ball.position).normalized; // 计算相机到小球的方向
        Vector3 targetPosition = ball.position + direction * distance + Vector3.up * height;

        // 平滑移动相机到目标位置
        transform.position = Vector3.Lerp(transform.position, targetPosition, smoothSpeed * Time.deltaTime);

        // 让相机始终朝向小球
        transform.LookAt(ball.position);
    }
}
