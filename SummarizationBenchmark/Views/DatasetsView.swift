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
            VStack(spacing: 0) {
                // Add button at the top
                HStack {
                    Spacer()
                    Button(action: { isShowingAddSheet = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Add Dataset")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.accentColor)
                        .cornerRadius(25)
                        .shadow(color: Color.accentColor.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                Divider()
                
                if datasetManager.datasets.isEmpty {
                    emptyStateView
                } else {
                    datasetListView
                }
            }
            .navigationTitle("Datasets")
            .sheet(isPresented: $isShowingAddSheet) {
                addDatasetView
            }

            .alert("Error", isPresented: .constant(datasetManager.errorMessage != nil)) {
                Button("OK") {
                    datasetManager.errorMessage = nil
                }
            } message: {
                Text(datasetManager.errorMessage ?? "")
            }
        }
    }
    
    // Empty state view
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            Text("No Datasets")
                .font(.title)
                .fontWeight(.medium)
            
            Text("Use the button above to add a dataset for model testing")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // Dataset list view
    private var datasetListView: some View {
        List {
            ForEach(datasetManager.datasets) { dataset in
                NavigationLink(destination: datasetDetailView(dataset)) {
                    datasetRow(dataset)
                }
            }
            .onDelete(perform: deleteDatasets)
        }
    }
    
    // Dataset row view
    private func datasetRow(_ dataset: Dataset) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(dataset.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(dataset.entries.count) entries")
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
    
    // Add dataset view
    private var addDatasetView: some View {
        NavigationStack {
            Form {
                Section(header: Text("Dataset Type")) {
                    Picker("Source", selection: $selectedDatasetType) {
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
                
                Section(header: Text("Examples")) {
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
            .navigationTitle("Dataset Details")
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
    
    // Load selected dataset
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
                // Custom datasets need separate logic
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
    
    // Delete datasets
    private func deleteDatasets(at offsets: IndexSet) {
        for index in offsets {
            let dataset = datasetManager.datasets[index]
            datasetManager.deleteDataset(dataset)
        }
    }
    
    // Get icon for dataset source
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
    
    // Get icon for dataset category
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
    
    // Get description for dataset type
    private func datasetDescription(for source: Dataset.DatasetSource) -> String {
        switch source {
        case .cnnDailyMail:
            return "The CNN/DailyMail dataset contains news articles and their summaries. It's one of the most popular datasets for text summarization tasks. The articles cover various topics: politics, technology, science, sports, etc."
        case .redditTIFU:
            return "The Reddit TIFU dataset contains posts from the 'Today I F***ed Up' subreddit, where users share their failures and mistakes. Each post has a brief summary (TL;DR) written by the author."
        case .scientificAbstracts:
            return "The Scientific Abstracts dataset contains scientific abstracts from various fields. Each abstract is accompanied by a summary that briefly describes the main research findings."
        case .custom:
            return "Custom dataset allows you to upload your own texts and summaries for testing summarization models."
        }
    }
}

// View for displaying dataset entry details
struct EntryDetailView: View {
    let entry: DatasetEntry
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("Source Text")
                        .font(.headline)
                    
                    Text(entry.text)
                        .font(.body)
                        .padding()
                        .cornerRadius(8)
                        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                
                if let summary = entry.referenceSummary {
                    Group {
                        Text("Reference Summary")
                            .font(.headline)
                        
                        Text(summary)
                            .font(.body)
                            .padding()
                            .cornerRadius(8)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
                
                Group {
                    Text("Statistics")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Text Length:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(entry.characterCount) characters")
                        }
                        
                        HStack {
                            Text("Word Count:")
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(entry.wordCount) words")
                        }
                        
                        if let summaryWordCount = entry.summaryWordCount {
                            HStack {
                                Text("Summary Length:")
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(summaryWordCount) words")
                            }
                        }
                        
                        if let compressionRatio = entry.compressionRatio {
                            HStack {
                                Text("Compression Ratio:")
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
                        Text("Metadata")
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
        .navigationTitle("Entry Details")
    }
}
