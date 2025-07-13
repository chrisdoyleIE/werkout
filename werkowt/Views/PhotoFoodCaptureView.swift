import SwiftUI
import UIKit
import AVFoundation

struct PhotoFoodCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var captureState: CaptureState = .camera
    @State private var capturedImage: UIImage?
    @State private var hasNutritionInfo = false
    @State private var flashMode: UIImagePickerController.CameraFlashMode = .auto
    @State private var analysisResult: ClaudeAPIClient.FoodAnalysisResult?
    @State private var errorMessage: String?
    @State private var isAnalyzing = false
    @State private var showingVerification = false
    @State private var cameraPermissionStatus: AVAuthorizationStatus = .notDetermined
    @State private var showingPermissionAlert = false
    @State private var showingImagePicker = false
    
    let selectedMealType: MealType
    let onImageCaptured: ((UIImage) -> Void)?
    
    init(selectedMealType: MealType, onImageCaptured: ((UIImage) -> Void)? = nil) {
        self.selectedMealType = selectedMealType
        self.onImageCaptured = onImageCaptured
    }
    
    enum CaptureState {
        case camera
        case review
        case analyzing
        case permissionDenied
    }
    
    var body: some View {
        ZStack {
            let _ = print("🔄 Current captureState: \(captureState)")
            switch captureState {
            case .camera:
                let _ = print("📷 Rendering camera state")
                if cameraPermissionStatus == .authorized {
                    CameraView(
                        image: $capturedImage,
                        flashMode: $flashMode,
                        onCapture: { image in
                            print("🎯 onCapture called - setting image and changing to review state")
                            capturedImage = image
                            withAnimation(.easeInOut(duration: 0.3)) {
                                captureState = .review
                            }
                            print("🎯 State should now be .review")
                        }
                    )
                } else {
                    // Show loading while checking permissions
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Checking camera access...")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                }
                
            case .permissionDenied:
                VStack(spacing: 24) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    
                    VStack(spacing: 12) {
                        Text("Camera Access Required")
                            .font(.system(size: 24, weight: .semibold))
                        
                        Text("To capture photos of your food, please allow camera access in Settings.")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    VStack(spacing: 12) {
                        Button("Open Settings") {
                            if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsURL)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Choose from Photos") {
                            showingImagePicker = true
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                    }
                }
                .padding()
                
            case .review:
                let _ = print("📱 Rendering review state")
                if let image = capturedImage {
                    let _ = print("📱 Review state: Image captured, hasNutritionInfo: \(hasNutritionInfo)")
                    // Full screen photo as background
                    GeometryReader { geometry in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    }
                    .ignoresSafeArea()
                    
                    // Overlay controls
                    VStack {
                        // Top bar with close button
                        HStack {
                            Button(action: { dismiss() }) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Circle().fill(Color.black.opacity(0.5)))
                            }
                            .padding()
                            
                            Spacer()
                        }
                        
                        Spacer()
                        
                        // Bottom controls
                        VStack(spacing: 24) {
                            let _ = print("🎯 Rendering bottom controls VStack")
                            // Nutrition info toggle (only show if doing analysis)
                            if onImageCaptured == nil {
                                VStack(alignment: .leading, spacing: 16) {
                                    let _ = print("⭐ Rendering nutrition toggle VStack")
                                    HStack {
                                        Image(systemName: "wand.and.stars")
                                            .font(.system(size: 24))
                                            .foregroundColor(.white)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Nutritional information visible")
                                                .font(.system(size: 18, weight: .semibold))
                                                .foregroundColor(.white)
                                            
                                            Text("Toggle ON if nutrition facts are shown in the photo")
                                                .font(.system(size: 14))
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        
                                        Spacer()
                                        
                                        Toggle("", isOn: $hasNutritionInfo)
                                            .toggleStyle(SwitchToggleStyle(tint: .purple))
                                            .scaleEffect(1.2)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 20)
                                    .background(.black.opacity(0.7))
                                    .cornerRadius(16)
                                }
                                .padding(.horizontal)
                            }
                            
                            // Action buttons
                            HStack(spacing: 16) {
                                Button(action: {
                                    print("🔄 Retake button pressed")
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    capturedImage = nil
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        captureState = .camera
                                    }
                                    print("🔄 Retake: State changed to camera")
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.counterclockwise")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Retake")
                                            .font(.system(size: 16, weight: .medium))
                                    }
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(.regularMaterial)
                                    .cornerRadius(12)
                                }
                                
                                Button(action: {
                                    print("📸 Use Photo button pressed")
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    
                                    if let onImageCaptured = onImageCaptured, let image = capturedImage {
                                        // If we have a callback, just return the image
                                        print("📸 Use Photo: Calling image captured callback")
                                        onImageCaptured(image)
                                    } else {
                                        // Otherwise proceed with analysis
                                        withAnimation(.easeInOut(duration: 0.3)) {
                                            captureState = .analyzing
                                        }
                                        print("📸 Use Photo: State changed to analyzing")
                                        analyzePhoto()
                                    }
                                }) {
                                    HStack {
                                        Text(onImageCaptured != nil ? "Use for Reference" : "Use This Photo")
                                            .font(.system(size: 16, weight: .semibold))
                                        Image(systemName: onImageCaptured != nil ? "checkmark" : "arrow.right")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.primary)
                                    .cornerRadius(12)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 32)
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 24))
                    }
                    .ignoresSafeArea(edges: .bottom)
                }
                
            case .analyzing:
                if let image = capturedImage {
                    // Dimmed photo background
                    GeometryReader { geometry in
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                            .overlay(Color.black.opacity(0.6))
                    }
                    .ignoresSafeArea()
                    
                    // Loading overlay
                    VStack(spacing: 24) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Analyzing your photo...")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                        
                        if hasNutritionInfo {
                            Text("Extracting nutrition information")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        } else {
                            Text("Searching for food details")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                
            }
            
            // Error handling overlay
            if let error = errorMessage {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.orange)
                        
                        Text("Analysis Failed")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button("Try Again") {
                            errorMessage = nil
                            capturedImage = nil
                            captureState = .camera
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(32)
                    .background(.regularMaterial)
                    .cornerRadius(16)
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            #if targetEnvironment(simulator)
            // Auto-load test image in simulator for easier testing
            print("🧪 Simulator detected - auto-loading test image")
            if let testImage = UIImage(named: "test-food-image") {
                print("✅ Test image loaded successfully")
                capturedImage = testImage
                captureState = .review
            } else {
                print("❌ Could not load test-food-image from Assets")
            }
            #else
            // Real device - check camera permissions
            checkCameraPermission()
            #endif
        }
        .sheet(isPresented: $showingVerification) {
            if let result = analysisResult {
                FoodVerificationView(
                    analysisResult: result,
                    selectedMealType: selectedMealType
                )
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(image: $capturedImage) { image in
                capturedImage = image
                withAnimation(.easeInOut(duration: 0.3)) {
                    captureState = .review
                }
            }
        }
        .onChange(of: showingVerification) { _, isShowing in
            if !isShowing {
                // When verification sheet dismisses, close the entire photo capture flow
                dismiss()
            }
        }
    }
    
    private func checkCameraPermission() {
        cameraPermissionStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch cameraPermissionStatus {
        case .authorized:
            // Camera is already authorized
            break
        case .notDetermined:
            // Request camera permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraPermissionStatus = granted ? .authorized : .denied
                    if !granted {
                        captureState = .permissionDenied
                    }
                }
            }
        case .denied, .restricted:
            captureState = .permissionDenied
        @unknown default:
            captureState = .permissionDenied
        }
    }
    
    private func analyzePhoto() {
        guard let image = capturedImage else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                let result = try await ClaudeAPIClient.shared.analyzeFoodPhoto(
                    image: image,
                    hasNutritionInfo: hasNutritionInfo
                )
                
                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false
                    showingVerification = true
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                    captureState = .review
                }
            }
        }
    }
}

// MARK: - Camera View Wrapper
struct CameraView: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Binding var flashMode: UIImagePickerController.CameraFlashMode
    let onCapture: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        
        // Check if camera is available before setting source type
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("📷 Camera available - using camera source")
            picker.sourceType = .camera
            picker.cameraFlashMode = flashMode
            picker.allowsEditing = false
            
            // Add custom overlay for flash control
            let overlayView = CameraOverlayView(flashMode: $flashMode) { mode in
                picker.cameraFlashMode = mode
            }
            let hostingController = UIHostingController(rootView: overlayView)
            hostingController.view.backgroundColor = .clear
            hostingController.view.frame = picker.view.bounds
            picker.cameraOverlayView = hostingController.view
        } else {
            print("📱 Camera not available (simulator) - using photo library")
            // Fallback to photo library if camera not available (simulator)
            picker.sourceType = .photoLibrary
            picker.allowsEditing = false
        }
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        uiViewController.cameraFlashMode = flashMode
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onCapture(image)
            }
            // Don't dismiss here - let SwiftUI handle it when state changes to .review
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

// MARK: - Camera Overlay View
struct CameraOverlayView: View {
    @Binding var flashMode: UIImagePickerController.CameraFlashMode
    let onFlashChange: (UIImagePickerController.CameraFlashMode) -> Void
    
    var flashIcon: String {
        switch flashMode {
        case .off:
            return "bolt.slash.fill"
        case .on:
            return "bolt.fill"
        case .auto:
            return "bolt.badge.a.fill"
        @unknown default:
            return "bolt.badge.a.fill"
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                Spacer()
                
                Button(action: toggleFlash) {
                    Image(systemName: flashIcon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                        .padding(12)
                        .background(Circle().fill(Color.black.opacity(0.5)))
                }
                .padding()
            }
            
            Spacer()
        }
    }
    
    private func toggleFlash() {
        let newMode: UIImagePickerController.CameraFlashMode
        switch flashMode {
        case .off:
            newMode = .on
        case .on:
            newMode = .auto
        case .auto:
            newMode = .off
        @unknown default:
            newMode = .auto
        }
        flashMode = newMode
        onFlashChange(newMode)
    }
}

// MARK: - Image Picker for Photo Library
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onImageSelected: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.allowsEditing = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> ImagePickerCoordinator {
        ImagePickerCoordinator(self)
    }
    
    class ImagePickerCoordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

#Preview {
    PhotoFoodCaptureView(selectedMealType: .lunch)
}