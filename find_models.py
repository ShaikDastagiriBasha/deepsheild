import os
from huggingface_hub import hf_hub_download, HfApi

api = HfApi()

print("--- Searching yakhyo/uniface-weights ---")
files = api.list_repo_files("yakhyo/uniface-weights")
for f in files:
    if 'adaface' in f.lower() and f.endswith('.onnx'):
        print(f"Found AdaFace: {f}")

print("\n--- Searching ilaylow/PP_OCRv5_mobile_onnx ---")
try:
    files = api.list_repo_files("ilaylow/PP_OCRv5_mobile_onnx")
    for f in files:
        print(f"Found PP-OCRv5: {f}")
except Exception as e:
    print(e)
    
print("\n--- Searching monkt/paddleocr-onnx ---")
try:
    files = api.list_repo_files("monkt/paddleocr-onnx")
    for f in files:
        if 'v5' in f.lower() or 'v4' in f.lower():
            print(f"Found PaddleOCR: {f}")
except Exception as e:
    print(e)
