import SwiftUI

struct TodoListView: View {
    @ObservedObject var store: TodoStore

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(store.sortedActive) { item in
                    TodoRowView(store: store, item: item)
                }
                ForEach(store.sortedCompleted) { item in
                    TodoRowView(store: store, item: item)
                }
            }
            .padding(.horizontal, 8)
        }
    }
}
