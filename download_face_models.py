import os
import urllib.request

base_url = "https://raw.githubusercontent.com/justadudewhohacks/face-api.js/master/weights/"
models_dir = os.path.join("web", "models")
os.makedirs(models_dir, exist_ok=True)

files = [
    "tiny_face_detector_model-weights_manifest.json",
    "tiny_face_detector_model-shard1",
    "face_landmark_68_model-weights_manifest.json",
    "face_landmark_68_model-shard1",
    "face_recognition_model-weights_manifest.json",
    "face_recognition_model-shard1",
    "face_recognition_model-shard2",
    "face_expression_model-weights_manifest.json",
    "face_expression_model-shard1",
]

for file in files:
    url = base_url + file
    filepath = os.path.join(models_dir, file)
    if not os.path.exists(filepath):
        print(f"Downloading {file}...")
        try:
            urllib.request.urlretrieve(url, filepath)
            print(f"Downloaded {file}")
        except Exception as e:
            print(f"Error downloading {file}: {e}")
    else:
        print(f"{file} already exists.")
print("Done.")
