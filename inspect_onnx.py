# pyrefly: ignore [missing-import]
import onnx

model_path = r"c:\Users\SK BASHA\deepshield\assets\models\w600k_mbf.onnx"
try:
    model = onnx.load(model_path)
    print("Model loaded successfully!")
    
    print("\n--- Inputs ---")
    for input in model.graph.input:
        name = input.name
        type = input.type.tensor_type.elem_type
        shape = [dim.dim_value for dim in input.type.tensor_type.shape.dim]
        print(f"Name: {name}, Type: {type}, Shape: {shape}")
        
    print("\n--- Outputs ---")
    for output in model.graph.output:
        name = output.name
        type = output.type.tensor_type.elem_type
        shape = [dim.dim_value for dim in output.type.tensor_type.shape.dim]
        print(f"Name: {name}, Type: {type}, Shape: {shape}")
        
except Exception as e:
    print(f"Error loading model: {e}")
