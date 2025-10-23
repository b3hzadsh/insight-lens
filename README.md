
# Insight Lens: Real-Time AI Image Classification 👁️✨

A high-performance, real-time object classification app built with Flutter. This project demonstrates a jank-free camera UI by offloading all heavy AI and image processing tasks to a separate thread using Dart Isolates.

---
![Insight Lens Demo](https://github.com/user-attachments/assets/362eb10c-85a7-431e-b3b7-22f8b3e96538)


## 🚀 Key Features

* **⚡ Real-Time Classification:** Instantly identifies objects, plants, and animals from the live camera feed.
* **🚀 High-Performance (Jank-Free) UI:** Achieves a smooth, 60 FPS user experience by executing the entire inference pipeline on a separate thread, ensuring the main UI thread is never blocked.
* **🔐 On-Device Processing:** All AI analysis is performed locally using the TFLite model. No internet connection is required, ensuring user privacy and offline capability.
* **📱 Cross-Platform:** Built from a single Flutter codebase for both Android and iOS.

---

## 🛠️ Tech Stack

* **Framework:** Flutter
* **AI Model:** TFLite (MobileNetV1)
* **Key Packages:**
    * `camera`: Provides the live image stream from the device's camera.
    * `tflite_flutter`: A high-performance wrapper for running TensorFlow Lite models.
    * `image`: Used for advanced image manipulation (format conversion, cropping, resizing).
    * `permission_handler`: Manages camera permission requests.
* **Core Concept:** Dart `Isolate` for true, parallel concurrency.

---

## 🧠 Technical Deep Dive: Challenges Solved

This project successfully addresses two major challenges encountered in on-device, real-time AI.

### 1. Challenge: UI Jank & Inference Latency

**Problem:** Running a TFLite model on every camera frame is a CPU-intensive operation. Performing this on the main thread would block the UI, causing severe "jank" or "freezing." Simply sending frames to an isolate without control would create a massive processing queue, leading to a noticeable lag (e.g., the UI shows a result for an object you pointed at 3 seconds ago).

**Solution:**
A robust, two-part concurrency model was engineered:

1.  **Isolate Offloading:** The entire inference pipeline—from image conversion to model execution—is moved to a dedicated `Isolate`. This frees the main (UI) thread completely.
2.  **Back-Pressure Management:** A custom back-pressure system was implemented using a `Completer`.
    * The main thread `await`s a `Future` from the `TensorflowService` before sending a new frame.
    * The `TensorflowService` only `complete`s this `Future` *after* it receives the result for the *previous* frame from the isolate.
    * This ensures that only one frame is being processed at a time, eliminating the processing queue and guaranteeing that the classification result is always for the most recent frame.

### 2. Challenge: Android's YUV_420_888 Image Format

**Problem:** The Android `camera` plugin provides image frames in the complex `YUV_420_888` format, not the standard RGB format that the MobileNet model expects.

**Solution:**
A custom, stride-aware YUV-to-RGB conversion function was implemented. This function manually processes the separate Y (luminance), U (chrominance), and V (chrominance) planes provided by the `CameraImage` object.

Crucially, it correctly calculates pixel indices by using the `bytesPerRow` (stride) property of each plane, which accounts for potential memory padding. This low-level byte manipulation was essential to correctly reconstruct the RGB image before pre-processing and feeding it to the model.

---

## 🔜 Future Enhancements (Todo List)

This project serves as a strong foundation, and there are several planned improvements to further enhance its capabilities and user experience:

* **Customizable Camera ROI (Region of Interest):** Implement a frame or overlay to allow users to select and process only a specific part of the camera's view, reducing processing load and focusing on the target.
* **Model Upgrade:** Integrate a more modern and performant image classification model (e.g., MobileNetV2/V3, EfficientNet Lite) to improve accuracy and expand recognition capabilities.
* **Internationalization:** Add support for multiple languages to make the app accessible to a wider global audience.
* **Image File Classification:** Extend functionality to classify objects from existing image files (e.g., from gallery or file picker), not just live camera feeds.
* **UI/UX Improvements:** Refine the user interface for better aesthetics and a more intuitive user experience (font, component, etc).
* **CI/CD Pipeline:** Set up GitHub Actions for automated building and releasing of the application (e.g., for APK/AAB generation).
* **Model Optimization:** Explore converting the `mobilenet_v1_1.0_224` model to an optimized `int8` or `float16` version using the TensorFlow Lite Model Optimization Toolkit and measure its impact on inference speed and accuracy.

---

## 🏁 Setup and Run

### 1. Prerequisites
* [Flutter SDK](https://flutter.dev/docs/get-started/install) installed.
* An Android or iOS device (or simulator).

### 2. Get the Model & Labels
This project requires the `mobilenet_v1_1.0_224.tflite` model and a corresponding `labels_fa.txt` file. Place them in the `assets/` directory:

```

/assets
├── mobilenet_v1_1.0_224.tflite
└── labels_fa.txt

````

Next, register these assets in your `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/mobilenet_v1_1.0_224.tflite
    - assets/labels_fa.txt
````

### 3\. Install and Run

1.  Clone the repository:

    ```bash
    git clone [https://github.com/your-username/insight-lens.git](https://github.com/your-username/insight-lens.git)
    cd insight-lens
    ```

2.  Install dependencies:

    ```bash
    flutter pub get
    ```

3.  Run the app:

    ```bash
    flutter run
    ```

<!-- end list -->

```
```
