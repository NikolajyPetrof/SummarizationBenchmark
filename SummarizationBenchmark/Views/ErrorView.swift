import SwiftUI

/// Компонент для отображения ошибок с возможностью копирования
struct ErrorView: View {
    let errorMessage: String
    @State private var isCopied: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ошибка")
                    .font(.headline)
                    .foregroundColor(.red)
                
                Spacer()
                
                Button(action: {
                    copyToClipboard(errorMessage)
                    withAnimation {
                        isCopied = true
                    }
                    
                    // Сбросить состояние через 2 секунды
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Скопировано" : "Копировать")
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(4)
                }
            }
            
            ScrollView {
                Text(errorMessage)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.red)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.red.opacity(0.1))
                    )
            }
            .frame(maxHeight: 200)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.8))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
    }
    
    /// Копирует текст в буфер обмена
    private func copyToClipboard(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
    }
}

#Preview {
    ErrorView(errorMessage: "Произошла ошибка при выполнении скрипта Python:\nTraceback (most recent call last):\n  File \"/tmp/summarize.py\", line 15, in <module>\n    import torch\nModuleNotFoundError: No module named 'torch'")
        .frame(width: 500)
        .padding()
}
