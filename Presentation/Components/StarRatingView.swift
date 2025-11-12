import SwiftUI

struct StarRatingView: View {
    let rating: Int16
    let maxRating: Int16
    let onRatingChanged: ((Int16) -> Void)?
    let interactive: Bool
    
    init(
        rating: Int16,
        maxRating: Int16 = 5,
        interactive: Bool = false,
        onRatingChanged: ((Int16) -> Void)? = nil
    ) {
        self.rating = rating
        self.maxRating = maxRating
        self.interactive = interactive
        self.onRatingChanged = onRatingChanged
    }
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(1...maxRating, id: \.self) { index in
                Image(systemName: index <= rating ? "star.fill" : "star")
                    .foregroundColor(index <= rating ? .yellow : .gray)
                    .font(.system(size: interactive ? 20 : 16))
                    .onTapGesture {
                        if interactive, let onRatingChanged = onRatingChanged {
                            onRatingChanged(Int16(index))
                        }
                    }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarRatingView(rating: 3, maxRating: 5, interactive: false)
        StarRatingView(rating: 4, maxRating: 5, interactive: true) { rating in
            print("Rating changed to: \(rating)")
        }
    }
    .padding()
}

