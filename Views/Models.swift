//
//  Models.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 10.06.2025.
//

// NewSessionView.swift
struct NewSessionView: View {
    @ObservedObject var benchmarkVM: BenchmarkViewModel
    @State private var sessionName = ""
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            Text("New Benchmark Session")
                .font(.headline)
                .padding()
            
            TextField("Session Name", text: $sessionName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
            
            HStack {
                Button("Cancel") {
                    presentationMode.wrappedValue.dismiss()
                }
                
                Button("Create") {
                    benchmarkVM.startNewSession(name: sessionName)
                    presentationMode.wrappedValue.dismiss()
                }
                .disabled(sessionName.isEmpty)
            }
            .padding()
        }
        .frame(width: 300, height: 150)
    }
}

// SessionDetailView.swift
struct SessionDetailView: View {
    let session: BenchmarkSession
    
    var body: some View {
        VStack {
            Text(session.name)
                .font(.largeTitle)
                .padding()
            
            List(session.results) { result in
                VStack(alignment: .leading) {
                    Text(result.modelName)
                        .font(.headline)
                    Text("Time: \(String(format: "%.2f", result.metrics.inferenceTime))s")
                    Text("Speed: \(String(format: "%.1f", result.metrics.tokensPerSecond)) tok/s")
                }
                .padding(.vertical, 4)
            }
        }
    }
}
