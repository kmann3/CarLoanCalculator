//
//  LoanInformation.swift
//  CarLoanCalculator
//
//  Created by Kenny Mann on 6/30/26.
//

import Foundation
import SwiftData
import Charts
import SwiftUI

final class LoanInformation {
    public var loanAmount: Decimal = 0
    public var annualInterestRate: Decimal = 0  // APR as decimal, e.g. 0.05 for 5%
    public var monthlyInterestRate: Decimal  { annualInterestRate == 0 ? 0 : annualInterestRate / 12.0 }
    public var termMonths: Int = 0

    public var monthlyPaymentAmount: Decimal = 0
    public var totalInterestPaid: Decimal = 0
    public var totalPrincipalPaid: Decimal = 0
    public var interestPercentOfLoan: Decimal = 0
    public var principalPercentOfLoan: Decimal = 0

    public var displayLoanAmount: String { return NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: loanAmount)) ?? "\(loanAmount)" }
    public var displayAPR: String { return NumberFormatter.localPercentFormatter.string(from: NSDecimalNumber(decimal: annualInterestRate))! }
    public var displayTerm: String { "\(termMonths) months" }
    public var displayMonthlyPayment: String { NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: monthlyPaymentAmount))! }
    public var displayTotalLoanAmount: String { NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: loanAmount + totalInterestPaid))! }
    public var displayTotalInterest: String { NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: totalInterestPaid))! }
    
    public var monthlyInterestPrincipalLineChartData: [MonthlyChartData] = []
    
    public var principalInterestPieChartData: [(String, Decimal)] = [
        ("Principal", 50),
        ("Interest", 50)
    ]
    
    init() {
        
    }
    
    init(loanAmount: Decimal, annualInterestRate: Decimal, termMonths: Int) {
        self.loanAmount = loanAmount
        self.annualInterestRate = annualInterestRate > 1 ? annualInterestRate / 100 : annualInterestRate // Let's sanity check. No one should be paying over 100% interest for a loan
        self.termMonths = termMonths

        self.monthlyInterestPrincipalLineChartData = (0..<termMonths).map { i in MonthlyChartData(month: i + 1, interest: 0, principal: 0) }

        let n = Decimal(termMonths)
        let c = self.annualInterestRate / 12.0 // monthly rate (use sanitized APR)

        // Monthly payment
        if c == 0 {
            self.monthlyPaymentAmount = loanAmount / n
        } else {
            let pow = pow(1.0 + c, termMonths)
            self.monthlyPaymentAmount = loanAmount * ((c * pow) / (pow - 1.0))
        }

        // Amortization schedule totals
        var balance = loanAmount
        var principalSum: Decimal = 0.0 // This should total to be the loan amount
        var interestSum: Decimal = 0.0

        for month in 0..<termMonths {
            let interest = balance * c
            let principal = monthlyPaymentAmount - interest

            // Guard against tiny floating-point issues at the end
            let adjustedPrincipal: Decimal
            if month == termMonths - 1 {
                adjustedPrincipal = balance
            } else {
                adjustedPrincipal = principal
            }

            let adjustedInterest = monthlyPaymentAmount - adjustedPrincipal

            monthlyInterestPrincipalLineChartData[month].month = month + 1
            monthlyInterestPrincipalLineChartData[month].interest = adjustedInterest
            monthlyInterestPrincipalLineChartData[month].principal = adjustedPrincipal


            balance -= adjustedPrincipal
            principalSum += adjustedPrincipal
            interestSum += adjustedInterest
        }

        self.totalPrincipalPaid = principalSum
        self.totalInterestPaid = interestSum
        
        let interestPercent = (totalInterestPaid / totalPrincipalPaid) * 100
        let principalPercent = 100 - interestPercent
        
        self.interestPercentOfLoan = interestPercent
        self.principalPercentOfLoan = principalPercent
        
        principalInterestPieChartData = [
            ("Principal", principalPercent),
            ("Interest", interestPercent)
        ]
    }
    
    struct MonthlyChartData: Identifiable {
        var id = UUID()
        var month: Int
        var interest: Decimal
        var principal: Decimal
    }
}

@MainActor
extension LoanInformation: CustomDebugStringConvertible {
    public var debugDescription: String {
        return """
            LoanInformation:
            - Amount: \(loanAmount)
            - APR: \(annualInterestRate)
            - Monthly Interest Rate: \(monthlyInterestRate)
            - Term: \(termMonths)
            -
            - Monthly payment: \(monthlyPaymentAmount)
            - Total Interest: \(totalInterestPaid)
            -
            - DisplayMonthlyPayment: \(displayMonthlyPayment)
            - Display Total Loan Paid: \(displayTotalLoanAmount)
            - Display Total Interest: \(displayTotalInterest)
            """
    }
    
    public var shortDescription: String {
        return "LoanInformation: Amount: \(loanAmount) APR: \(annualInterestRate) Term: \(termMonths)"
    }
}

