import AppKit
import SwiftUI

struct TitleBarView: View {
    @ObservedObject var store: TodoStore
    @ObservedObject var controller: PanelController

    var body: some View {
        ZStack {
            DragHandle(
                onDoubleClick: { controller.toggleCollapsed() },
                onQuit: { NSApp.terminate(nil) },
                currentTheme: controller.theme,
                onSelectTheme: { controller.setTheme($0) },
                onToggleLoginItem: { controller.toggleLoginItem() }
            )
            HStack {
                Text("Tasks · \(store.incompleteCount)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }
            .padding(.horizontal, 10)
            .allowsHitTesting(false)
        }
        .frame(height: 28)
    }
}
