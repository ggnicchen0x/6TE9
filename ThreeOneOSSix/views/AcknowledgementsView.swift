import SwiftUI

struct AcknowledgementsView: View {
    var body: some View {
        List {
            Section {
                Text("Compass")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
