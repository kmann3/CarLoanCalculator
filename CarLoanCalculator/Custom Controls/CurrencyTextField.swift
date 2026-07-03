//
//  CurrencyTextField.swift
//  CarLoanCalculator
//
//  Created by Kenny Mann on 6/30/26.
//

import SwiftUI

struct CurrencyTextField: View {
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
        #if os(iOS)
            .keyboardType(.decimalPad)
        #endif
            .focused($isFocused)
            .onAppear {
                previousValue = value
                text = formatted(value)
            }
            .onChange(of: value) { _, newValue in
                // IMPORTANT: update internal text when binding changes externally
                let newString = NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: newValue)) ?? ""
                if text != newString {
                    text = newString
                }
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
        let ns = NSDecimalNumber(decimal: v)
        return NumberFormatter.localCurrencyFormatter.string(from: ns) ?? "\(v)"
    }

    private func parseDecimal(from s: String) -> Decimal? {
        let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        // Try to parse using NumberFormatter first (respects locale and symbols)
        if let number = NumberFormatter.localCurrencyFormatter.number(from: trimmed) {
            return number.decimalValue
        }

        // Fallback: remove currency symbol and grouping separators, then parse with locale-aware Decimal initializer
        var cleaned = trimmed.replacingOccurrences(of: NumberFormatter.localCurrencyFormatter.currencySymbol, with: "")
        if let grouping = NumberFormatter.localCurrencyFormatter.groupingSeparator, !grouping.isEmpty {
            cleaned = cleaned.replacingOccurrences(of: grouping, with: "")
        }

        // Decimal(string: , locale:) handles different decimal separators safely
        if let dec = Decimal(string: cleaned, locale: NumberFormatter.localCurrencyFormatter.locale) {
            return dec
        }

        return nil
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var amount: Decimal = 4546.67
        @State private var waste: String = ""

        var body: some View {
            Form {
                CurrencyTextField(name: "Amount", value: $amount)
                Text("Committed: \(amount.description)")
                TextField("", text: $waste)
            }
        }
    }
    
    return PreviewWrapper()
}
