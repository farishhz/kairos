import SwiftUI

struct CustomSlider: View {
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double?

    var body: some View {
        GeometryReader { geometry in
            let clampedValue = self.clampValue(self.value)
            let progress = (clampedValue - self.range.lowerBound) / (self.range.upperBound - self.range.lowerBound)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)

                Capsule()
                    .fill(Color.blue)
                    .frame(width: CGFloat(progress) * geometry.size.width, height: 4)

                Circle()
                    .fill(Color.white)
                    .frame(width: 14, height: 14)
                    .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                    .offset(x: CGFloat(progress) * geometry.size.width - 7)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { gesture in
                        self.updateValue(with: gesture.location.x, in: geometry.size.width)
                    })
        }
        .frame(height: 20)
    }

    private func updateValue(with xLocation: CGFloat, in totalWidth: CGFloat) {
        let percentage = max(0, min(1, xLocation / totalWidth))
        let newValue = self.range.lowerBound + (percentage * (self.range.upperBound - self.range.lowerBound))
        self.value = self.applyStep(newValue)
    }

    private func clampValue(_ input: Double) -> Double {
        min(self.range.upperBound, max(self.range.lowerBound, input))
    }

    private func applyStep(_ input: Double) -> Double {
        guard let step else { return self.clampValue(input) }
        let steps = (input - self.range.lowerBound) / step
        let rounded = steps.rounded() * step + self.range.lowerBound
        return self.clampValue(rounded)
    }
}
