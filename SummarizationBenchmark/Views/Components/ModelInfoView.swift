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
    case california = "california"
    case president = "president"
    case gun = "gun"
    case penguin = "penguin"
    case harry = "harry"
    
    var title: String {
        switch self {
        case .climate: return "Climate Change"
        case .ai: return "Artificial Intelligence"
        case .brain: return "Human Brain"
        case .california: return "California"
        case .president: return "President"
        case .gun: return "Зимнее утро"
        case .penguin: return "Penguin"
        case .harry: return "Harry"
        }
    }
    
    var content: String {
        switch self {
        case .climate:
            return """
            The purpose of this text is to provide sample data for testing. A good summary should capture the main points of the original text. Summarization is an important task in natural language processing. The purpose of this text is to provide sample data for testing. Summarization is an important task in natural language processing. The length of a summary can vary depending on the requirements. Different models may produce different quality summaries. Summarization is an important task in natural language processing..
            """
        case .ai:
            return """
            Language models can be evaluated on their ability to summarize text. Summarization is an important task in natural language processing. The length of a summary can vary depending on the requirements. The quality of a summary can be measured using metrics like ROUGE. Summarization is an important task in natural language processing. The purpose of this text is to provide sample data for testing. The length of a summary can vary depending on the requirements. The quality of a summary can be measured using metrics like ROUGE. Abstractive summarization involves generating new sentences. Summarization is an important task in natural language processing. The purpose of this text is to provide sample data for testing. The length of a summary can vary depending on the requirements. A good summary should capture the main points of the original text. The length of a summary can vary depending on the requirements. Extractive summarization involves selecting sentences from the original text. The purpose of this text is to provide sample data for testing.
            """
        case .brain:
            return """
            The human brain is one of the most complex structures in the known universe, containing approximately 86 billion neurons interconnected through trillions of synapses. This intricate network enables consciousness, memory, learning, and all cognitive functions that define human experience. Recent advances in neuroscience have revealed fascinating insights into how the brain processes information, forms memories, and adapts through neuroplasticity. Researchers are using cutting-edge technologies like functional MRI, optogenetics, and brain-computer interfaces to unlock the mysteries of neural function. Studies have shown that the brain continues to change and adapt throughout life, challenging previous assumptions about fixed neural pathways. Understanding the brain better has profound implications for treating neurological disorders, developing artificial intelligence, and potentially enhancing human cognitive abilities through various interventions and technologies.
            """
        case .california:
            return """
            SAN FRANCISCO, California (CNN)  -- A magnitude 4.2 earthquake shook the San Francisco area Friday at 4:42 a.m. PT (7:42 a.m. ET), the U.S. Geological Survey reported. The quake left about 2,000 customers without power, said David Eisenhower, a spokesman for Pacific Gas and Light. Under the USGS classification, a magnitude 4.2 earthquake is considered "light," which it says usually causes minimal damage. "We had quite a spike in calls, mostly calls of inquiry, none of any injury, none of any damage that was reported," said Capt. Al Casciato of the San Francisco police. "It was fairly mild."  Watch police describe concerned calls immediately after the quake » . The quake was centered about two miles east-northeast of Oakland, at a depth of 3.6 miles, the USGS said. Oakland is just east of San Francisco, across San Francisco Bay. An Oakland police dispatcher told CNN the quake set off alarms at people's homes. The shaking lasted about 50 seconds, said CNN meteorologist Chad Myers. According to the USGS, magnitude 4.2 quakes are felt indoors and may break dishes and windows and overturn unstable objects. Pendulum clocks may stop. E-mail to a friend .
            """
        case .president:
            return """
            WASHINGTON (CNN) -- Vice President Dick Cheney will serve as acting president briefly Saturday while President Bush is anesthetized for a routine colonoscopy, White House spokesman Tony Snow said Friday. Bush is scheduled to have the medical procedure, expected to take about 2 1/2 hours, at the presidential retreat at Camp David, Maryland, Snow said. Bush's last colonoscopy was in June 2002, and no abnormalities were found, Snow said. The president's doctor had recommended a repeat procedure in about five years. The procedure will be supervised by Dr. Richard Tubb and conducted by a multidisciplinary team from the National Naval Medical Center in Bethesda, Maryland, Snow said. A colonoscopy is the most sensitive test for colon cancer, rectal cancer and polyps, small clumps of cells that can become cancerous, according to the Mayo Clinic. Small polyps may be removed during the procedure. Snow said that was the case when Bush had colonoscopies before becoming president. Snow himself is undergoing chemotherapy for cancer that began in his colon and spread to his liver. Snow told reporters he had a chemo session scheduled later Friday.  Watch Snow talk about Bush's procedure and his own colon cancer » . "The president wants to encourage everybody to use surveillance," Snow said. The American Cancer Society recommends that people without high-risk factors or symptoms begin getting screened for signs of colorectal cancer at age 50. E-mail to a friend .
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
        case .harry:
            return """
                LONDON, England (Reuters) -- Harry Potter star Daniel Radcliffe gains access to a reported £20 million ($41.1 million) fortune as he turns 18 on Monday, but he insists the money won't cast a spell on him. Daniel Radcliffe as Harry Potter in "Harry Potter and the Order of the Phoenix" To the disappointment of gossip columnists around the world, the young actor says he has no plans to fritter his cash away on fast cars, drink and celebrity parties. "I don't plan to be one of those people who, as soon as they turn 18, suddenly buy themselves a massive sports car collection or something similar," he told an Australian interviewer earlier this month. "I don't think I'll be particularly extravagant. "The things I like buying are things that cost about 10 pounds -- books and CDs and DVDs." At 18, Radcliffe will be able to gamble in a casino, buy a drink in a pub or see the horror film "Hostel: Part II," currently six places below his number one movie on the UK box office chart. Details of how he'll mark his landmark birthday are under wraps. His agent and publicist had no comment on his plans. "I'll definitely have some sort of party," he said in an interview. "Hopefully none of you will be reading about it." Radcliffe's earnings from the first five Potter films have been held in a trust fund which he has not been able to touch. Despite his growing fame and riches, the actor says he is keeping his feet firmly on the ground. "People are always looking to say 'kid star goes off the rails,'" he told reporters last month. "But I try very hard not to go that way because it would be too easy for them." His latest outing as the boy wizard in "Harry Potter and the Order of the Phoenix" is breaking records on both sides of the Atlantic and he will reprise the role in the last two films.  Watch I-Reporter give her review of Potter's latest » . There is life beyond Potter, however. The Londoner has filmed a TV movie called "My Boy Jack," about author Rudyard Kipling and his son, due for release later this year. He will also appear in "December Boys," an Australian film about four boys who escape an orphanage. Earlier this year, he made his stage debut playing a tortured teenager in Peter Shaffer's "Equus." Meanwhile, he is braced for even closer media scrutiny now that he's legally an adult: "I just think I'm going to be more sort of fair game," he told Reuters. E-mail to a friend . Copyright 2007 Reuters. All rights reserved.This material may not be published, broadcast, rewritten, or redistributed.
                """
        }
    }
    
    var wordCount: Int {
        content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }.count
    }
}
