using UnityEngine;

public class RobotTestScriptFree : MonoBehaviour
{

    private Animator anim;
    private float jumpTimer = 0;
    private float moveSpeed = 2.0f; // 走路速度
    private float runSpeed = 4.0f;  // 跑步速度

    void Start()
    {
        anim = this.gameObject.GetComponent<Animator>();
    }

    void Update()
    {
        float speed = 0f; // 角色的实际移动速度

        if (Input.GetKey("2"))
        {
            anim.SetInteger("Speed", 2);
            speed = runSpeed;  // 设置为跑步速度
        }
        else if (Input.GetKey("1"))
        {
            anim.SetInteger("Speed", 1);
            speed = moveSpeed; // 设置为走路速度
        }
        else
        {
            anim.SetInteger("Speed", 0);
        }

        // 控制角色移动
        transform.Translate(Vector3.forward * speed * Time.deltaTime);

        if (Input.GetKey("3"))
        {
            jumpTimer = 1;
            anim.SetBool("Jumping", true);
        }

        if (jumpTimer > 0.5)
        {
            jumpTimer -= Time.deltaTime;
        }
        else if (anim.GetBool("Jumping") == true)
        {
            anim.SetBool("Jumping", false);
        }
    }
}
