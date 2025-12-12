import SwiftUI

extension LogCluster {
    @ViewBuilder public var ShareButton: some View {
        ShareButtonView(cluster: self)
    }

    struct ShareButtonView: View {
        let cluster: LogCluster

        var body: some View {
            Button(action: { cluster.copyArchiveUrl() }) {
                HStack {
                    Image(systemName: "list.clipboard")
                    Text("Share Logs")
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.teal)
            .help("Click to copy, or drag to drag, a zip archive of today's logs")
            .draggable(cluster) {
                Image(systemName: "zipper.page")
                    .font(.largeTitle)
                    .bold()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.white)
                    .padding(10)
                    .background(Color.accentColor.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerSize: CGSize(width: 10, height: 10)))
                    .shadow(radius: 25)
            }
        }
    }
}

//#Preview {
//    LogCluster.ShareButton(cluster: .)
//}
