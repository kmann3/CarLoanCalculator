//
//  Extensions.swift
//  CarLoanCalculator
//
//  Created by Kenny Mann on 6/30/26.
//

import Foundation

extension NumberFormatter {
    static var localCurrencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        formatter.generatesDecimalNumbers = true
        formatter.usesGroupingSeparator = true
        return formatter
    }
    
    static var localIntFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 0
        formatter.minimumFractionDigits = 0
        formatter.generatesDecimalNumbers = true
        formatter.usesGroupingSeparator = true
        return formatter
    }
    
    static var localPercentFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 5
        formatter.minimumFractionDigits = 0
        formatter.generatesDecimalNumbers = true
        formatter.usesGroupingSeparator = true
        return formatter
    }
    
    static var localPercentFormatter2: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = Locale.current
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.generatesDecimalNumbers = true
        formatter.usesGroupingSeparator = true
        return formatter
    }
}
