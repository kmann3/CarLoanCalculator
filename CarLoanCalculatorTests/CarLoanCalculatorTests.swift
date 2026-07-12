//
//  CarLoanCalculatorTests.swift
//  CarLoanCalculatorTests
//
//  Created by Kenny Mann on 7/12/26.
//

import Foundation
import Testing
@testable import CarLoanCalculator

// This was written by ChatGPT.
// I've gone over it by hand though. Assume I'm an idiot and feel free to double check.
// I had to change the typicalLoan to use raw numbers so it didn't re-calculate the loan from the same logic I already wrote. Just in case my logic was wrong.
@Suite("LoanInformation math tests")
struct LoanInformationTests {
    // Helper to convert Decimal to Double for approximate comparisons
    private func d(_ value: Decimal) -> Double { NSDecimalNumber(decimal: value).doubleValue }

    // Helper to assert approximate equality within a tolerance
    private func assertApproximatelyEqual(_ actual: Double, _ expected: Double, tolerance: Double = 0.01) {
        let condition = abs(actual - expected) <= tolerance
        #expect(condition)
    }

    // A $12,000 loan at 0% interest should be a $500.00 monthly payment.
    @Test("Zero interest loan produces equal principal payments and zero interest")
    func zeroInterestLoan() throws {
        let loan = LoanInformation(loanAmount: 12_000, annualInterestRate: 0, termMonths: 24)

        // Monthly payment should be principal/term
        assertApproximatelyEqual(d(loan.monthlyPaymentAmount), 500.0, tolerance: 0.001)
        // Total interest should be zero
        assertApproximatelyEqual(d(loan.totalInterestPaid), 0.0, tolerance: 0.0001)
        // Total principal should equal loan amount
        assertApproximatelyEqual(d(loan.totalPrincipalPaid), 12_000.0, tolerance: 0.01)

        // Schedule length equals term
        #expect(loan.monthlyInterestPrincipalLineChartData.count == 24)

        // Each month: principal == payment, interest == 0
        for month in loan.monthlyInterestPrincipalLineChartData {
            assertApproximatelyEqual(d(month.principal), 500.0, tolerance: 0.001)
            assertApproximatelyEqual(d(month.interest), 0.0, tolerance: 0.0001)
        }
    }

    @Test("Typical loan at 5% APR for 60 months")
    func typicalLoan() throws {
        let principal: Decimal = 20_000
        let apr: Decimal = 0.05 // 5%
        let term = 60

        let loan = LoanInformation(loanAmount: principal, annualInterestRate: apr, termMonths: term)

        assertApproximatelyEqual(d(loan.monthlyPaymentAmount), 377.42, tolerance: 0.05)

        // Totals from amortization should be consistent
        let totalPaid = d(loan.monthlyPaymentAmount) * Double(term)
        assertApproximatelyEqual(d(loan.totalPrincipalPaid), d(principal), tolerance: 0.05)
        assertApproximatelyEqual(d(loan.totalInterestPaid), totalPaid - d(principal), tolerance: 0.5)

        // Schedule sums should match totals
        let schedulePrincipalSum = 20_000.00
        let scheduleInterestSum = 2_645.48
        assertApproximatelyEqual(schedulePrincipalSum, d(loan.totalPrincipalPaid), tolerance: 0.05)
        assertApproximatelyEqual(scheduleInterestSum, d(loan.totalInterestPaid), tolerance: 0.05)

        // Percentages should match definition
        let expectedInterestPct = scheduleInterestSum / schedulePrincipalSum * 100.0
        let expectedPrincipalPct = 100.0 - expectedInterestPct
        assertApproximatelyEqual(d(loan.interestPercentOfLoan), expectedInterestPct, tolerance: 0.01)
        assertApproximatelyEqual(d(loan.principalPercentOfLoan), expectedPrincipalPct, tolerance: 0.01)
    }

    // This is in case I was dumb and forgot.
    // Fool myself once.. shame on me? Because oooh boy did this throw my numbers off and my hair out trying to figure out how I done goofed
    @Test("APR sanitization: passing 5 equals passing 0.05")
    func aprSanitization() throws {
        let term = 60
        let p: Decimal = 20_000

        let loanPercent = LoanInformation(loanAmount: p, annualInterestRate: 0.05, termMonths: term)
        let loanWholeNumber = LoanInformation(loanAmount: p, annualInterestRate: 5, termMonths: term) // should be sanitized to 0.05

        assertApproximatelyEqual(d(loanPercent.monthlyPaymentAmount), d(loanWholeNumber.monthlyPaymentAmount), tolerance: 0.001)
        assertApproximatelyEqual(d(loanPercent.totalInterestPaid), d(loanWholeNumber.totalInterestPaid), tolerance: 0.05)
        assertApproximatelyEqual(d(loanPercent.totalPrincipalPaid), d(loanWholeNumber.totalPrincipalPaid), tolerance: 0.001)
    }

    // I have no idea what chatGPT thinks this matters but ok.
    @Test("Last payment principal adjustment avoids negative balance")
    func lastPaymentAdjustment() throws {
        let loan = LoanInformation(loanAmount: 10_000, annualInterestRate: 0.0725, termMonths: 36)
        // Sum of principal should exactly equal original loan amount
        let principalSum = loan.monthlyInterestPrincipalLineChartData.reduce(0.0) { $0 + d($1.principal) }
        assertApproximatelyEqual(principalSum, 10_000.0, tolerance: 0.05)

        // The last month's principal should be payment - last month's interest
        if let last = loan.monthlyInterestPrincipalLineChartData.last {
            let expectedLastPrincipal = d(loan.monthlyPaymentAmount) - d(last.interest)
            assertApproximatelyEqual(d(last.principal), expectedLastPrincipal, tolerance: 0.01)
        } else {
            Issue.record(Comment("Schedule unexpectedly empty"))
        }
    }
}
