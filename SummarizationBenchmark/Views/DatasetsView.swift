//
//  DatasetsView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 27.06.2025.
//

import SwiftUI
import AppKit

struct DatasetsView: View {
    @ObservedObject var datasetManager: DatasetManager
    @StateObject private var downloader = DatasetDownloader()
    
    @State private var isShowingAddSheet = false
    @State private var selectedSampleSize = DatasetConstants.mediumSampleSize
    @State private var selectedDatasetType: Dataset.DatasetSource = .cnnDailyMail
    @State private var isShowingDetail = false
    @State private var selectedDataset: Dataset?
    
    private let sampleSizes = [
        DatasetConstants.smallSampleSize,
        DatasetConstants.mediumSampleSize,
        DatasetConstants.largeSampleSize
    ]
    
    var body: some View {
        NavigationStack {
            VStack {
                if datasetManager.datasets.isEmpty {
                    emptyStateView
                } else {
                    datasetListView
                }
            }
            .navigationTitle("Датасеты")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { isShowingAddSheet = true }) {
                        Label("Добавить датасет", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                addDatasetView
            }
            .sheet(isPresented: $isShowingDetail) {
                if let dataset = selectedDataset {
                    datasetDetailView(dataset)
                }
            }
            .alert("Ошибка", isPresented: .constant(datasetManager.errorMessage != nil)) {
                Button("OK") {
                    datasetManager.errorMessage = nil
                }
            } message: {
                Text(datasetManager.errorMessage ?? "")
            }
        }
    }
    
    // Представление для пустого состояния
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 72))
                .foregroundColor(.secondary)
            
            Text("Нет доступных датасетов")
                .font(.title2)
                .fontWeight(.medium)
            
            Text("Добавьте датасет для тестирования моделей суммаризации")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: { isShowingAddSheet = true }) {
                Text("Добавить датасет")
                    .fontWeight(.semibold)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top)
        }
        .padding()
    }
    
    // Представление списка датасетов
    private var datasetListView: some View {
        List {
            ForEach(datasetManager.datasets) { dataset in
                datasetRow(dataset)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedDataset = dataset
                        isShowingDetail = true
                    }
            }
            .onDelete(perform: deleteDatasets)
        }
    }
    
    // Строка датасета
    private func datasetRow(_ dataset: Dataset) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(dataset.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(dataset.entries.count) записей")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(dataset.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Label(dataset.source.rawValue, systemImage: sourceIcon(for: dataset.source))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Label(dataset.category.rawValue, systemImage: categoryIcon(for: dataset.category))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
    
    // Представление для добавления датасета
    private var addDatasetView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Тип датасета")) {
                    Picker("Источник", selection: $selectedDatasetType) {
                        ForEach(Dataset.DatasetSource.allCases, id: \.self) { source in
                            Text(source.rawValue).tag(source)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Размер выборки")) {
                    Picker("Количество примеров", selection: $selectedSampleSize) {
                        ForEach(sampleSizes, id: \.self) { size in
                            Text("\(size) примеров").tag(size)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    Button(action: downloadSelectedDataset) {
                        if downloader.isDownloading {
                            HStack {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(0.8)
                                
                                Text("Загрузка...")
                                    .padding(.leading, 8)
                            }
                        } else {
                            Text("Загрузить датасет")
                        }
                    }
                    .disabled(downloader.isDownloading)
                    
                    if downloader.isDownloading {
                        VStack(alignment: .leading) {
                            Text(downloader.statusMessage)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            ProgressView(value: downloader.downloadProgress)
                                .progressViewStyle(.linear)
                                .padding(.top, 4)
                        }
                        
                        Button("Отменить загрузку") {
                            downloader.cancelDownload()
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section(header: Text("Информация")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("О датасете \(selectedDatasetType.rawValue)")
                            .font(.headline)
                        
                        Text(datasetDescription(for: selectedDatasetType))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Добавить датасет")
            //.navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") {
                        isShowingAddSheet = false
                    }
                }
            }
            .alert("Ошибка", isPresented: .constant(downloader.errorMessage != nil)) {
                Button("OK") {
                    downloader.errorMessage = nil
                }
            } message: {
                Text(downloader.errorMessage ?? "")
            }
        }
    }
    
    // Представление для детальной информации о датасете
    private func datasetDetailView(_ dataset: Dataset) -> some View {
        NavigationStack {
            List {
                Section(header: Text("Информация")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(dataset.name)
                            .font(.headline)
                        
                        Text(dataset.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Label(dataset.source.rawValue, systemImage: sourceIcon(for: dataset.source))
                                .font(.caption)
                            
                            Spacer()
                            
                            Label(dataset.category.rawValue, systemImage: categoryIcon(for: dataset.category))
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Статистика")) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Количество записей")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(dataset.entries.count)")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Средняя длина текста")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(dataset.statistics.averageTextLength)) символов")
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Средняя длина саммари")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text("\(Int(dataset.statistics.averageSummaryLength)) символов")
                                .font(.headline)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .leading) {
                            Text("Коэффициент сжатия")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(String(format: "%.2f", dataset.statistics.averageCompressionRatio))
                                .font(.headline)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                Section(header: Text("Примеры")) {
                    ForEach(dataset.entries.prefix(5)) { entry in
                        NavigationLink(destination: EntryDetailView(entry: entry)) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.text.prefix(100) + "...")
                                    .font(.subheadline)
                                    .lineLimit(2)
                                
                                Text("Длина: \(entry.characterCount) символов")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    if dataset.entries.count > 5 {
                        NavigationLink("Показать все \(dataset.entries.count) записей") {
                            List(dataset.entries) { entry in
                                NavigationLink(destination: EntryDetailView(entry: entry)) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.text.prefix(100) + "...")
                                            .font(.subheadline)
                                            .lineLimit(2)
                                        
                                        Text("Длина: \(entry.characterCount) символов")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            .navigationTitle("Все записи")
                        }
                    }
                }
                
                Section(header: Text("Метаданные")) {
                    ForEach(dataset.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(key)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Text(value)
                                .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("Детали датасета")
            //.navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Выбрать") {
                        datasetManager.selectedDataset = dataset
                        isShowingDetail = false
                    }
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Закрыть") {
                        isShowingDetail = false
                    }
                }
            }
        }
    }
    
    // Загрузка выбранного датасета
    private func downloadSelectedDataset() {
        Task {
            var dataset: Dataset?
            
            switch selectedDatasetType {
            case .cnnDailyMail:
                dataset = await downloader.downloadCNNDailyMailDataset(sampleSize: selectedSampleSize)
            case .redditTIFU:
                dataset = await downloader.downloadRedditTIFUDataset(sampleSize: selectedSampleSize)
            case .scientificAbstracts:
                dataset = await downloader.downloadScientificAbstractsDataset(sampleSize: selectedSampleSize)
            case .custom:
                // Для пользовательских датасетов нужна отдельная логика
                break
            }
            
            if let dataset = dataset {
                datasetManager.datasets.append(dataset)
                datasetManager.saveDataset(dataset)
                datasetManager.selectedDataset = dataset
                isShowingAddSheet = false
            }
        }
    }
    
    // Удаление датасетов
    private func deleteDatasets(at offsets: IndexSet) {
        for index in offsets {
            let dataset = datasetManager.datasets[index]
            datasetManager.deleteDataset(dataset)
        }
    }
    
    // Получение иконки для источника датасета
    private func sourceIcon(for source: Dataset.DatasetSource) -> String {
        switch source {
        case .cnnDailyMail:
            return "newspaper"
        case .redditTIFU:
            return "person.2"
        case .scientificAbstracts:
            return "book"
        case .custom:
            return "doc.text"
        }
    }
    
    // Получение иконки для категории датасета
    private func categoryIcon(for category: Dataset.DatasetCategory) -> String {
        switch category {
        case .news:
            return "globe"
        case .social:
            return "bubble.left.and.bubble.right"
        case .scientific:
            return "graduationcap"
        case .other:
            return "doc"
        }
    }
    
    // Получение описания для типа датасета
    private func datasetDescription(for source: Dataset.DatasetSource) -> String {
        switch source {
        case .cnnDailyMail:
            return "Датасет CNN/DailyMail содержит новостные статьи и их саммари. Это один из наиболее популярных датасетов для задач суммаризации текста. Статьи относятся к различным темам: политика, технологии, наука, спорт и т.д."
        case .redditTIFU:
            return "Датасет Reddit TIFU содержит посты из сабреддита 'Today I F***ed Up', где пользователи рассказывают о своих неудачах и ошибках. Каждый пост имеет краткое саммари (TL;DR), написанное самим автором."
        case .scientificAbstracts:
            return "Датасет Scientific Abstracts содержит научные абстракты из различных областей знаний. Каждый абстракт сопровождается саммари, которое кратко описывает основные результаты исследования."
        case .custom:
            return "Пользовательский датасет позволяет загрузить собственные тексты и саммари для тестирования моделей суммаризации."
        }
    }
}

// Представление для детальной информации о записи датасета
struct EntryDetailView: View {
    let entry: DatasetEntry
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("Исходный текст")
                        .font(.headline)
                    
                    Text(entry.text)
                        .font(.body)
                        .padding()
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                if let summary = entry.referenceSummary {
                    Group {
                        Text("Эталонное саммари")
                            .font(.headline)
                        
                        Text(summary)
                            .font(.body)
                            .padding()
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
                
                Group {
                    Text("Статистика")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Длина текста:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(entry.characterCount) символов")
                        }
                        
                        HStack {
                            Text("Количество слов:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(entry.wordCount) слов")
                        }
                        
                        if let summaryWordCount = entry.summaryWordCount {
                            HStack {
                                Text("Длина саммари:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(summaryWordCount) слов")
                            }
                        }
                        
                        if let compressionRatio = entry.compressionRatio {
                            HStack {
                                Text("Коэффициент сжатия:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.2f", compressionRatio))
                            }
                        }
                    }
                    .padding()
                    .cornerRadius(8)
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                if !entry.metadata.isEmpty {
                    Group {
                        Text("Метаданные")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(entry.metadata.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                                HStack {
                                    Text(key)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(value)
                                }
                            }
                        }
                        .padding()
                        //.background(Color(UIColor.systemBackground))
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Детали записи")
    }
}
