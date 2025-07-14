//
//  PasteboardHelper.swift
//  SummarizationBenchmark
//
//  Created by Nikolay Petrov on 27.06.2025.
//

import Foundation

#if os(macOS)
import AppKit
#elseif os(iOS)
import UIKit
#endif

struct PasteboardHelper {
    
    /// Копирует текст в буфер обмена
    static func copyToClipboard(_ text: String) {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        #elseif os(iOS)
        UIPasteboard.general.string = text
        #endif
    }
    
    /// Получает текст из буфера обмена
    static func getFromClipboard() -> String? {
        #if os(macOS)
        return NSPasteboard.general.string(forType: .string)
        #elseif os(iOS)
        return UIPasteboard.general.string
        #endif
    }
}
