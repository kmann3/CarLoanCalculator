//
//  CalculateLoanViewModel.swift
//  CarLoanCalculator
//
//  Created by Kenny Mann on 6/30/26.
//

import Foundation
import Combine

// Most of this file was written by DuckDuckGo AI with me having to do small fixes to get it working correctly.
// And then a lot of small changes because I didn't like some of it
final class CalculateLoanViewModel: ObservableObject {
    @Published var carPrice: Decimal = 0
    @Published var loanTerm: Int = 0
    @Published var loanInterestRate: Decimal = 0
    @Published var incentives: Decimal = 0
    @Published var downPayment: Decimal = 0
    @Published var addons: Decimal = 0
    @Published var tradeInValue: Decimal = 0
    @Published var tradeInOwed: Decimal = 0
    @Published var tax: Decimal = 0
    @Published var fees: Decimal = 0
    
    // Destination fee?
    // TTL? Individually?

    private let store = ICloudLoanSettingsStore()
    private var cancellables = Set<AnyCancellable>()

    private var isApplyingRemote = false

    init() {
        
        if self.carPrice == 0 {
            apply(snapshot: store.load())
        }

        // Listen for external changes from iCloud
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleICloudChange),
            name: NSUbiquitousKeyValueStore.didChangeExternallyNotification,
            object: NSUbiquitousKeyValueStore.default
        )

        // Auto-save after typing stops (debounced)
        // The goal here is really to sync between iPhone and iPad
        Publishers
            .CombineLatest4($carPrice, $loanTerm, $loanInterestRate, $incentives)
            .combineLatest(Publishers.CombineLatest4($addons, $downPayment, $tradeInValue, $tradeInOwed))
            .combineLatest($tax, $fees)
            .debounce(for: DispatchQueue.SchedulerTimeType.Stride.milliseconds(400), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                guard !self.isApplyingRemote else { return }
                let snapshot = SettingsSnapshot(
                    carPrice: self.carPrice,
                    loanTerm: self.loanTerm,
                    loanInterestRate: self.loanInterestRate,
                    incentives: self.incentives,
                    addons: self.addons,
                    downPayment: self.downPayment,
                    tradeInValue: self.tradeInValue,
                    tradeInOwed: self.tradeInOwed,
                    tax: self.tax,
                    fees: self.fees
                )
                self.store.save(snapshot)
            }
            .store(in: &cancellables)
    }

    private func apply(snapshot: SettingsSnapshot) {
        isApplyingRemote = true
        carPrice = snapshot.carPrice
        loanTerm = snapshot.loanTerm
        loanInterestRate = snapshot.loanInterestRate
        incentives = snapshot.incentives
        addons = snapshot.addons
        downPayment = snapshot.downPayment
        tradeInValue = snapshot.tradeInValue
        tradeInOwed = snapshot.tradeInOwed
        tax = snapshot.tax
        fees = snapshot.fees
        isApplyingRemote = false
    }

    @objc private func handleICloudChange() {
        apply(snapshot: store.load())
    }

    // Manual save, if I ever implement it
    func saveNow() {
        let snapshot = SettingsSnapshot(
            carPrice: carPrice,
            loanTerm: loanTerm,
            loanInterestRate: loanInterestRate,
            incentives: incentives,
            addons: addons,
            downPayment: downPayment,
            tradeInValue: tradeInValue,
            tradeInOwed: tradeInOwed,
            tax: tax,
            fees: fees
        )
        store.save(snapshot)
    }
}
