//
//  ContentView.swift
//  kfdfun
//
//  Created by Mineek on 07/01/2024.
//

import SwiftUI

struct ContentView: View {
    var pipe = Pipe()
    @State var logItems: [String] = []
    
    public func openConsolePipe() {
        setvbuf(stdout, nil, _IONBF, 0)
        dup2(pipe.fileHandleForWriting.fileDescriptor,
             STDOUT_FILENO)
        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            let str = String(data: data, encoding: .ascii) ?? "[i] <Non-ascii data of size\(data.count)>\n"
            DispatchQueue.main.async {
                logItems.append(str)
            }
        }
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                ScrollView {
                    LazyVStack(alignment: .leading) {
                        ScrollViewReader { value in
                            ForEach(logItems, id: \.self) { log in
                                Text(log)
                                    .id(log)
                                    .multilineTextAlignment(.leading)
                                    .frame(width: geo.size.width - 50, alignment: .leading)
                            }
                            .font(.system(.body, design: .monospaced))
                            .multilineTextAlignment(.leading)
                            .onChange(of: logItems.count) { new in
                                value.scrollTo(logItems[new - 1])
                            }
                        }
                    }
                    .padding(.bottom, 15)
                    .padding()
                }
                Button("kfdfun") {
                    do_all(2)
                }
            }
        }
        .padding()
        .onAppear {
            openConsolePipe()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
