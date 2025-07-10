//
//  ModelInfoView.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.07.2025.
//

import SwiftUI

struct ModelInfoView: View {
    let result: BenchmarkResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Model Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 4) {
                InfoRow(label: "Model:", value: result.modelName)
                InfoRow(label: "Timestamp:", value: DateFormatter.localizedString(from: result.timestamp, dateStyle: .short, timeStyle: .medium))
                InfoRow(label: "Input Length:", value: "\(result.inputText.count) characters")
                InfoRow(label: "Summary Length:", value: "\(result.metrics.summaryLength) characters")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

// MARK: - Info Row
struct InfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .bold()
        }
        .font(.caption)
    }
}

// MARK: - Text Presets
enum TextPreset: String, CaseIterable {
    case climate = "climate"
    case ai = "ai"
    case brain = "brain"
    case economics = "economics"
    case space = "space"
    case gun = "gun"
    case penguin = "penguin"
    case darkMatter = "darkMatter"
    
    var title: String {
        switch self {
        case .climate: return "Climate Change"
        case .ai: return "Artificial Intelligence"
        case .brain: return "Human Brain"
        case .economics: return "Global Economics"
        case .space: return "Space Exploration"
        case .gun: return "Зимнее утро"
        case .penguin: return "Penguin"
        case .darkMatter: return "Dark Matter"
        }
    }
    
    var content: String {
        switch self {
        case .climate:
            return """
            Climate change is one of the most pressing challenges facing humanity today. Rising global temperatures, largely driven by human activities such as burning fossil fuels and deforestation, are causing widespread environmental disruptions. These include melting ice caps, rising sea levels, more frequent extreme weather events, and shifts in precipitation patterns. The impacts are not just environmental but also social and economic, affecting agriculture, water resources, human health, and infrastructure. Scientists worldwide are studying these effects and developing models to predict future scenarios. Addressing climate change requires urgent global action, including transitioning to renewable energy sources, improving energy efficiency, protecting and restoring forests, and implementing policies that reduce greenhouse gas emissions. International cooperation through agreements like the Paris Climate Accord is essential for coordinating efforts across nations.
            """
        case .ai:
            return """
            Artificial intelligence has revolutionized numerous industries and aspects of daily life. From healthcare diagnostics to autonomous vehicles, from personalized recommendations to smart home systems, AI technologies are becoming increasingly integrated into our world. Machine learning algorithms can now process vast amounts of data to identify patterns and make predictions that would be impossible for humans to achieve manually. Deep learning networks have achieved remarkable breakthroughs in image recognition, natural language processing, and game playing. However, this rapid advancement also raises important questions about privacy, job displacement, algorithmic bias, and the need for responsible AI development. As we continue to advance these technologies, it's crucial to balance innovation with ethical considerations and ensure that AI benefits all of humanity while minimizing potential risks and negative consequences.
            """
        case .brain:
            return """
            The human brain is one of the most complex structures in the known universe, containing approximately 86 billion neurons interconnected through trillions of synapses. This intricate network enables consciousness, memory, learning, and all cognitive functions that define human experience. Recent advances in neuroscience have revealed fascinating insights into how the brain processes information, forms memories, and adapts through neuroplasticity. Researchers are using cutting-edge technologies like functional MRI, optogenetics, and brain-computer interfaces to unlock the mysteries of neural function. Studies have shown that the brain continues to change and adapt throughout life, challenging previous assumptions about fixed neural pathways. Understanding the brain better has profound implications for treating neurological disorders, developing artificial intelligence, and potentially enhancing human cognitive abilities through various interventions and technologies.
            """
        case .economics:
            return """
            The global economy is a complex interconnected system that affects billions of people worldwide. Economic policies, trade relationships, and market dynamics influence everything from employment rates to the cost of everyday goods. In recent years, we've seen significant shifts due to technological advancement, changing demographics, and global events. Digital currencies and blockchain technology are challenging traditional financial systems, while automation is transforming labor markets. Income inequality has become a major concern in many developed nations, leading to discussions about universal basic income and progressive taxation. International trade agreements and tariffs continue to shape global commerce, while emerging markets play increasingly important roles in the world economy. Understanding these economic forces is crucial for governments, businesses, and individuals making financial decisions in an interconnected world.
            """
        case .space:
            return """
            Space exploration represents humanity's greatest adventure and scientific endeavor. From the first human steps on the Moon to robotic missions exploring Mars and the outer planets, space exploration has expanded our understanding of the universe and our place within it. Modern space programs involve international cooperation, with the International Space Station serving as a symbol of what nations can achieve together. Private companies like SpaceX and Blue Origin are revolutionizing space travel with reusable rockets and ambitious plans for Mars colonization. Scientific discoveries from space missions have led to countless technological innovations that benefit life on Earth, from satellite communications to medical imaging technologies. As we look to the future, missions to Mars, asteroid mining, and the search for extraterrestrial life promise to open new frontiers for human civilization and scientific discovery.
            """
        case .gun:
            return """
                Мороз и солнце; день чудесный!
                Еще ты дремлешь, друг прелестный —
                Пора, красавица, проснись:
                Открой сомкнуты негой взоры
                Навстречу северной Авроры,
                Звездою севера явись!
                Вечор, ты помнишь, вьюга злилась,
                На мутном небе мгла носилась;
                Луна, как бледное пятно,
                Сквозь тучи мрачные желтела,
                И ты печальная сидела —
                А нынче… погляди в окно:
                Под голубыми небесами
                Великолепными коврами,
                Блестя на солнце, снег лежит;
                Прозрачный лес один чернеет,
                И ель сквозь иней зеленеет,
                И речка подо льдом блестит.
                Вся комната янтарным блеском
                Озарена. Веселым треском
                Трещит затопленная печь.
                Приятно думать у лежанки.
                Но знаешь: не велеть ли в санки
                Кобылку бурую запречь?
                Скользя по утреннему снегу,
                Друг милый, предадимся бегу
                Нетерпеливого коня
                И навестим поля пустые,
                Леса, недавно столь густые,
                И берег, милый для меня.
                """
        case .penguin:
            return """
                Пингвин — птица, которая не летает. Зато все 18 видов этого семейства отлично плавают и ныряют — благодаря обтекаемой форме тела и устройству костей крыльев.

                Императорских пингвинов в Антарктиде живет так много, что их колонии видны из космоса! Это помогает ученым изучать птиц, считать их, следить за передвиженями.

                «Эффектом пингвина» называют такое поведение, когда ни один человек (или пингвин!) на берегу не хочет первым заходить в воду. Может быть, потому, что она холодная, или просто нет настроения. Но пингвины делают именно так: подталкивают друг друга, отходят как бы нерешительно, снова приближаются к воде — до тех пор, пока кто-то из них не спрыгнет в воду первым. Такое поведение — природный механизм, ведь в естественных условиях жизни пингвин, первым прыгнувший в воду, рискует быть съеденным хищником.

                Пингвины пьют морскую воду (или глотают ее во время охоты за рыбой). Для них это безопасно, потому что с помощью особой надглазной железы соль отфильтровывается из организма птицы. Соленая вода потом выделяется через клюв во время чихания.

                Пингвины питаются морепродуктами. Рыбу, кальмаров и креветок они ловят во время ныряния, но пищу не жуют — зубов у пингвина нет, он же птица! Зато у него в пасти особые шипы, которые помогают еде отправляться прямо в глотку.

                Раз в год пингвины линяют. Линька происходит обычно весной: «зимнее», старое оперение пингвин меняет на новое, сбрасывая практически все перья! От трёх до четырёх недель, пока новое оперение отрастает, пингвин выглядит как пушистый серо-коричневый шарик. У нового пуха еще некоторое время нет водоотталкивающих свойств, поэтому плавать пингвин в это время не может.
                """
        case .darkMatter:
            return """
                Topic: Dark Matter Detection Methods
                The purpose of this text is to provide sample data for testing. Language models can be evaluated on their ability to summarize text. Different models may produce different quality summaries. Summarization is an important task in natural language processing. Summarization is an important task in natural language processing. The quality of a summary can be measured using metrics like ROUGE. Abstractive summarization involves generating new sentences. Abstractive summarization involves generating new sentences. Abstractive summarization involves generating new sentences. Different models may produce different quality summaries. Different models may produce different quality summaries. The length of a summary can vary depending on the requirements. Different models may produce different quality summaries. Summarization is an important task in natural language processing. Abstractive summarization involves generating new sentences. This is a demonstration text for the summarization benchmark. This is a demonstration text for the summarization benchmark. The length of a summary can vary depending on the requirements. This is a demonstration text for the summarization benchmark. Summarization is an important task in natural language processing. The quality of a summary can be measured using metrics like ROUGE. Extractive summarization involves selecting sentences from the original text. Different models may produce different quality summaries.
                """
        }
    }
    
    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
}
