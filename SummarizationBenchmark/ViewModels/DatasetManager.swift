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
        
            datasets = loadedDatasets
            
            // Выбираем первый датасет, если он есть
            if let firstDataset = datasets.first {
                selectedDataset = firstDataset
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
    
    /// Создание демонстрационных датасетов
    public func createDemoDatasets() -> [Dataset] {
        var demoDatasets: [Dataset] = []
        
        // CNN/DailyMail демо датасет
        let cnnDemoEntries = [
            DatasetEntry(
                text: """
                (CNN) -- Imagine a skyscraper that cleans the air. You won't have to wait long -- two will soon be built in China.
                Italian architect Stefano Boeri announced plans to build a pair of towers in the southern Chinese city of Nanjing that will be covered in greenery to help regenerate local biodiversity and provide cleaner air for the community.
                The towers will be designed to absorb enough carbon dioxide to make 60 kg (132 lbs) of oxygen every day, a press release from Boeri's firm claimed.
                The buildings, which are scheduled to be completed in 2018, will stand at heights of 200 and 108 meters. They will hold 1,100 trees from 23 local species, as well as 2,500 cascading shrubs and plants.
                The project, called Nanjing Green Towers, is the architect's third vertical forest project, and the first in China. Two other similar structures can be found in Milan, Italy and Lausanne, Switzerland.
                """,
                referenceSummary: "Italian architect Stefano Boeri is building two towers in Nanjing, China, that will be covered in greenery to help regenerate local biodiversity and provide cleaner air. The towers will absorb carbon dioxide to produce 60 kg of oxygen daily and will contain 1,100 trees from 23 local species, plus 2,500 shrubs and plants.",
                metadata: ["source": "CNN", "category": "architecture", "date": "2017-02-08"]
            ),
            DatasetEntry(
                text: """
                (CNN) -- The world's biggest smartphone maker is trying to move past last year's disastrous Galaxy Note 7 launch with a successor sporting a dual-lens camera, animated messages, expanded note-taking -- and lower battery capacity.
                Samsung is no longer trying to squeeze more battery power into each phone. Last year's Note 7 had to be recalled after dozens spontaneously caught fire because of defective batteries.
                The South Korean company disclosed the battery in the new Note 8 holds 3,300 milliamp hours. That's still sizable, but slightly smaller than the Note 7, which started at 3,500 milliamp hours.
                """,
                referenceSummary: "Samsung is launching the Galaxy Note 8 with a dual-lens camera, animated messages, and expanded note-taking features. Following last year's Note 7 battery fires, the new phone has a slightly smaller 3,300 milliamp hour battery compared to the Note 7's 3,500 milliamp hours.",
                metadata: ["source": "CNN", "category": "technology", "date": "2017-08-23"]
            ),
            DatasetEntry(
                text: """
                (CNN) -- Authorities in Spain have confirmed they are investigating the fatal stabbing of a 36-year-old man as a possible anti-LGBT hate crime.
                Samuel Luiz, a nursing assistant, was beaten to death outside a nightclub in the northwestern city of A Coruña in the early hours of Saturday morning.
                A friend of Luiz, who claimed to have been with him at the time, told Spanish media that a man had attacked Luiz because he believed he was trying to record him on his phone.
                The man is alleged to have shouted "either stop recording or I'll kill you, fag," before hitting Luiz, according to the friend.
                """,
                referenceSummary: "Spanish authorities are investigating the fatal stabbing of 36-year-old nursing assistant Samuel Luiz as a possible anti-LGBT hate crime. Luiz was beaten to death outside a nightclub in A Coruña. According to a friend who was present, the attacker accused Luiz of recording him on his phone and threatened him with homophobic language before the assault.",
                metadata: ["source": "CNN", "category": "crime", "date": "2021-07-06"]
            )
        ]
        
        let cnnDemoDataset = Dataset(
            name: "CNN/DailyMail Demo",
            description: "Демонстрационный датасет на основе CNN/DailyMail для тестирования суммаризации новостных статей",
            source: .cnnDailyMail,
            category: .news,
            entries: cnnDemoEntries,
            metadata: [
                "url": DatasetConstants.cnnDailyMailURL,
                "sample_size": "\(cnnDemoEntries.count)",
                "full_dataset_size": "300,000+"
            ]
        )
        
        demoDatasets.append(cnnDemoDataset)
        
        // Reddit TIFU демо датасет
        let redditDemoEntries = [
            DatasetEntry(
                text: """
                So this happened a few days ago. I was at the gym doing my usual workout routine. I had just finished a set of bench presses and was taking a short break. I noticed this attractive girl working out nearby and we made eye contact a few times.
                
                After my break, I decided to do some dumbbell exercises. I picked up what I thought were my usual weights (25 lbs each) and started doing lateral raises. On the third rep, I felt something was off - the weights felt much heavier than usual. I looked down and realized I had accidentally grabbed 35 lb dumbbells instead!
                
                Not wanting to look weak in front of the cute girl, I tried to power through the set. Big mistake. On the fifth rep, my arms gave out and I dropped both dumbbells. One of them landed directly on my foot, and the other bounced and hit a nearby water bottle, sending water spraying everywhere.
                
                I was in pain, embarrassed, and now the center of attention in the gym. The cute girl came over to ask if I was okay, which only made me more embarrassed. I mumbled something about being fine and limped to the locker room with a bruised foot and an even more bruised ego.
                
                Now I'm icing my foot at home and have learned my lesson about gym vanity.
                """,
                referenceSummary: "I tried to impress a cute girl at the gym by lifting heavier dumbbells than usual. My arms gave out, I dropped the weights, injured my foot, and caused a scene when one dumbbell hit a water bottle and sprayed water everywhere.",
                metadata: ["source": "Reddit", "subreddit": "TIFU", "upvotes": "2.4k"]
            ),
            DatasetEntry(
                text: """
                This happened last week but I'm still dealing with the consequences. I'm a college student and I had a major paper due for my English Literature class. I had been working on it for weeks and was finally done with it - a 15-page analysis of Shakespearean themes in modern literature.
                
                The night before it was due, I decided to do one final review before submitting it online. I was working on my laptop while drinking some tea. You can probably see where this is going...
                
                I reached for my mug and accidentally knocked it over, spilling tea all over my laptop keyboard. I quickly turned it upside down and tried to dry it off, but it was too late. The laptop wouldn't turn on.
                
                I started panicking because I hadn't backed up my paper anywhere else - it was only saved locally on that laptop. I tried everything - rice trick, hair dryer on cool setting, waiting overnight - but nothing worked.
                
                I had to email my professor explaining the situation, but of course it sounds like the digital version of "my dog ate my homework." He gave me a 2-day extension, but I basically had to rewrite the entire paper from scratch, working from memory of what I had written before.
                
                I turned in the rewritten version, but it was nowhere near as good as my original. Just got my grade back - C minus. My GPA is definitely taking a hit this semester.
                
                TLDR: Always back up your work, and keep drinks far away from electronics.
                """,
                referenceSummary: "I spilled tea on my laptop the night before a major paper was due, destroying the device and losing my only copy of a 15-page literature analysis. Had to rewrite the entire paper from memory in two days and received a C minus grade.",
                metadata: ["source": "Reddit", "subreddit": "TIFU", "upvotes": "5.8k"]
            )
        ]
        
        let redditDemoDataset = Dataset(
            name: "Reddit TIFU Demo",
            description: "Демонстрационный датасет на основе Reddit TIFU для тестирования суммаризации неформальных текстов",
            source: .redditTIFU,
            category: .social,
            entries: redditDemoEntries,
            metadata: [
                "url": DatasetConstants.redditTIFUURL,
                "sample_size": "\(redditDemoEntries.count)",
                "full_dataset_size": "120,000+"
            ]
        )
        
        demoDatasets.append(redditDemoDataset)
        
        // Scientific Abstracts демо датасет
        let scientificDemoEntries = [
            DatasetEntry(
                text: """
                The rapid development of large language models (LLMs) has revolutionized natural language processing, enabling sophisticated text generation, translation, and understanding. However, the computational resources required for training and deploying these models present significant challenges for mobile and edge devices with limited memory and processing capabilities. In this paper, we introduce a novel approach for efficient LLM compression that maintains performance while drastically reducing model size. Our method combines quantization-aware training, knowledge distillation, and sparse attention mechanisms to create compact models suitable for resource-constrained environments. We evaluate our approach on standard benchmarks including GLUE, SQuAD, and MMLU, demonstrating that our compressed models retain 95% of the performance of their full-sized counterparts while requiring only 15% of the parameters. Furthermore, we present a case study deploying these models on mobile devices, showing real-time inference with minimal battery consumption. Our findings suggest that high-quality language understanding and generation can be achieved on edge devices without relying on cloud-based solutions, opening new possibilities for privacy-preserving AI applications.
                """,
                referenceSummary: "This paper presents a novel LLM compression approach combining quantization-aware training, knowledge distillation, and sparse attention mechanisms. The compressed models maintain 95% of original performance with only 15% of parameters, enabling efficient deployment on mobile devices with real-time inference and minimal battery usage, facilitating privacy-preserving AI applications.",
                metadata: ["domain": "Computer Science", "field": "Machine Learning", "year": "2024"]
            ),
            DatasetEntry(
                text: """
                Climate change poses an existential threat to coral reef ecosystems worldwide. Rising ocean temperatures have led to increased frequency and severity of coral bleaching events, while ocean acidification impairs calcium carbonate skeleton formation. This study presents a five-year longitudinal analysis of coral reef resilience factors across 35 sites in the Indo-Pacific region, identifying key ecological and environmental variables associated with recovery following mass bleaching events. We found that reefs with higher functional diversity, particularly herbivorous fish abundance, showed significantly greater recovery potential (p<0.001). Additionally, local management practices, such as marine protected areas with enforced fishing restrictions, correlated strongly with improved recovery metrics. Notably, we identified specific coral genotypes exhibiting enhanced thermal tolerance, suggesting potential targets for conservation prioritization. Our data indicate that while global climate action remains paramount, targeted local interventions can significantly enhance reef resilience. We propose an integrated management framework that combines protection of resistant coral populations, restoration using resilient genotypes, and local mitigation of non-climate stressors to maximize reef persistence through the coming decades of environmental change.
                """,
                referenceSummary: "This five-year study across 35 Indo-Pacific coral reef sites identifies key resilience factors against climate change impacts. Higher functional diversity, especially herbivorous fish abundance, significantly improved recovery after bleaching events. Marine protected areas with enforced fishing restrictions and specific thermally tolerant coral genotypes showed better outcomes. The research proposes an integrated management framework combining protection of resistant corals, restoration with resilient genotypes, and mitigation of non-climate stressors to enhance reef survival.",
                metadata: ["domain": "Marine Biology", "field": "Ecology", "year": "2023"]
            )
        ]
        
        let scientificDemoDataset = Dataset(
            name: "Scientific Abstracts Demo",
            description: "Демонстрационный датасет научных абстрактов для тестирования суммаризации академических текстов",
            source: .scientificAbstracts,
            category: .scientific,
            entries: scientificDemoEntries,
            metadata: [
                "url": DatasetConstants.scientificAbstractsURL,
                "sample_size": "\(scientificDemoEntries.count)",
                "full_dataset_size": "2,000,000+"
            ]
        )
        
        demoDatasets.append(scientificDemoDataset)
        
        return demoDatasets
    }
}
