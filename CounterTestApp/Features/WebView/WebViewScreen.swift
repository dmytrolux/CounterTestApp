import SwiftUI

struct WebViewScreen: View {
    @StateObject private var viewModel: WebViewViewModel

    init(viewModel: WebViewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        WebViewContainer(viewModel: viewModel)
            .ignoresSafeArea(edges: .bottom)
    }
}
