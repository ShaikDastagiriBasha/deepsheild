import os
import onnx
from huggingface_hub import hf_hub_download

models_dir = r"c:\Users\SK BASHA\deepshield\assets\models"
os.makedirs(models_dir, exist_ok=True)

downloads = [
    ("yakhyo/uniface-weights", "adaface_ir_18.onnx"),
    ("ilaylow/PP_OCRv5_mobile_onnx", "ppocrv5_det.onnx"),
    ("ilaylow/PP_OCRv5_mobile_onnx", "ppocrv5_rec.onnx")
]

for repo, filename in downloads:
    print(f"\n--- Downloading {filename} ---")
    local_path = hf_hub_download(repo_id=repo, filename=filename, local_dir=models_dir)
    print(f"Downloaded to {local_path}")
    
    try:
        model = onnx.load(local_path)
        print("Model loaded successfully!")
        
        print("--- Inputs ---")
        for input in model.graph.input:
            name = input.name
            type = input.type.tensor_type.elem_type
            shape = [dim.dim_value for dim in input.type.tensor_type.shape.dim]
            print(f"Name: {name}, Type: {type}, Shape: {shape}")
            
        print("--- Outputs ---")
        for output in model.graph.output:
            name = output.name
            type = output.type.tensor_type.elem_type
            shape = [dim.dim_value for dim in output.type.tensor_type.shape.dim]
            print(f"Name: {name}, Type: {type}, Shape: {shape}")
            
    except Exception as e:
        print(f"Error loading model: {e}")

# Download dictionary
print("\n--- Downloading PP-OCR dictionary ---")
import urllib.request
dict_url = "https://raw.githubusercontent.com/PaddlePaddle/PaddleOCR/main/ppocr/utils/ppocr_keys_v1.txt"
dict_path = os.path.join(models_dir, "ppocr_keys_v1.txt")
urllib.request.urlretrieve(dict_url, dict_path)
print(f"Dictionary downloaded to {dict_path}")
