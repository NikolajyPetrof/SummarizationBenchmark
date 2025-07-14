//
//  DatasetManager.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 27.06.2025.
//

import Foundation
import SwiftUI

/// Класс для управления датасетами
@MainActor
class DatasetManager: ObservableObject {
    /// Все доступные датасеты
    @Published var datasets: [Dataset] = []
    
    /// Выбранный датасет
    @Published var selectedDataset: Dataset?
    
    /// Статус загрузки
    @Published var isLoading = false
    
    /// Сообщение об ошибке
    @Published var errorMessage: String?
    
    /// Путь к директории с датасетами
    private let datasetsDirectory: URL
    
    /// Инициализация менеджера датасетов
    init() {
        // Получаем URL директории документов
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        
        // Создаем директорию для датасетов, если она не существует
        self.datasetsDirectory = documentsDirectory.appendingPathComponent("Datasets")
        
        do {
            try FileManager.default.createDirectory(at: datasetsDirectory, withIntermediateDirectories: true)
            loadDatasets()
        } catch {
            errorMessage = "Ошибка при создании директории датасетов: \(error.localizedDescription)"
        }
    }
    
    /// Загрузка всех доступных датасетов
    func loadDatasets() {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Получаем список файлов в директории датасетов
            let fileURLs = try FileManager.default.contentsOfDirectory(at: datasetsDirectory, includingPropertiesForKeys: nil)
            
            // Фильтруем только JSON файлы
            let jsonFiles = fileURLs.filter { $0.pathExtension == "json" }
            
            // Загружаем каждый датасет
            var loadedDatasets: [Dataset] = []
            
            for fileURL in jsonFiles {
                do {
                    let data = try Data(contentsOf: fileURL)
                    let decoder = JSONDecoder()
                    let dataset = try decoder.decode(Dataset.self, from: data)
                    loadedDatasets.append(dataset)
                } catch {
                    print("Ошибка при загрузке датасета \(fileURL.lastPathComponent): \(error.localizedDescription)")
                }
            }
        
            // Если нет загруженных датасетов, показываем пустой список
            if loadedDatasets.isEmpty {
                print("📝 Датасеты не найдены.")
                datasets = []
            } else {
                datasets = loadedDatasets
                // Выбираем первый датасет, если он есть
                if let firstDataset = datasets.first {
                    selectedDataset = firstDataset
                }
            }
        } catch {
            errorMessage = "Ошибка при загрузке датасетов: \(error.localizedDescription)"
        }
    }
    
    /// Сохранение датасета
    func saveDataset(_ dataset: Dataset) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(dataset)
            
            let fileURL = datasetsDirectory.appendingPathComponent("\(dataset.name).json")
            try data.write(to: fileURL)
        } catch {
            errorMessage = "Ошибка при сохранении датасета: \(error.localizedDescription)"
        }
    }
    
    /// Удаление датасета
    func deleteDataset(_ dataset: Dataset) {
        do {
            let fileURL = datasetsDirectory.appendingPathComponent("\(dataset.name).json")
            try FileManager.default.removeItem(at: fileURL)
            
            // Удаляем датасет из списка
            datasets.removeAll { $0.name == dataset.name }
            
            // Если удаленный датасет был выбран, выбираем первый из оставшихся
            if selectedDataset?.name == dataset.name {
                selectedDataset = datasets.first
            }
        } catch {
            errorMessage = "Ошибка при удалении датасета: \(error.localizedDescription)"
        }
    }
    
}
