//
//  DatasetConstants.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 27.06.2025.
//

import Foundation

/// Константы для работы с датасетами
enum DatasetConstants {
    /// URL для CNN/DailyMail датасета
    static let cnnDailyMailURL = "https://huggingface.co/datasets/cnn_dailymail"
    
    /// URL для Reddit TIFU датасета
    static let redditTIFUURL = "https://huggingface.co/datasets/reddit_tifu"
    
    /// URL для Scientific Abstracts датасета
    static let scientificAbstractsURL = "https://huggingface.co/datasets/scientific_papers"
    
    /// Стандартные размеры выборок для тестирования
    static let smallSampleSize = 10
    static let mediumSampleSize = 50
    static let largeSampleSize = 100
    
    /// Максимальная длина входного текста для различных тестов
    static let shortTextLength = 500   // слов
    static let mediumTextLength = 1000 // слов
    static let longTextLength = 2000   // слов
    
    /// Пути к локальным файлам датасетов
    static func localDatasetPath(for name: String) -> URL? {
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return documentsDirectory?.appendingPathComponent("Datasets/\(name).json")
    }
}
