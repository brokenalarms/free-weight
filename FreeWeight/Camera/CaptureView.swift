import SwiftUI

struct CaptureView: View {
    @Environment(AppState.self) private var appState
    @Environment(\.dismiss) private var dismiss
    @State private var camera = CameraManager()
    @State private var selectedAngle: PhotoAngle = .front
    @State private var capturedAngles: [PhotoAngle: Data] = [:]
    @State private var isCapturing = false
    @State private var isSaving = false
    @State private var showReview = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if camera.isAuthorized {
                cameraContent
            } else {
                cameraPermissionView
            }
        }
        .task {
            await camera.requestAccess()
            if camera.isAuthorized {
                camera.configure()
                camera.start()
            }
        }
        .onDisappear {
            camera.stop()
        }
    }

    @ViewBuilder
    private var cameraContent: some View {
        ZStack {
            // Live camera preview
            CameraPreview(session: camera.session)
                .ignoresSafeArea()

            // Body silhouette overlay
            BodySilhouetteOverlay()
                .ignoresSafeArea()

            // Controls
            VStack {
                // Top bar
                HStack {
                    Button("Cancel") { dismiss() }
                        .font(.body.weight(.medium))
                        .foregroundStyle(.white)

                    Spacer()

                    Text(selectedAngle.label)
                        .font(.headline)
                        .foregroundStyle(.white)

                    Spacer()

                    Button {
                        camera.flipCamera()
                    } label: {
                        Image(systemName: "camera.rotate")
                            .font(.title3)
                            .foregroundStyle(.white)
                    }
                }
                .padding()

                Spacer()

                // Angle picker
                Picker("Angle", selection: $selectedAngle) {
                    ForEach(PhotoAngle.allCases) { angle in
                        Text(angle.label).tag(angle)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 40)

                // Capture button
                Button(action: capture) {
                    ZStack {
                        Circle()
                            .fill(.white)
                            .frame(width: 72, height: 72)
                        Circle()
                            .stroke(.gray.opacity(0.5), lineWidth: 3)
                            .frame(width: 64, height: 64)
                    }
                }
                .disabled(isCapturing)
                .opacity(isCapturing ? 0.5 : 1)
                .padding(.vertical, 20)

                // Captured angle indicators
                HStack(spacing: 12) {
                    ForEach(PhotoAngle.allCases) { angle in
                        VStack(spacing: 4) {
                            Circle()
                                .fill(capturedAngles[angle] != nil ? .green : .white.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Text(angle.label)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                }

                // Save button (appears after any capture)
                if !capturedAngles.isEmpty {
                    Button(action: savePhotos) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Save \(capturedAngles.count) photo\(capturedAngles.count == 1 ? "" : "s")")
                        }
                        .font(.headline)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(.green, in: Capsule())
                    }
                    .disabled(isSaving)
                    .padding(.top, 8)
                }

                Spacer().frame(height: 16)
            }

            // Error overlay
            if let errorMessage {
                VStack {
                    Spacer()
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.red.opacity(0.8), in: RoundedRectangle(cornerRadius: 8))
                        .padding()
                }
            }
        }
    }

    @ViewBuilder
    private var cameraPermissionView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("Camera Access Required")
                .font(.title3.weight(.semibold))

            Text("FreeWeight needs camera access to take progress photos.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)

            Button("Cancel") { dismiss() }
                .foregroundStyle(.secondary)
        }
    }

    private func capture() {
        isCapturing = true
        Task {
            defer { isCapturing = false }
            do {
                let data = try await camera.capturePhoto()
                capturedAngles[selectedAngle] = data
                errorMessage = nil
            } catch {
                errorMessage = "Capture failed: \(error.localizedDescription)"
            }
        }
    }

    private func savePhotos() {
        guard let rootURL = appState.rootFolderURL else { return }
        isSaving = true
        Task {
            defer { isSaving = false }
            let fm = ProgressFileManager(rootURL: rootURL)
            let today = Date()
            do {
                for (angle, data) in capturedAngles {
                    _ = try fm.savePhoto(data: data, date: today, angle: angle)
                }
                await appState.refreshTimeline()
                dismiss()
            } catch {
                errorMessage = "Save failed: \(error.localizedDescription)"
            }
        }
    }
}

// MARK: - Body Silhouette Overlay

/// A subtle, low-opacity human body outline to help users align consistently.
struct BodySilhouetteOverlay: View {
    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let height = geo.size.height

            Canvas { context, size in
                // Draw a simple human figure outline
                var path = Path()

                let headRadius: CGFloat = size.width * 0.055
                let headCenterY: CGFloat = height * 0.12

                // Head
                path.addEllipse(in: CGRect(
                    x: centerX - headRadius,
                    y: headCenterY - headRadius,
                    width: headRadius * 2,
                    height: headRadius * 2
                ))

                // Neck
                let neckTop = headCenterY + headRadius
                let neckBottom = neckTop + height * 0.03
                path.move(to: CGPoint(x: centerX - headRadius * 0.4, y: neckTop))
                path.addLine(to: CGPoint(x: centerX - headRadius * 0.4, y: neckBottom))
                path.move(to: CGPoint(x: centerX + headRadius * 0.4, y: neckTop))
                path.addLine(to: CGPoint(x: centerX + headRadius * 0.4, y: neckBottom))

                // Shoulders
                let shoulderY = neckBottom
                let shoulderWidth = size.width * 0.22
                path.move(to: CGPoint(x: centerX - shoulderWidth, y: shoulderY))
                path.addLine(to: CGPoint(x: centerX + shoulderWidth, y: shoulderY))

                // Torso (slight taper)
                let torsoBottom = height * 0.52
                let hipWidth = size.width * 0.15
                path.move(to: CGPoint(x: centerX - shoulderWidth, y: shoulderY))
                path.addLine(to: CGPoint(x: centerX - hipWidth, y: torsoBottom))
                path.move(to: CGPoint(x: centerX + shoulderWidth, y: shoulderY))
                path.addLine(to: CGPoint(x: centerX + hipWidth, y: torsoBottom))

                // Waist line
                let waistY = height * 0.42
                let waistWidth = size.width * 0.16
                path.move(to: CGPoint(x: centerX - waistWidth, y: waistY))
                path.addLine(to: CGPoint(x: centerX + waistWidth, y: waistY))

                // Hip line
                path.move(to: CGPoint(x: centerX - hipWidth, y: torsoBottom))
                path.addLine(to: CGPoint(x: centerX + hipWidth, y: torsoBottom))

                // Arms
                let armTopY = shoulderY + height * 0.01
                let armBottomY = height * 0.45
                let armWidth = size.width * 0.035
                // Left arm
                path.move(to: CGPoint(x: centerX - shoulderWidth, y: armTopY))
                path.addLine(to: CGPoint(x: centerX - shoulderWidth - armWidth, y: armBottomY))
                // Right arm
                path.move(to: CGPoint(x: centerX + shoulderWidth, y: armTopY))
                path.addLine(to: CGPoint(x: centerX + shoulderWidth + armWidth, y: armBottomY))

                // Legs
                let legBottomY = height * 0.82
                let legSpread = size.width * 0.06
                // Left leg
                path.move(to: CGPoint(x: centerX - hipWidth * 0.6, y: torsoBottom))
                path.addLine(to: CGPoint(x: centerX - legSpread - hipWidth * 0.3, y: legBottomY))
                // Right leg
                path.move(to: CGPoint(x: centerX + hipWidth * 0.6, y: torsoBottom))
                path.addLine(to: CGPoint(x: centerX + legSpread + hipWidth * 0.3, y: legBottomY))

                context.stroke(
                    path,
                    with: .color(.white.opacity(0.15)),
                    lineWidth: 1.5
                )
            }
        }
        .allowsHitTesting(false)
    }
}
