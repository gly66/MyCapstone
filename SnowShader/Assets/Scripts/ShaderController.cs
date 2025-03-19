using UnityEngine;
using UnityEngine.UI;

public class ShaderController : MonoBehaviour
{
    public Material targetMaterial; 

    public Toggle useLowerLayerToggle;
    public Slider initialHeightSlider;
    public Slider displacementStrengthSlider;
    public Slider blurSizeSlider;
    public Slider distanceBlendSlider;
    public Slider tesselationEdgeLengthSlider;

    public Text initialHeightValueText;
    public Text displacementStrengthValueText;
    public Text blurSizeValueText;
    public Text distanceBlendValueText;
    public Text tesselationEdgeLengthValueText;


    void Start()
    {

        useLowerLayerToggle.isOn = targetMaterial.GetFloat("_UseLowerLayer") == 1;
        SetSliderValue(initialHeightSlider, initialHeightValueText, "_InitialHeight");
        SetSliderValue(displacementStrengthSlider, displacementStrengthValueText, "_DisplacementStrength");
        SetSliderValue(blurSizeSlider, blurSizeValueText, "_BlurSize");
        SetSliderValue(distanceBlendSlider, distanceBlendValueText, "_DistanceBlend");
        SetSliderValue(tesselationEdgeLengthSlider, tesselationEdgeLengthValueText, "_TesselationEdgeLength");


        useLowerLayerToggle.onValueChanged.AddListener(OnUseLowerLayerChanged);
        initialHeightSlider.onValueChanged.AddListener(value => OnSliderChanged(initialHeightValueText, "_InitialHeight", value));
        displacementStrengthSlider.onValueChanged.AddListener(value => OnSliderChanged(displacementStrengthValueText, "_DisplacementStrength", value));
        blurSizeSlider.onValueChanged.AddListener(value => OnSliderChanged(blurSizeValueText, "_BlurSize", value));
        distanceBlendSlider.onValueChanged.AddListener(value => OnSliderChanged(distanceBlendValueText, "_DistanceBlend", value));
        tesselationEdgeLengthSlider.onValueChanged.AddListener(value => OnSliderChanged(tesselationEdgeLengthValueText, "_TesselationEdgeLength", value));
    }

    void SetSliderValue(Slider slider, Text valueText, string shaderProperty)
    {
        float value = targetMaterial.GetFloat(shaderProperty);
        slider.value = value;
        valueText.text = value.ToString("F3"); // 保留两位小数
    }

    void OnUseLowerLayerChanged(bool value)
    {
        targetMaterial.SetFloat("_UseLowerLayer", value ? 1 : 0);
    }

    void OnSliderChanged(Text valueText, string shaderProperty, float value)
    {
        targetMaterial.SetFloat(shaderProperty, value);
        valueText.text = value.ToString("F3");
    }
}