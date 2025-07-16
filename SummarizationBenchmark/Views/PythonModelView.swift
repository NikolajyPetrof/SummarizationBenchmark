import SwiftUI
import Foundation
// Импортируем компонент для отображения ошибок с возможностью копирования

struct PythonModelView: View {
    @ObservedObject var viewModel: PythonModelViewModel
    @State private var inputText: String = ""
    @State private var showDependenciesAlert: Bool = false
    
    init(viewModel: PythonModelViewModel = PythonModelViewModel()) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Заголовок
            Text("Python-модели суммаризации")
                .font(.title)
                .fontWeight(.bold)
            
            // Выбор модели
            VStack(alignment: .leading) {
                Text("Выберите модель:")
                    .font(.headline)
                
                Picker("Модель", selection: $viewModel.selectedModel) {
                    ForEach(viewModel.availableModels) { model in
                        Text(model.name).tag(model)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .frame(maxWidth: .infinity)
                .padding(8)
                .background(Color(.textBackgroundColor))
                .cornerRadius(8)
                
                Text(viewModel.selectedModel.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Параметры генерации
            VStack(alignment: .leading) {
                Text("Параметры генерации:")
                    .font(.headline)
                
                HStack {
                    Text("Макс. токенов:")
                    Slider(value: Binding(
                        get: { Double(viewModel.maxTokens) },
                        set: { viewModel.maxTokens = Int($0) }
                    ), in: 50...512, step: 1)
                    Text("\(viewModel.maxTokens)")
                        .frame(width: 40, alignment: .trailing)
                }
                
                HStack {
                    Text("Температура:")
                    Slider(value: $viewModel.temperature, in: 0.0...1.0, step: 0.05)
                    Text(String(format: "%.2f", viewModel.temperature))
                        .frame(width: 40, alignment: .trailing)
                }
                
                HStack {
                    Text("Top-P:")
                    Slider(value: $viewModel.topP, in: 0.0...1.0, step: 0.05)
                    Text(String(format: "%.2f", viewModel.topP))
                        .frame(width: 40, alignment: .trailing)
                }
            }
            
            // Ввод текста
            VStack(alignment: .leading) {
                Text("Текст для суммаризации:")
                    .font(.headline)
                
                TextEditor(text: $inputText)
                    .frame(height: 150)
                    .padding(8)
                    .background(Color(.textBackgroundColor))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Кнопка суммаризации
            Button(action: {
                if !viewModel.dependenciesInstalled {
                    showDependenciesAlert = true
                } else {
                    Task {
                        await viewModel.summarizeText(inputText)
                    }
                }
            }) {
                Text("Суммаризировать")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .disabled(viewModel.isProcessing || inputText.isEmpty)
            
            // Прогресс
            if viewModel.isProcessing {
                VStack {
                    ProgressView(value: viewModel.progress)
                        .progressViewStyle(LinearProgressViewStyle())
                    
                    Text(viewModel.statusMessage)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Результат
            if !viewModel.summary.isEmpty {
                VStack(alignment: .leading) {
                    Text("Результат суммаризации:")
                        .font(.headline)
                    
                    ScrollView {
                        Text(viewModel.summary)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.textBackgroundColor))
                            .cornerRadius(8)
                    }
                    .frame(height: 150)
                    
                    // Кнопка копирования
                    Button(action: {
                        PasteboardHelper.copyToClipboard(viewModel.summary)
                    }) {
                        Label("Копировать", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
                }
            }
            
            // Ошибка
            if !viewModel.errorMessage.isEmpty {
                ErrorView(errorMessage: viewModel.fullErrorText.isEmpty ? viewModel.errorMessage : viewModel.fullErrorText)
                    .frame(maxWidth: .infinity)
            }
            
            Spacer()
        }
        .padding()
        .alert(isPresented: $showDependenciesAlert) {
            Alert(
                title: Text("Требуется установка зависимостей"),
                message: Text("Для работы с Python-моделями необходимо установить библиотеки MLX и MLX-VLM. Установить сейчас?"),
                primaryButton: .default(Text("Установить")) {
                    Task {
                        await viewModel.installDependencies()
                    }
                },
                secondaryButton: .cancel(Text("Отмена"))
            )
        }
        .onAppear {
            Task {
                await viewModel.checkDependencies()
            }
        }
    }
}

#Preview {
    PythonModelView(viewModel: PythonModelViewModel())
}
