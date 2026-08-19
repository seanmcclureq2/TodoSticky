import AppKit
import SwiftUI

struct CollapsedBarView: View {
    @ObservedObject var store: TodoStore
    @ObservedObject var controller: PanelController

    var body: some View {
        ZStack {
            DragHandle(
                onDoubleClick: { controller.toggleCollapsed() },
                onQuit: { NSApp.terminate(nil) },
                currentTheme: controller.theme,
                onSelectTheme: { controller.setTheme($0) },
                showCompleted: store.showCompleted,
                onToggleShowCompleted: { store.toggleShowCompleted() },
                onToggleLoginItem: { controller.toggleLoginItem() }
            )
            HStack(spacing: 6) {
                statusDot
                Text("Tasks · \(store.incompleteCount)")
                    .font(.system(size: 12, weight: .medium))
                Spacer()
            }
            .padding(.horizontal, 10)
            .allowsHitTesting(false)
        }
        .frame(height: PanelController.collapsedHeight)
    }

    @ViewBuilder
    private var statusDot: some View {
        switch store.urgencyStatus {
        case .overdue:
            Circle().fill(Color.red).frame(width: 7, height: 7)
        case .dueSoon:
            Circle().fill(Color.yellow).frame(width: 7, height: 7)
        case .none:
            EmptyView()
        }
    }
}
