# Welcome to Cloud Functions for Firebase for Python!
# To get started, simply uncomment the below code or create your own.
# Deploy with `firebase deploy`

from firebase_functions import https_fn
from firebase_admin import initialize_app
import json

initialize_app()

@https_fn.on_request()
def process_ocr(req: https_fn.Request) -> https_fn.Response:
    """
    Receives a PAN card image and returns extracted details via OCR.
    For demonstration, this is a mock implementation.
    """
    if req.method != "POST":
        return https_fn.Response("Method not allowed", status=405)
    
    # In a real scenario, we would parse req.data (image bytes) and use Google Cloud Vision API
    # or paddleocr to extract text and parse the Indian ID fields.
    
    mock_response = {
        "documentType": "Identity Document",
        "documentTypeLabel": "PAN Card",
        "idNumber": "ABCDE1234F",
        "name": "TEST USER",
        "dateOfBirth": "01/01/1990",
        "confidenceScore": 0.99
    }
    
    # Adding CORS headers to allow Web requests
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    }
    
    if req.method == "OPTIONS":
        return https_fn.Response("", status=204, headers=headers)
        
    return https_fn.Response(json.dumps(mock_response), headers=headers, content_type="application/json")


@https_fn.on_request()
def verify_face_and_liveness(req: https_fn.Request) -> https_fn.Response:
    """
    Receives PAN and Selfie images, verifies face match, and performs deepfake liveness checks.
    For demonstration, this is a mock implementation.
    """
    if req.method != "POST":
        return https_fn.Response("Method not allowed", status=405)

    mock_response = {
        "faceMatchSimilarity": 0.85,
        "isVerified": True,
        "deepfakeResult": {
            "textureScore": 95.0,
            "texturePassed": True,
            "motionScore": 90.0,
            "motionPassed": True,
            "landmarkScore": 92.0,
            "landmarkPassed": True,
            "fftScore": 96.0,
            "fftPassed": True,
            "overallConfidence": 93.0,
            "riskLevel": "LOW RISK",
            "isAuthentic": True
        }
    }
    
    headers = {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "Content-Type",
    }
    
    if req.method == "OPTIONS":
        return https_fn.Response("", status=204, headers=headers)

    return https_fn.Response(json.dumps(mock_response), headers=headers, content_type="application/json")
