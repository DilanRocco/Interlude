import AppKit
import SwiftUI
import Combine

private var postureFlowWindow = NSWindow(
    contentRect: NSRect(x: 0, y: 0, width: 460, height: 520),
    styleMask: [.titled, .closable],
    backing: .buffered,
    defer: false
)

private let postureFlowViewModel = PostureMenuViewModel()

func openPostureFlowWindow() {
    postureFlowViewModel.startPostureFlow()
    postureFlowSubscriptions.removeAll()

    let rootView = PostureFlowView(viewModel: postureFlowViewModel)
    postureFlowWindow.contentView = NSHostingView(rootView: rootView)
    postureFlowWindow.title = "Posture Check"
    postureFlowWindow.center()
    postureFlowWindow.isReleasedWhenClosed = false
    postureFlowWindow.makeKeyAndOrderFront(nil)
    postureFlowWindow.orderFrontRegardless()

    postureFlowViewModel.$isPresented
        .sink { isPresented in
            guard !isPresented else { return }
            postureFlowWindow.close()
        }
        .store(in: &postureFlowSubscriptions)
}

private var postureFlowSubscriptions: Set<AnyCancellable> = []
