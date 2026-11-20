import SwiftUI

struct AcknowledgementsView: View {
    var body: some View {
        List {
            Section {
                Text("Byte External")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}
