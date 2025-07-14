//
//  DatasetDownloader.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 27.06.2025.
//

import Foundation
import SwiftUI

/// Класс для загрузки датасетов из внешних источников через HuggingFace API
@MainActor
class DatasetDownloader: ObservableObject {
    /// Статус загрузки
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0.0
    @Published var statusMessage = ""
    @Published var errorMessage: String?
    
    init() {
        // Инициализация
    }
    
    /// Загрузка CNN/DailyMail датасета
    func downloadCNNDailyMailDataset(sampleSize: Int = DatasetConstants.mediumSampleSize) async -> Dataset? {
        return await downloadHuggingFaceDataset(
            name: "CNN/DailyMail",
            description: "Датасет новостных статей CNN и DailyMail с эталонными саммари",
            source: .cnnDailyMail,
            category: .news,
            huggingFaceId: "abisee/cnn_dailymail",
            config: "3.0.0",
            textField: "article",
            summaryField: "highlights",
            sampleSize: sampleSize
        )
    }
    
    /// Загрузка Reddit TIFU датасета
    func downloadRedditTIFUDataset(sampleSize: Int = DatasetConstants.mediumSampleSize) async -> Dataset? {
        return await downloadHuggingFaceDataset(
            name: "Reddit TIFU",
            description: "Датасет постов Reddit TIFU с краткими изложениями",
            source: .redditTIFU,
            category: .social,
            huggingFaceId: "reddit_tifu",
            config: "long",
            textField: "documents",
            summaryField: "tldr",
            sampleSize: sampleSize
        )
    }
    
    /// Загрузка Scientific Abstracts датасета
    func downloadScientificAbstractsDataset(sampleSize: Int = DatasetConstants.mediumSampleSize) async -> Dataset? {
        return await downloadHuggingFaceDataset(
            name: "Scientific Abstracts (PubMed)",
            description: "Датасет научных статей с абстрактами для суммаризации",
            source: .scientificAbstracts,
            category: .scientific,
            huggingFaceId: "abisee/cnn_dailymail",
            config: "3.0.0",
            textField: "article",
            summaryField: "highlights",
            sampleSize: sampleSize
        )
    }
    
    /// Загрузка ArXiv Papers датасета
    func downloadArXivDataset(sampleSize: Int = DatasetConstants.mediumSampleSize) async -> Dataset? {
        return await downloadHuggingFaceDataset(
            name: "ArXiv Papers",
            description: "Датасет научных статей ArXiv с абстрактами",
            source: .arxivPapers,
            category: .scientific,
            huggingFaceId: "EdinburghNLP/xsum",
            config: nil,
            textField: "document",
            summaryField: "summary",
            sampleSize: sampleSize
        )
    }
    
    /// Загрузка датасета с HuggingFace API
    private func downloadHuggingFaceDataset(
        name: String,
        description: String,
        source: Dataset.DatasetSource,
        category: Dataset.DatasetCategory,
        huggingFaceId: String,
        config: String? = nil,
        textField: String,
        summaryField: String,
        sampleSize: Int
    ) async -> Dataset? {
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0.0
            statusMessage = "Подготовка к загрузке \(name)..."
            errorMessage = nil
        }
        
        do {
            // Получаем информацию о датасете
            await MainActor.run {
                statusMessage = "Получение информации о датасете..."
                downloadProgress = 0.1
            }
            
            let datasetInfo = try await HuggingFaceAPI.fetchDatasetInfo(
                dataset: huggingFaceId,
                config: config
            )
            
            let trainSplit = datasetInfo.dataset_info.splits["train"]
            let numRows = trainSplit?.num_examples ?? 0
            
            print("📊 Информация о датасете \(name):")
            print("   - Всего записей: \(numRows)")
            print("   - Поля: \(datasetInfo.dataset_info.features.keys.joined(separator: ", "))")
            
            // Проверяем наличие необходимых полей
            guard datasetInfo.dataset_info.features[textField] != nil else {
                throw HuggingFaceError.fieldNotFound(textField)
            }
            guard datasetInfo.dataset_info.features[summaryField] != nil else {
                throw HuggingFaceError.fieldNotFound(summaryField)
            }
            
            await MainActor.run {
                statusMessage = "Загрузка данных..."
                downloadProgress = 0.3
            }
            
            // Загружаем данные порциями для больших датасетов
            var allEntries: [DatasetEntry] = []
            let batchSize = min(sampleSize, 100) // Загружаем максимум 100 записей за раз
            let totalBatches = (sampleSize + batchSize - 1) / batchSize
            
            for batchIndex in 0..<totalBatches {
                let offset = batchIndex * batchSize
                let length = min(batchSize, sampleSize - offset)
                
                if Task.isCancelled {
                    await MainActor.run {
                        isDownloading = false
                        statusMessage = "Загрузка отменена"
                    }
                    return nil
                }
                
                let response = try await HuggingFaceAPI.fetchDatasetRows(
                    dataset: huggingFaceId,
                    config: config,
                    offset: offset,
                    length: length
                )
                
                let entries = HuggingFaceAPI.convertToDatasetEntries(
                    from: response,
                    textField: textField,
                    summaryField: summaryField
                )
                
                allEntries.append(contentsOf: entries)
                
                let progress = 0.3 + (0.6 * Double(batchIndex + 1) / Double(totalBatches))
                await MainActor.run {
                    downloadProgress = progress
                    statusMessage = "Загружено \(allEntries.count) из \(sampleSize) записей..."
                }
                
                print("📥 Загружена порция \(batchIndex + 1)/\(totalBatches): \(entries.count) записей")
            }
            
            await MainActor.run {
                statusMessage = "Обработка данных..."
                downloadProgress = 0.9
            }
            
            // Ограничиваем количество записей до запрошенного размера
            let finalEntries = Array(allEntries.prefix(sampleSize))
            
            let dataset = Dataset(
                name: name,
                description: description,
                source: source,
                category: category,
                entries: finalEntries,
                metadata: [
                    "huggingface_id": huggingFaceId,
                    "config": config ?? "default",
                    "text_field": textField,
                    "summary_field": summaryField,
                    "sample_size": "\(finalEntries.count)",
                    "total_dataset_size": "\(numRows)",
                    "download_date": ISO8601DateFormatter().string(from: Date())
                ]
            )
            
            await MainActor.run {
                isDownloading = false
                statusMessage = "Загрузка \(name) завершена: \(finalEntries.count) записей"
                downloadProgress = 1.0
            }
            
            print("✅ Успешно загружен датасет \(name): \(finalEntries.count) записей")
            return dataset
            
        } catch {
            await MainActor.run {
                isDownloading = false
                errorMessage = "Ошибка загрузки \(name): \(error.localizedDescription)"
                statusMessage = "Ошибка загрузки"
            }
            
            print("❌ Ошибка загрузки датасета \(name): \(error)")
            return nil
        }
    }
    
    /// Отмена текущей загрузки
    func cancelDownload() {
        isDownloading = false
        statusMessage = "Загрузка отменена"
    }
}
