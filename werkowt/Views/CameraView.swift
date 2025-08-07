import SwiftUI
import UIKit
import AVFoundation
import PhotosUI

struct CameraView: UIViewControllerRepresentable {
    @Binding var selectedImage: UIImage?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Check camera permission first
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch authStatus {
        case .authorized:
            return createCameraPicker(context: context)
        case .notDetermined:
            // Request permission
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        // Permission granted, but we're already in the view controller
                        // The user will need to try again
                    }
                }
            }
            return createPermissionDeniedController(message: "Camera permission is required to scan nutrition labels. Please grant permission and try again.", context: context)
        case .denied, .restricted:
            return createPermissionDeniedController(message: "Camera access is required to scan nutrition labels. Please enable camera access in Settings.", context: context)
        @unknown default:
            return createPermissionDeniedController(message: "Camera permission is required to scan nutrition labels.", context: context)
        }
    }
    
    private func createCameraPicker(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        picker.cameraCaptureMode = .photo
        return picker
    }
    
    private func createPermissionDeniedController(message: String, context: Context) -> UIViewController {
        let controller = UIViewController()
        
        let label = UILabel()
        label.text = message
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        let settingsButton = UIButton(type: .system)
        settingsButton.setTitle("Open Settings", for: .normal)
        settingsButton.addTarget(CameraPermissionTarget.self, action: #selector(CameraPermissionTarget.openSettings), for: .touchUpInside)
        settingsButton.translatesAutoresizingMaskIntoConstraints = false
        
        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle("Cancel", for: .normal)
        cancelButton.addTarget(context.coordinator, action: #selector(Coordinator.cancel), for: .touchUpInside)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        
        controller.view.addSubview(label)
        controller.view.addSubview(settingsButton)
        controller.view.addSubview(cancelButton)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: controller.view.centerYAnchor, constant: -50),
            label.leadingAnchor.constraint(equalTo: controller.view.leadingAnchor, constant: 40),
            label.trailingAnchor.constraint(equalTo: controller.view.trailingAnchor, constant: -40),
            
            settingsButton.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            settingsButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            
            cancelButton.centerXAnchor.constraint(equalTo: controller.view.centerXAnchor),
            cancelButton.topAnchor.constraint(equalTo: settingsButton.bottomAnchor, constant: 20)
        ])
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImage = image
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        @objc func cancel() {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// Helper class for button targets
class CameraPermissionTarget {
    @objc static func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// Alternative camera view for when device camera is not available (simulator)
struct PhotoLibraryFallbackView: View {
    @Binding var selectedPhotoItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.secondary)
                
                Text("Camera Not Available")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Camera is not available on this device. You can select a nutrition label photo from your library instead.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                PhotosPicker(
                    selection: $selectedPhotoItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    HStack {
                        Image(systemName: "photo.on.rectangle")
                        Text("Choose from Library")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.primary)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Capture Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}