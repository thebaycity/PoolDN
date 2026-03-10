import SwiftUI
import UIKit

struct ImageCropView: View {
    let image: UIImage
    let onCrop: (Data) -> Void
    let onCancel: () -> Void

    @State private var displayImage: UIImage?
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    @State private var containerSize: CGSize = .zero

    private let cropDiameter: CGFloat = 300

    private var activeImage: UIImage { displayImage ?? image }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            GeometryReader { geo in
                let fittedSize = imageFittingSize(in: geo.size)

                ZStack {
                    Image(uiImage: activeImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: fittedSize.width, height: fittedSize.height)
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            DragGesture()
                                .onChanged { value in
                                    offset = CGSize(
                                        width: lastOffset.width + value.translation.width,
                                        height: lastOffset.height + value.translation.height
                                    )
                                }
                                .onEnded { _ in
                                    lastOffset = offset
                                }
                                .simultaneously(with:
                                    MagnifyGesture()
                                        .onChanged { value in
                                            let newScale = lastScale * value.magnification
                                            scale = min(max(newScale, 1.0), 4.0)
                                        }
                                        .onEnded { _ in
                                            lastScale = scale
                                        }
                                )
                        )

                    CropOverlay(cropDiameter: cropDiameter)
                        .allowsHitTesting(false)
                }
                .frame(width: geo.size.width, height: geo.size.height)
                .onAppear { containerSize = geo.size }
                .onChange(of: geo.size) { _, newSize in containerSize = newSize }
            }

            VStack {
                Spacer()
                HStack(spacing: 40) {
                    Button("Cancel") { onCancel() }
                        .font(.body)
                        .foregroundColor(.white)

                    Button("Use Photo") { cropImage() }
                        .font(.body.bold())
                        .foregroundColor(Color.theme.accent)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            displayImage = image.normalizedOrientation()
        }
    }

    private func imageFittingSize(in size: CGSize) -> CGSize {
        let aspectRatio = activeImage.size.width / activeImage.size.height
        if aspectRatio > size.width / size.height {
            let width = size.width
            return CGSize(width: width, height: width / aspectRatio)
        } else {
            let height = size.height
            return CGSize(width: height * aspectRatio, height: height)
        }
    }

    private func cropImage() {
        let img = activeImage
        let fitted = imageFittingSize(in: containerSize)
        let scaledW = fitted.width * scale
        let scaledH = fitted.height * scale
        let outputSize = CGSize(width: cropDiameter, height: cropDiameter)

        let renderer = UIGraphicsImageRenderer(size: outputSize)
        let result = renderer.image { ctx in
            ctx.cgContext.addEllipse(in: CGRect(origin: .zero, size: outputSize))
            ctx.cgContext.clip()

            // Map the crop circle region to the output:
            // Crop circle is always centered in the container.
            // Image center in container = container center + offset.
            // So in the output coordinate system, the image is drawn at:
            let drawRect = CGRect(
                x: offset.width - (scaledW - cropDiameter) / 2,
                y: offset.height - (scaledH - cropDiameter) / 2,
                width: scaledW,
                height: scaledH
            )
            img.draw(in: drawRect)
        }

        if let data = result.jpegData(compressionQuality: 0.85) {
            onCrop(data)
        }
    }
}

private extension UIImage {
    func normalizedOrientation() -> UIImage {
        guard imageOrientation != .up else { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let result = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return result ?? self
    }
}

private struct CropOverlay: View {
    let cropDiameter: CGFloat

    var body: some View {
        GeometryReader { geo in
            let rect = geo.frame(in: .local)
            Canvas { context, size in
                context.fill(Path(rect), with: .color(.black.opacity(0.6)))

                let circleRect = CGRect(
                    x: (size.width - cropDiameter) / 2,
                    y: (size.height - cropDiameter) / 2,
                    width: cropDiameter,
                    height: cropDiameter
                )
                context.blendMode = .destinationOut
                context.fill(Path(ellipseIn: circleRect), with: .color(.white))

                context.blendMode = .normal
                context.stroke(
                    Path(ellipseIn: circleRect),
                    with: .color(.white.opacity(0.7)),
                    lineWidth: 1.5
                )
            }
            .compositingGroup()
        }
    }
}
