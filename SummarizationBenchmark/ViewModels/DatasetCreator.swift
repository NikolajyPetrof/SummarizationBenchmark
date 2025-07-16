import Foundation

/// Вспомогательный класс для создания демонстрационных датасетов
class DatasetCreator {
    
    /// Создать демонстрационный датасет научных абстрактов
    static func createScientificAbstractsDemo() -> Dataset {
        let entries = [
            DatasetEntry(
                id: UUID(),
                text: """
                Recent advances in artificial intelligence have led to the development of large language models (LLMs) capable of generating human-like text. These models, trained on vast corpora of text data, have demonstrated remarkable abilities in various natural language processing tasks. However, their deployment raises significant ethical concerns, including potential biases, misinformation propagation, and privacy issues. This paper examines the ethical implications of LLMs, focusing on fairness, accountability, transparency, and safety. We propose a framework for responsible AI development that addresses these concerns while enabling continued innovation in the field.
                """,
                referenceSummary: "This paper explores ethical concerns surrounding large language models, including bias and misinformation, and proposes a framework for responsible AI development.",
                metadata: ["domain": "AI Ethics", "year": "2025"]
            ),
            DatasetEntry(
                id: UUID(),
                text: """
                Climate change presents one of the most significant challenges of our time, with far-reaching implications for ecosystems, economies, and human societies. This study synthesizes recent findings on climate change mitigation strategies, focusing on renewable energy transitions, carbon capture technologies, and policy frameworks. Our analysis reveals that while technological solutions are advancing rapidly, implementation at scale requires coordinated policy actions and substantial investments. We identify key barriers to adoption and propose a multi-faceted approach that combines technological innovation, policy reform, and behavioral changes to address the climate crisis effectively.
                """,
                referenceSummary: "This study examines climate change mitigation strategies, highlighting the need for coordinated policy actions alongside technological solutions to address the climate crisis.",
                metadata: ["domain": "Climate Science", "year": "2025"]
            ),
            DatasetEntry(
                id: UUID(),
                text: """
                Quantum computing represents a paradigm shift in computational capabilities, leveraging quantum mechanical phenomena to perform operations on data. This paper reviews recent experimental advances in quantum computing hardware, focusing on superconducting qubits, trapped ions, and photonic systems. We evaluate the current state of quantum error correction, quantum algorithm development, and potential applications in cryptography, materials science, and drug discovery. While significant technical challenges remain, our analysis suggests that quantum advantage for specific problems may be achievable within the next decade, potentially revolutionizing fields that rely on computational modeling and simulation.
                """,
                referenceSummary: "This paper reviews advances in quantum computing hardware and applications, suggesting that quantum advantage for specific problems may be achievable within a decade.",
                metadata: ["domain": "Quantum Computing", "year": "2025"]
            )
        ]
        
        return Dataset(
            id: UUID(),
            name: "Scientific Abstracts Demo",
            description: "A demonstration dataset containing scientific abstracts from various domains",
            source: .scientificAbstracts,
            category: .scientific,
            entries: entries,
            metadata: ["version": "1.0", "created": "2025-07-14"]
        )
    }
    
    /// Создать демонстрационный датасет новостей
    static func createNewsDemo() -> Dataset {
        let entries = [
            DatasetEntry(
                id: UUID(),
                text: """
                The European Space Agency (ESA) announced today the successful launch of its new Mars rover mission, designed to search for signs of past or present life on the Red Planet. The rover, equipped with advanced scientific instruments including a drill capable of reaching depths of up to two meters, will explore regions believed to have once contained liquid water. "This mission represents a significant step forward in our understanding of Mars and its potential to harbor life," said ESA Director General in a press conference. The mission is expected to last at least two Earth years, with the possibility of extension depending on the rover's performance and scientific discoveries.
                """,
                referenceSummary: "ESA launched a new Mars rover mission to search for signs of life, equipped with instruments including a two-meter drill to explore regions that may have contained water.",
                metadata: ["category": "Space Exploration", "source": "ESA Press Release"]
            ),
            DatasetEntry(
                id: UUID(),
                text: """
                A breakthrough in renewable energy storage was announced yesterday by researchers at the National Renewable Energy Laboratory. The team has developed a new type of battery that can store solar and wind energy for extended periods at a fraction of the current cost. The technology uses abundant, non-toxic materials and can be scaled for both residential and utility applications. "This could be the missing piece in the renewable energy puzzle," said the lead researcher. "It addresses the intermittency issue that has long been a challenge for widespread adoption of renewable energy sources." Industry analysts suggest the technology could accelerate the transition away from fossil fuels if it can be commercialized successfully.
                """,
                referenceSummary: "Researchers developed a new battery technology that stores renewable energy longer and cheaper, using abundant materials and scalable for various applications.",
                metadata: ["category": "Renewable Energy", "source": "NREL"]
            )
        ]
        
        return Dataset(
            id: UUID(),
            name: "News Demo",
            description: "A demonstration dataset containing news articles",
            source: .cnnDailyMail,
            category: .news,
            entries: entries,
            metadata: ["version": "1.0", "created": "2025-07-14"]
        )
    }
    
    /// Создать и сохранить демонстрационные датасеты
    static func createAndSaveDemo(to directory: URL) throws {
        let scientificDemo = createScientificAbstractsDemo()
        let newsDemo = createNewsDemo()
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        
        // Сохраняем научный датасет
        let scientificData = try encoder.encode(scientificDemo)
        try scientificData.write(to: directory.appendingPathComponent("\(scientificDemo.name).json"))
        
        // Сохраняем новостной датасет
        let newsData = try encoder.encode(newsDemo)
        try newsData.write(to: directory.appendingPathComponent("\(newsDemo.name).json"))
    }
}
