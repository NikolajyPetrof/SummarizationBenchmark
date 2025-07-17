//
//  HuggingFaceAPI.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 14.07.2025.
//

import Foundation

/// Client for working with HuggingFace Datasets API
class HuggingFaceAPI {
    
    /// Base URL for HuggingFace Datasets API
    private static let baseURL = "https://datasets-server.huggingface.co"
    
    /// Structure for dataset information
    struct DatasetInfo: Codable {
        let dataset_info: DatasetInfoDetails
        let partial: Bool
        
        struct DatasetInfoDetails: Codable {
            let dataset_name: String
            let config_name: String
            let features: [String: Feature]
            let splits: [String: SplitInfo]
            
            struct Feature: Codable {
                let dtype: String
                let _type: String
            }
            
            struct SplitInfo: Codable {
                let name: String
                let num_examples: Int
                let num_bytes: Int
            }
        }
    }
    
    /// Structure for API response with dataset data
    struct DatasetResponse: Codable {
        let features: [FeatureInfo]
        let rows: [DatasetRow]
        let num_rows_total: Int?
        let num_rows_per_page: Int?
        let partial: Bool?
        
        struct FeatureInfo: Codable {
            let feature_idx: Int
            let name: String
            let type: FeatureType
            
            struct FeatureType: Codable {
                let dtype: String
                let _type: String
            }
        }
        
        struct DatasetRow: Codable {
            let row_idx: Int
            let row: [String: DatasetValue]
            let truncated_cells: [String]
        }
    }
    
    /// Universal value for dataset data
    enum DatasetValue: Codable {
        case string(String)
        case array([String])
        case null
        
        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            
            if container.decodeNil() {
                self = .null
            } else if let stringValue = try? container.decode(String.self) {
                self = .string(stringValue)
            } else if let arrayValue = try? container.decode([String].self) {
                self = .array(arrayValue)
            } else {
                // Try to decode any other value as a string
                let stringValue = try container.decode(String.self)
                self = .string(stringValue)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .string(let value):
                try container.encode(value)
            case .array(let value):
                try container.encode(value)
            case .null:
                try container.encodeNil()
            }
        }
        
        var stringValue: String? {
            switch self {
            case .string(let value):
                return value
            case .array(let values):
                return values.joined(separator: " ")
            case .null:
                return nil
            }
        }
    }
    
    /// Load dataset information
    static func fetchDatasetInfo(dataset: String, config: String? = nil, split: String = "train") async throws -> DatasetInfo {
        var urlComponents = URLComponents(string: "\(baseURL)/info")!
        urlComponents.queryItems = [
            URLQueryItem(name: "dataset", value: dataset),
            URLQueryItem(name: "split", value: split)
        ]
        
        if let config = config {
            urlComponents.queryItems?.append(URLQueryItem(name: "config", value: config))
        }
        
        guard let url = urlComponents.url else {
            throw HuggingFaceError.invalidURL
        }
        
        print("🔍 Requesting dataset info: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HuggingFaceError.invalidResponse
        }
        
        print("📡 HTTP status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "не удалось декодировать"
            print("❌ HTTP error \(httpResponse.statusCode): \(responseString)")
            throw HuggingFaceError.httpError(httpResponse.statusCode)
        }
        
        do {
            let datasetInfo = try JSONDecoder().decode(DatasetInfo.self, from: data)
            return datasetInfo
        } catch {
            print("❌ Error decoding DatasetInfo: \(error)")
            print("📄 Response data: \(String(data: data, encoding: .utf8) ?? "failed to decode")")
            throw HuggingFaceError.decodingError(error)
        }
    }
    
    /// Load dataset rows
    static func fetchDatasetRows(
        dataset: String,
        config: String? = nil,
        split: String = "train",
        offset: Int = 0,
        length: Int = 100
    ) async throws -> DatasetResponse {
        var urlComponents = URLComponents(string: "\(baseURL)/rows")!
        urlComponents.queryItems = [
            URLQueryItem(name: "dataset", value: dataset),
            URLQueryItem(name: "split", value: split),
            URLQueryItem(name: "offset", value: String(offset)),
            URLQueryItem(name: "length", value: String(length))
        ]
        
        if let config = config {
            urlComponents.queryItems?.append(URLQueryItem(name: "config", value: config))
        }
        
        guard let url = urlComponents.url else {
            throw HuggingFaceError.invalidURL
        }
        
        print("🔍 Requesting dataset data: \(url.absoluteString)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw HuggingFaceError.invalidResponse
        }
        
        print("📡 HTTP status (data): \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let responseString = String(data: data, encoding: .utf8) ?? "не удалось декодировать"
            print("❌ HTTP error (data) \(httpResponse.statusCode): \(responseString)")
            throw HuggingFaceError.httpError(httpResponse.statusCode)
        }
        
        do {
            let datasetResponse = try JSONDecoder().decode(DatasetResponse.self, from: data)
            return datasetResponse
        } catch {
            print("❌ Error decoding DatasetResponse: \(error)")
            print("📄 Response data (data): \(String(data: data, encoding: .utf8) ?? "failed to decode")")
            throw HuggingFaceError.decodingError(error)
        }
    }
    
    /// Convert HuggingFace data to DatasetEntry
    static func convertToDatasetEntries(
        from response: DatasetResponse,
        textField: String,
        summaryField: String
    ) -> [DatasetEntry] {
        return response.rows.compactMap { row in
            guard let text = row.row[textField]?.stringValue,
                  let summary = row.row[summaryField]?.stringValue,
                  !text.isEmpty, !summary.isEmpty else {
                return nil
            }
            
            // Create metadata from available fields
            var metadata: [String: String] = [:]
            for (key, value) in row.row {
                if key != textField && key != summaryField,
                   let stringValue = value.stringValue {
                    metadata[key] = stringValue
                }
            }
            metadata["row_idx"] = String(row.row_idx)
            
            return DatasetEntry(
                text: text,
                referenceSummary: summary,
                metadata: metadata
            )
        }
    }
}

/// HuggingFace API Errors
enum HuggingFaceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case datasetNotFound
    case fieldNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL for HuggingFace API request"
        case .invalidResponse:
            return "Invalid response from HuggingFace API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Data decoding error: \(error.localizedDescription)"
        case .datasetNotFound:
            return "Dataset not found"
        case .fieldNotFound(let field):
            return "Field '\(field)' not found in dataset"
        }
    }
}
