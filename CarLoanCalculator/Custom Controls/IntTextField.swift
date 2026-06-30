//
//  IntTextField.swift
//  CarLoanCalculator
//
//  Created by Kenny Mann on 6/30/26.
//

import SwiftUI

struct IntTextField: View {
    @Binding var value: Int

    @FocusState private var isFocused: Bool

    let name: String

    @State private var previousValue: Int
    @State private var text: String = ""
   
    init(name: String, value: Binding<Int>) {
        self.name = name
        self._value = value
        self.previousValue = value.wrappedValue
    }

    var body: some View {
        TextField(name, text: $text)
            .keyboardType(.numberPad)
            .focused($isFocused)
            .onAppear {
                previousValue = value
                text = formatted(value)
            }
            .onChange(of: isFocused) { _, focused in
                if focused {
                    // Clear when editing begins, but remember previous committed value
                    previousValue = value
                    text = ""
                } else {
                    // Focus lost: commit if valid and changed; otherwise restore
                    let parsed = parseDecimal(from: text)
                    if let parsed, parsed != value {
                        value = parsed
                        previousValue = parsed
                        text = formatted(value)
                    } else {
                        value = previousValue
                        text = formatted(value)
                    }
                }
            }
    }

    private func formatted(_ v: Int?) -> String {
        guard let v else { return "" }
        let ns = NSNumber(value: v)
        return NumberFormatter.localIntFormatter.string(from: ns) ?? String(v)
    }

    private func parseDecimal(from s: String) -> Int? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Try to parse using NumberFormatter first (respects locale and grouping)
        if let number = NumberFormatter.localIntFormatter.number(from: trimmed) {
            return number.intValue
        }

        // Fallback: remove grouping separators and any non-digit characters
        var cleaned = trimmed
        if let grouping = NumberFormatter.localIntFormatter.groupingSeparator, !grouping.isEmpty {
            cleaned = cleaned.replacingOccurrences(of: grouping, with: "")
        }
        // Allow optional leading minus sign; otherwise strip non-digits
        let allowed = CharacterSet(charactersIn: "-0123456789")
        cleaned = cleaned.unicodeScalars.filter { allowed.contains($0) }.map { String($0) }.joined()

        return Int(cleaned)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var amount: Int = 4546
        @State private var waste: String = ""

        var body: some View {
            Form {
                IntTextField(name: "Amount", value: $amount)
                Text("Committed: \(String(amount))")
                TextField("", text: $waste)
            }
        }
    }
    
    return PreviewWrapper()
}
