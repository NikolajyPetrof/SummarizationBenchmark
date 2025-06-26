//
//  DatasetDownloader.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 27.06.2025.
//

import Foundation
import SwiftUI

/// Класс для загрузки датасетов из внешних источников
@MainActor
class DatasetDownloader: ObservableObject {
    /// Статус загрузки
    @Published var isDownloading = false
    
    /// Прогресс загрузки (0.0 - 1.0)
    @Published var downloadProgress: Double = 0.0
    
    /// Сообщение об ошибке
    @Published var errorMessage: String?
    
    /// Сообщение о статусе
    @Published var statusMessage: String = ""
    
    /// Загрузка CNN/DailyMail датасета
    func downloadCNNDailyMailDataset(sampleSize: Int = DatasetConstants.mediumSampleSize) async -> Dataset? {
        return await downloadDataset(
            name: "CNN/DailyMail",
            description: "Датасет новостных статей CNN и DailyMail с эталонными саммари",
            source: .cnnDailyMail,
            category: .news,
            url: DatasetConstants.cnnDailyMailURL,
            sampleSize: sampleSize
        )
    }
    
    /// Загрузка Reddit TIFU датасета
    func downloadRedditTIFUDataset(sampleSize: Int = DatasetConstants.mediumSampleSize) async -> Dataset? {
        return await downloadDataset(
            name: "Reddit TIFU",
            description: "Датасет постов из сабреддита TIFU (Today I F***ed Up) с эталонными саммари",
            source: .redditTIFU,
            category: .social,
            url: DatasetConstants.redditTIFUURL,
            sampleSize: sampleSize
        )
    }
    
    /// Загрузка Scientific Abstracts датасета
    func downloadScientificAbstractsDataset(sampleSize: Int = DatasetConstants.mediumSampleSize) async -> Dataset? {
        return await downloadDataset(
            name: "Scientific Abstracts",
            description: "Датасет научных абстрактов из различных областей с эталонными саммари",
            source: .scientificAbstracts,
            category: .scientific,
            url: DatasetConstants.scientificAbstractsURL,
            sampleSize: sampleSize
        )
    }
    
    /// Общий метод для загрузки датасета
    private func downloadDataset(
        name: String,
        description: String,
        source: Dataset.DatasetSource,
        category: Dataset.DatasetCategory,
        url: String,
        sampleSize: Int
    ) async -> Dataset? {
        await MainActor.run {
            isDownloading = true
            downloadProgress = 0.0
            statusMessage = "Подготовка к загрузке \(name)..."
            errorMessage = nil
        }
        
        // Здесь будет логика загрузки датасета из внешнего источника
        // В реальном приложении здесь будет API-запрос к Hugging Face или другому источнику
        
        // Симулируем загрузку для демонстрации
        for i in 1...10 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 секунды
            
            await MainActor.run {
                downloadProgress = Double(i) / 10.0
                statusMessage = "Загрузка \(name)... \(Int(downloadProgress * 100))%"
            }
            
            // Проверяем отмену задачи
            if Task.isCancelled {
                await MainActor.run {
                    isDownloading = false
                    statusMessage = "Загрузка отменена"
                }
                return nil
            }
        }
        
        await MainActor.run {
            statusMessage = "Обработка данных..."
        }
        
        // В реальном приложении здесь будет парсинг полученных данных
        // и создание объектов DatasetEntry
        
        // Для демонстрации создаем тестовые данные
        var entries: [DatasetEntry] = []
        
        // Генерируем случайные записи для демонстрации
        for i in 1...sampleSize {
            let entry = createDemoEntry(for: source, index: i)
            entries.append(entry)
        }
        
        let dataset = Dataset(
            name: "\(name) (\(sampleSize) samples)",
            description: description,
            source: source,
            category: category,
            entries: entries,
            metadata: [
                "url": url,
                "sample_size": "\(sampleSize)",
                "download_date": ISO8601DateFormatter().string(from: Date())
            ]
        )
        
        await MainActor.run {
            isDownloading = false
            statusMessage = "Загрузка \(name) завершена"
            downloadProgress = 1.0
        }
        
        return dataset
    }
    
    /// Создание демонстрационной записи для датасета
    private func createDemoEntry(for source: Dataset.DatasetSource, index: Int) -> DatasetEntry {
        switch source {
        case .cnnDailyMail:
            return createNewsEntry(index: index)
        case .redditTIFU:
            return createSocialEntry(index: index)
        case .scientificAbstracts:
            return createScientificEntry(index: index)
        case .custom:
            return createCustomEntry(index: index)
        }
    }
    
    /// Создание демонстрационной новостной записи
    private func createNewsEntry(index: Int) -> DatasetEntry {
        let headlines = [
            "Global Leaders Meet to Discuss Climate Change",
            "New Study Shows Benefits of Mediterranean Diet",
            "Tech Company Announces Revolutionary Product",
            "Scientists Discover New Species in Amazon Rainforest",
            "Stock Market Reaches All-Time High"
        ]
        
        let headline = headlines[index % headlines.count]
        let text = generateDemoText(length: 300 + (index * 20) % 700, topic: headline)
        let summary = generateDemoSummary(from: text)
        
        return DatasetEntry(
            text: text,
            referenceSummary: summary,
            metadata: [
                "source": "CNN/DailyMail",
                "category": "News",
                "index": "\(index)"
            ]
        )
    }
    
    /// Создание демонстрационной социальной записи
    private func createSocialEntry(index: Int) -> DatasetEntry {
        let topics = [
            "I accidentally sent an embarrassing message to my boss",
            "I forgot my anniversary and my partner is upset",
            "I broke my friend's expensive item",
            "I showed up to the wrong meeting location",
            "I accidentally deleted an important file"
        ]
        
        let topic = topics[index % topics.count]
        let text = generateDemoText(length: 400 + (index * 30) % 800, topic: topic)
        let summary = generateDemoSummary(from: text)
        
        return DatasetEntry(
            text: text,
            referenceSummary: summary,
            metadata: [
                "source": "Reddit",
                "category": "Social",
                "index": "\(index)"
            ]
        )
    }
    
    /// Создание демонстрационной научной записи
    private func createScientificEntry(index: Int) -> DatasetEntry {
        let topics = [
            "Advances in Quantum Computing",
            "Climate Change Effects on Marine Ecosystems",
            "Neural Networks in Natural Language Processing",
            "Genetic Factors in Autoimmune Diseases",
            "Dark Matter Detection Methods"
        ]
        
        let topic = topics[index % topics.count]
        let text = generateDemoText(length: 500 + (index * 40) % 1000, topic: topic)
        let summary = generateDemoSummary(from: text)
        
        return DatasetEntry(
            text: text,
            referenceSummary: summary,
            metadata: [
                "source": "Scientific Journals",
                "category": "Academic",
                "index": "\(index)"
            ]
        )
    }
    
    /// Создание демонстрационной пользовательской записи
    private func createCustomEntry(index: Int) -> DatasetEntry {
        let text = generateDemoText(length: 300 + (index * 25) % 600, topic: "Custom Topic \(index)")
        let summary = generateDemoSummary(from: text)
        
        return DatasetEntry(
            text: text,
            referenceSummary: summary,
            metadata: [
                "source": "Custom",
                "index": "\(index)"
            ]
        )
    }
    
    /// Генерация демонстрационного текста
    private func generateDemoText(length: Int, topic: String) -> String {
        // В реальном приложении здесь будет более сложная логика генерации текста
        // или использование реальных текстов из датасетов
        
        let sentences = [
            "This is a demonstration text for the summarization benchmark.",
            "The purpose of this text is to provide sample data for testing.",
            "Language models can be evaluated on their ability to summarize text.",
            "Summarization is an important task in natural language processing.",
            "Different models may produce different quality summaries.",
            "The quality of a summary can be measured using metrics like ROUGE.",
            "A good summary should capture the main points of the original text.",
            "Abstractive summarization involves generating new sentences.",
            "Extractive summarization involves selecting sentences from the original text.",
            "The length of a summary can vary depending on the requirements."
        ]
        
        var result = "Topic: \(topic)\n\n"
        var currentLength = result.count
        
        while currentLength < length {
            let sentence = sentences.randomElement() ?? sentences[0]
            result += sentence + " "
            currentLength = result.count
        }
        
        return result
    }
    
    /// Генерация демонстрационного саммари
    private func generateDemoSummary(from text: String) -> String {
        // В реальном приложении здесь будет более сложная логика генерации саммари
        // или использование реальных саммари из датасетов
        
        // Для демонстрации просто берем первое предложение и добавляем заключение
        let firstSentence = text.components(separatedBy: ".").first ?? ""
        return firstSentence + ". This is a demonstration summary for testing purposes."
    }
    
    /// Отмена текущей загрузки
    func cancelDownload() {
        // В реальном приложении здесь будет логика отмены сетевых запросов
        isDownloading = false
        statusMessage = "Загрузка отменена"
    }
}
