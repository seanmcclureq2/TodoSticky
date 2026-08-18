import AppKit
import SwiftUI

struct RootView: View {
    @ObservedObject var store: TodoStore
    @ObservedObject var controller: PanelController

    var body: some View {
        Group {
            if controller.isCollapsed {
                CollapsedBarView(store: store, controller: controller)
            } else {
                VStack(spacing: 0) {
                    TitleBarView(store: store, controller: controller)
                    Divider()
                    TodoListView(store: store)
                    Divider()
                    AddItemView(store: store)
                }
            }
        }
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.black.opacity(0.15), lineWidth: 1)
        )
        .overlay(
            ResizeOverlay(
                isEnabled: !controller.isCollapsed,
                minSize: NSSize(width: PanelController.minExpandedWidth, height: PanelController.minExpandedHeight)
            )
        )
    }
}
