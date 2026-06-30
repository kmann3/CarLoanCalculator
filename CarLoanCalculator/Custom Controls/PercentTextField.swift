//
//  PercentTextField.swift
//  CarLoanCalculator
//
//  Created by Kenny Mann on 6/30/26.
//

import SwiftUI

struct PercentTextField: View {
    @Binding var value: Decimal

    @FocusState private var isFocused: Bool

    let name: String

    @State private var previousValue: Decimal
    @State private var text: String = ""
    
    init(name: String, value: Binding<Decimal>) {
        self.name = name
        self._value = value
        self.previousValue = value.wrappedValue
    }

    var body: some View {
        TextField(name, text: $text)
            .keyboardType(.decimalPad)
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

    private func formatted(_ v: Decimal?) -> String {
        guard let v else { return "" }
        // NumberFormatter with .percent expects fractional input (e.g., 0.0475 -> 4.75%)
        let scaled = v / 100
        let ns = NSDecimalNumber(decimal: scaled)
        return NumberFormatter.localPercentFormatter.string(from: ns) ?? "\(v)"
    }

    private func parseDecimal(from s: String) -> Decimal? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Try to parse using NumberFormatter first (respects locale and symbols)
        if let number = NumberFormatter.localPercentFormatter.number(from: trimmed) {
            // Parsing with .percent yields a fractional value (e.g., 4.75% -> 0.0475)
            // Convert back to percent units for storage (e.g., 0.0475 -> 4.75)
            return number.decimalValue * 100
        }

        // Fallback: remove percent symbol and grouping separators, then parse with locale-aware Decimal initializer
        var cleaned = trimmed.replacingOccurrences(of: "%", with: "")
        if let grouping = NumberFormatter.localPercentFormatter.groupingSeparator, !grouping.isEmpty {
            cleaned = cleaned.replacingOccurrences(of: grouping, with: "")
        }

        // Decimal(string: , locale:) handles different decimal separators safely
        if let dec = Decimal(string: cleaned, locale: NumberFormatter.localPercentFormatter.locale) {
            return dec
        }

        return nil
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var amount: Decimal = 4.75
        @State private var waste: String = ""

        var body: some View {
            Form {
                PercentTextField(name: "Amount", value: $amount)
                Text("Committed: \(amount.description)")
                TextField("", text: $waste)
            }
        }
    }

    return PreviewWrapper()
}
