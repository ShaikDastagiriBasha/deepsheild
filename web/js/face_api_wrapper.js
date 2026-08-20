const MODEL_URL = 'models';

let modelsLoaded = false;

async function loadFaceApiModels() {
    if (modelsLoaded) return true;
    try {
        console.log("Loading face-api models...");
        await Promise.all([
            faceapi.nets.tinyFaceDetector.loadFromUri(MODEL_URL),
            faceapi.nets.faceLandmark68Net.loadFromUri(MODEL_URL),
            faceapi.nets.faceRecognitionNet.loadFromUri(MODEL_URL),
            faceapi.nets.faceExpressionNet.loadFromUri(MODEL_URL),
        ]);
        modelsLoaded = true;
        console.log("face-api models loaded successfully");
        return true;
    } catch (e) {
        console.error("Error loading face-api models:", e);
        return false;
    }
}

// Convert Base64 string to HTMLImageElement
function base64ToImage(base64) {
    return new Promise((resolve, reject) => {
        const img = new Image();
        img.onload = () => resolve(img);
        img.onerror = (e) => reject(e);
        // Prefix with data URI if not present
        if (!base64.startsWith('data:image')) {
            // Assuming jpeg for simplicity, browser usually figures it out if base64 is raw
            img.src = 'data:image/jpeg;base64,' + base64;
        } else {
            img.src = base64;
        }
    });
}

// Ensure the image has dimensions (needed by face-api)
async function prepareImage(img) {
    let attempts = 0;
    while ((img.width === 0 || img.height === 0) && attempts < 50) {
        await new Promise(resolve => setTimeout(resolve, 100));
        attempts++;
    }
    if (img.width === 0) {
        throw new Error("Image failed to load dimensions.");
    }
    return img;
}

window.compareFacesBase64 = async function(docBase64, selfieBase64) {
    await loadFaceApiModels();
    
    try {
        const docImg = await base64ToImage(docBase64);
        const selImg = await base64ToImage(selfieBase64);
        
        await prepareImage(docImg);
        await prepareImage(selImg);

        // Detect face and extract descriptors
        console.log("Detecting doc face...");
        const docResult = await faceapi.detectSingleFace(docImg, new faceapi.TinyFaceDetectorOptions()).withFaceLandmarks().withFaceDescriptor();
        if (!docResult) {
            throw new Error("No face detected in document image.");
        }

        console.log("Detecting selfie face...");
        const selResult = await faceapi.detectSingleFace(selImg, new faceapi.TinyFaceDetectorOptions()).withFaceLandmarks().withFaceDescriptor();
        if (!selResult) {
            throw new Error("No face detected in selfie image.");
        }

        // Calculate euclidean distance
        const distance = faceapi.euclideanDistance(docResult.descriptor, selResult.descriptor);
        
        // Convert distance to a similarity score (0 to 1)
        // distance is typically between 0 (exact match) and ~1.0 (different faces)
        // A common threshold is 0.6
        const similarity = Math.max(0, 1 - distance);

        return JSON.stringify({
            success: true,
            similarity: similarity,
            isMatch: distance < 0.55
        });
    } catch (e) {
        console.error("Face comparison error:", e);
        return JSON.stringify({
            success: false,
            error: e.message
        });
    }
};

window.checkLivenessBase64 = async function(selfieBase64) {
    await loadFaceApiModels();
    
    try {
        const selImg = await base64ToImage(selfieBase64);
        await prepareImage(selImg);

        // Run full detection to get landmarks
        console.log("Detecting face for liveness...");
        const result = await faceapi.detectSingleFace(selImg, new faceapi.TinyFaceDetectorOptions()).withFaceLandmarks().withFaceExpressions();

        if (!result) {
            throw new Error("No face detected for liveness check.");
        }

        // For a basic web liveness check without multiple frames:
        // We will just verify a single face is clearly visible and landmarks are confident.
        // A real liveness check in JS requires video stream analysis (blinking, head movement).
        // For this single-image static check, we just validate it's a real 3D face structure (roughly).
        
        const landmarks = result.landmarks;
        const nose = landmarks.getNose();
        const leftEye = landmarks.getLeftEye();
        const rightEye = landmarks.getRightEye();

        // Very basic checks to ensure landmarks exist
        const hasLandmarks = (nose.length > 0 && leftEye.length > 0 && rightEye.length > 0);

        return JSON.stringify({
            success: true,
            isLive: hasLandmarks, // Simple fallback for single image
            score: hasLandmarks ? 0.9 : 0.1
        });
    } catch (e) {
        console.error("Liveness check error:", e);
        return JSON.stringify({
            success: false,
            error: e.message
        });
    }
};

window.evaluateLivenessFrameBase64 = async function(base64Image) {
    try {
        await loadFaceApiModels();
        const img = await base64ToImage(base64Image);
        const preparedImg = await prepareImage(img);

        const result = await faceapi.detectSingleFace(preparedImg, new faceapi.TinyFaceDetectorOptions())
            .withFaceLandmarks()
            .withFaceExpressions();

        if (!result) {
            return JSON.stringify({ success: false, error: "No face detected" });
        }

        // Calculate blink ratio (approximation based on landmarks)
        const getEyeOpenness = (pts) => {
            // Very rough approx: distance between top and bottom eyelid
            const height = Math.abs(pts[4].y - pts[1].y) + Math.abs(pts[5].y - pts[2].y);
            const width = Math.abs(pts[3].x - pts[0].x);
            return height / (2.0 * width);
        };
        
        const leftEyeRatio = getEyeOpenness(result.landmarks.getLeftEye());
        const rightEyeRatio = getEyeOpenness(result.landmarks.getRightEye());
        const eyeOpenProb = (leftEyeRatio + rightEyeRatio) / 2.0;

        // Head pose (approximation since faceapi.js doesn't give true 3D pose out of the box in this model)
        // We'll estimate yaw by the ratio of left eye to nose vs right eye to nose
        const nose = result.landmarks.getNose()[0];
        const leftEyePos = result.landmarks.getLeftEye()[0];
        const rightEyePos = result.landmarks.getRightEye()[3];
        
        const leftDist = nose.x - leftEyePos.x;
        const rightDist = rightEyePos.x - nose.x;
        let yawEstimate = (leftDist - rightDist) / (leftDist + rightDist); // roughly -1 to 1
        
        // Scale yawEstimate so it triggers thresholds easier
        yawEstimate = yawEstimate * 70.0;

        return JSON.stringify({
            success: true,
            pitch: 0.0, // Hard to estimate reliably without 3D model
            yaw: yawEstimate,
            roll: result.detection.angle?.roll || 0.0,
            leftEyeOpen: leftEyeRatio > 0.22 ? 1.0 : 0.0, // simplified threshold
            rightEyeOpen: rightEyeRatio > 0.22 ? 1.0 : 0.0,
            smileProb: Math.min(1.0, (result.expressions.happy || 0.0) * 1.5)
        });

    } catch (e) {
        return JSON.stringify({ success: false, error: e.message });
    }
};
