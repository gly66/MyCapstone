using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class SineWaveController : MonoBehaviour
{
    public Material sineWaveMaterial; // Material
    public Slider amplitudeSlider;    // Amplitude
    public Slider offsetSlider;       // Offset
    public Toggle modeToggle;         
    public TextMeshProUGUI amplitudeValueText;   
    public TextMeshProUGUI offsetValueText;      
    public TextMeshProUGUI deformationModeText;  // Parabola or Sine

    void Start()
    {
        // init ui
        amplitudeSlider.onValueChanged.AddListener(OnAmplitudeChanged);
        offsetSlider.onValueChanged.AddListener(OnOffsetChanged);
        modeToggle.onValueChanged.AddListener(OnModeChanged);

       
        OnAmplitudeChanged(amplitudeSlider.value);
        OnOffsetChanged(offsetSlider.value);
        OnModeChanged(modeToggle.isOn);
    }

    void OnAmplitudeChanged(float value)
    {
        if (sineWaveMaterial)
        {
            sineWaveMaterial.SetFloat("_Amplitude", value);
            amplitudeValueText.text = $"Amplitude (a): {value:F2}";
        }
    }

    void OnOffsetChanged(float value)
    {
        if (sineWaveMaterial)
        {
            sineWaveMaterial.SetFloat("_Offset", value);
            offsetValueText.text = $"Offset (b): {value:F2}";
        }
    }
    void OnModeChanged(bool isSineMode)
    {
        if (sineWaveMaterial)
        {
            sineWaveMaterial.SetFloat("_Mode", isSineMode ? 1.0f : 0.0f); // Set deformation mode
            deformationModeText.text = $"Mode: {(isSineMode ? "Sine" : "Parabola")}"; // update mode
        }
    }
}
