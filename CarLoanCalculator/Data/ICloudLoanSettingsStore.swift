//
//  ICloudLoanSettingsStore.swift
//  CarLoanCalculator
//
//  Created by Kenny Mann on 6/30/26.
//

import Foundation

final class ICloudLoanSettingsStore {
    static let suite = NSUbiquitousKeyValueStore.default

    // Keys
    private enum Key {
        static let carPrice = "carPrice"
        static let loanTerm = "loanTerm"
        static let loanInterestRate = "loanInterestRate"
        static let incentives = "incentives"
        static let addons = "addons"
        static let downPayment = "downPayment"
        static let tradeInValue = "tradeInValue"
        static let tradeInOwed = "tradeInOwed"
        static let tax = "tax"
        static let fees = "fees"
    }

    // Precision
    private static let dp2 = 2
    private static let dp5 = 5

    private static let roundingMode: NSDecimalNumber.RoundingMode = .bankers

    // MARK: - Decimal helpers
    private func quantize(_ value: Decimal, dp: Int) -> Decimal {
        var v = value
        var result = Decimal()
        NSDecimalRound(&result, &v, dp, ICloudLoanSettingsStore.roundingMode)
        return result
    }

    private func getDecimal(key: String, dp: Int) -> Decimal {
        guard let raw = Self.suite.object(forKey: key) else { return 0 }
        if let s = raw as? String, let d = Decimal(string: s) { return d }
        if let n = raw as? NSNumber { return quantize(n.decimalValue, dp: dp) }
        return 0
    }

    private func getInt(key: String) -> Int {
        // NSUbiquitousKeyValueStore does not have integer(forKey:),
        // so read the stored value and coerce safely to Int.
        if let raw = Self.suite.object(forKey: key) {
            if let n = raw as? NSNumber { return n.intValue }
            if let s = raw as? String, let i = Int(s) { return i }
        }
        return 0
    }

    private func setDecimal(_ value: Decimal, key: String, dp: Int) {
        let q = quantize(value, dp: dp)
        // Store as string to avoid binary floating issues
        Self.suite.set(NSDecimalNumber(decimal: q).stringValue, forKey: key)
    }

    // MARK: - Public API
    func load() -> SettingsSnapshot {
        SettingsSnapshot(
            carPrice: getDecimal(key: Key.carPrice, dp: Self.dp2),
            loanTerm: getInt(key: Key.loanTerm),
            loanInterestRate: getDecimal(key: Key.loanInterestRate, dp: Self.dp2),
            incentives: getDecimal(key: Key.incentives, dp: Self.dp2),
            addons: getDecimal(key: Key.addons, dp: Self.dp2),
            downPayment: getDecimal(key: Key.downPayment, dp: Self.dp2),
            tradeInValue: getDecimal(key: Key.tradeInValue, dp: Self.dp2),
            tradeInOwed: getDecimal(key: Key.tradeInOwed, dp: Self.dp2),
            tax: getDecimal(key: Key.tax, dp: Self.dp5),
            fees: getDecimal(key: Key.fees, dp: Self.dp2)
        )
    }

    func save(_ snapshot: SettingsSnapshot) {
        setDecimal(snapshot.carPrice, key: Key.carPrice, dp: Self.dp2)
        Self.suite.set(snapshot.loanTerm, forKey: Key.loanTerm)
        setDecimal(snapshot.loanInterestRate, key: Key.loanInterestRate, dp: Self.dp2)
        setDecimal(snapshot.incentives, key: Key.incentives, dp: Self.dp2)
        setDecimal(snapshot.addons, key: Key.addons, dp: Self.dp2)
        setDecimal(snapshot.downPayment, key: Key.downPayment, dp: Self.dp2)
        setDecimal(snapshot.tradeInValue, key: Key.tradeInValue, dp: Self.dp2)
        setDecimal(snapshot.tradeInOwed, key: Key.tradeInOwed, dp: Self.dp2)
        setDecimal(snapshot.tax, key: Key.tax, dp: Self.dp5)
        setDecimal(snapshot.fees, key: Key.fees, dp: Self.dp2)

        Self.suite.synchronize()
    }
}

struct SettingsSnapshot: Equatable {
    var carPrice: Decimal = 0
    var loanTerm: Int = 0
    var loanInterestRate: Decimal = 0
    var incentives: Decimal = 0
    var addons: Decimal = 0
    var downPayment: Decimal = 0
    var tradeInValue: Decimal = 0
    var tradeInOwed: Decimal = 0
    var tax: Decimal = 0
    var fees: Decimal = 0
}
