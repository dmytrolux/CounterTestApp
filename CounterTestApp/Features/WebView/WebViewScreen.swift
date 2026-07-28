import SwiftUI

struct WebViewScreen: View {
    @StateObject private var viewModel: WebViewViewModel

    init(viewModel: WebViewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        WebViewContainer(
            request: viewModel.request,
            configurationProvider: viewModel.configurationProvider
        )
        .ignoresSafeArea(edges: .bottom)
    }
}
