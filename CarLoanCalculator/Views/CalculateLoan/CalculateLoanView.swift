//
//  CalculateLoanView.swift
//  CarLoanCalculator
//
//  Created by Kenny Mann on 6/30/26.
//

import SwiftUI
import SwiftData
import Combine
import Charts

struct CalculateLoanView: View {
    private let store = ICloudLoanSettingsStore()
    
    @State private var isAdvanced: Bool = false
    
    @StateObject private var loanSettingsViewModel: CalculateLoanViewModel
    @State private var formInputsRefreshID = UUID()
    @State private var showClearConfirmation = false
    
    private enum Field: Hashable { case carAmount }
    @FocusState private var focusedField: Field?
    
    //@State private var state // One day I'd like to be able to select a state and have it infer taxes
    @State private var loanInformation: LoanInformation = LoanInformation()
    @State private var displaySalesTaxAmount: String = "$0.00"
    @State private var displayUpfrontPayment: String = "$0.00"
    
    @State private var displayInterestPercent: String = ""
    
    public var toShareFullString: String {
        return #"""
        ------------
        Full Report:
        ------------
        Car Price: \#(NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: self.loanSettingsViewModel.carPrice)) ?? "Error")
        APR / Interest Rate: \#(loanInformation.displayAPR)
        Term: \#(loanInformation.termMonths) months
        ----
        Monthly Payment: \#(loanInformation.displayMonthlyPayment)
        Total Loan Amount: \#(loanInformation.displayTotalLoanAmount)
        Total Interest: \#(loanInformation.displayTotalInterest)
        ----
        Sales Tax: \#(displaySalesTaxAmount)
        Down Payment: \#(displayUpfrontPayment)
        Incentives: \#(NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: self.loanSettingsViewModel.incentives)) ?? "Error")
        Addons: \#(NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: self.loanSettingsViewModel.addons)) ?? "$0.00")
        Trade-In Value: \#(NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: self.loanSettingsViewModel.tradeInValue)) ?? "Error")
        Owed on Trade: \#(NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: self.loanSettingsViewModel.tradeInOwed)) ?? "Error")
        Fees: \#(NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: self.loanSettingsViewModel.fees)) ?? "Error")
        ----
        \#(self.displayInterestPercent) of the loan is interest.
        """#
    }
    
    // TBI: A setting for "warning, that is WAY too much interest and you should be concerned!"
    
    init(
            calculateLoanViewModel: CalculateLoanViewModel = CalculateLoanViewModel(),
            isAdvanced: Bool = false
        ) {
            _loanSettingsViewModel = StateObject(wrappedValue: calculateLoanViewModel)
            _isAdvanced = State(initialValue: isAdvanced)
        }
    
    var body: some View {
        NavigationStack {
            List {
                Section("") {
                    HStack {
                        Text("Car Amount")
                        CurrencyTextField(name: "Car Price", value: $loanSettingsViewModel.carPrice)
                            .focused($focusedField, equals: .carAmount)
                            .onChange(of: loanSettingsViewModel.carPrice) { _, _ in
                                calculateLoan()
                            }
                            .id(formInputsRefreshID)
                            .accessibilityLabel("Car price")
                            .accessibilityHint("Enter the price of the vehicle before incentives and fees")
                    }
                    
                    HStack {
                        Text("Loan Term")
                        IntTextField(name: "Loan Term", value: $loanSettingsViewModel.loanTerm)
                            .onChange(of: loanSettingsViewModel.loanTerm) { _, _ in
                                calculateLoan()
                            }
                            .accessibilityLabel("Loan term in months")
                            .accessibilityHint("Enter the number of months for the loan")
                            .id(formInputsRefreshID)
                    }
                    
                    HStack {
                        Text("Loan Interest Rate")
                        PercentTextField(name: "Loan Interest Rate", value: $loanSettingsViewModel.loanInterestRate)
                            .onChange(of: loanSettingsViewModel.loanInterestRate) { _, _ in
                                calculateLoan()
                            }
                            .id(formInputsRefreshID)
                            .accessibilityLabel("Annual interest rate")
                            .accessibilityHint("Enter the annual percentage rate")
                    }
                    
                    Button ("Expand Additional Fields") {
                        withAnimation {
                            isAdvanced.toggle()
                        }
                    }
                }
                
                Section("", isExpanded: $isAdvanced) {
                    HStack {
                        Text("Incentives")
                        CurrencyTextField(name: "Incentives", value: $loanSettingsViewModel.incentives)
                            .onChange(of: loanSettingsViewModel.incentives) { _, _ in
                                calculateLoan()
                            }
                            .id(formInputsRefreshID)
                            .accessibilityLabel("Incentives")
                            .accessibilityHint("Enter the amount of incentives applied to the purchase")
                    }
                    
                    HStack {
                        Text("Addons")
                        CurrencyTextField(name: "Addons", value: $loanSettingsViewModel.addons)
                            .onChange(of: loanSettingsViewModel.addons) { _, _ in
                                calculateLoan()
                            }
                            .id(formInputsRefreshID)
                            .accessibilityLabel("Add-ons")
                            .accessibilityHint("Enter the total cost of add-ons")
                        // Would like to add individual line items later
//                        Button("Add Item") {
//                            
//                        }
                    }
                    
                    HStack {
                        Text("Down Payment")
                        CurrencyTextField(name: "Down Payment", value: $loanSettingsViewModel.downPayment)
                            .onChange(of: loanSettingsViewModel.downPayment) { _, _ in
                                calculateLoan()
                            }
                            .id(formInputsRefreshID)
                            .accessibilityLabel("Down payment")
                            .accessibilityHint("Enter the amount paid upfront")
                    }
                    
                    HStack {
                        Text("Trade-in Value")
                        CurrencyTextField(name: "Trade-in Value", value: $loanSettingsViewModel.tradeInValue)
                            .onChange(of: loanSettingsViewModel.tradeInValue) { _, _ in
                                calculateLoan()
                            }
                            .id(formInputsRefreshID)
                            .accessibilityLabel("Trade-in value")
                            .accessibilityHint("Enter the value of your trade-in")
                    }
                    
                    HStack {
                        Text("Amount Owed")
                        CurrencyTextField(name: "Amount Owed", value: $loanSettingsViewModel.tradeInOwed)
                            .onChange(of: loanSettingsViewModel.tradeInOwed) { _, _ in
                                calculateLoan()
                            }
                            .id(formInputsRefreshID)
                            .accessibilityLabel("Amount owed on trade-in")
                            .accessibilityHint("Enter the remaining loan balance for your trade-in")
                    }
                    
                    //            // One day I'd like to have a drop down to pre-fill the tax information
                    //            HStack {
                    //                Text("Your State (Taxes)")
                    //                TextField("", value: $loanTerm, format: .number)
                    //                    .keyboardType(.numberPad)
                    //            }
                    
                    HStack {
                        Text("Sales Tax")
                        PercentTextField(name: "Sales Tax", value: $loanSettingsViewModel.tax)
                            .onChange(of: loanSettingsViewModel.tax) { _, _ in
                                calculateLoan()
                            }
                            .id(formInputsRefreshID)
                            .accessibilityLabel("Sales tax")
                            .accessibilityHint("Enter your local sales tax percentage")
                    }
                    
                    HStack {
                        Text("Fees")
                        CurrencyTextField(name: "Fees", value: $loanSettingsViewModel.fees)
                            .onChange(of: loanSettingsViewModel.fees) { _, _ in
                                calculateLoan()
                            }
                            .id(formInputsRefreshID)
                            .accessibilityLabel("Fees")
                            .accessibilityHint("Enter total fees such as registration and documentation")
                    }
                    .frame(height: isAdvanced ? nil : 0, alignment: .top)
                    .clipped()
                }
                
                VStack {
                    Text("Monthly Payment: \(loanInformation.displayMonthlyPayment)")
                        .accessibilityLabel("Monthly payment")
                        .accessibilityValue(loanInformation.displayMonthlyPayment) // I need to test and see how this looks / sounds
                    Text("Total Amount: \(loanInformation.displayTotalLoanAmount)")
                    Text("Sales Tax: \(displaySalesTaxAmount)")
                    Text("Upfront Payment: \(displayUpfrontPayment)")
                    Divider()
                    Text("Total Interest Paid: \(loanInformation.displayTotalInterest)")
                    Group {
                        Text("Principal and Interest")
                            .font(.headline)
                        Chart {
                            ForEach(loanInformation.principalInterestPieChartData, id: \.0) { item in
                                SectorMark(
                                    angle: .value("Percent", item.1),
                                    innerRadius: 0.5,
                                    angularInset: 3.0
                                )
                                .foregroundStyle(by: .value("Item", item.0))
                                .annotation(position: .overlay) {
                                    Text("\(item.0)")
                                        .cornerRadius(5)
                                        .padding(0)
                                        .foregroundStyle(Color.white)
                                }
                            }
                        }
                        .chartLegend(.visible)
                        .frame(height: 260)
                        
                        Text("\(self.displayInterestPercent) percent of the loan is interest")
                            .accessibilityLabel("Interest breakdown")
                            .accessibilityValue("\(self.displayInterestPercent) percent of the loan is interest")
                        
                    }
                }
            }
            .scrollDismissesKeyboard(.interactively) // Test this versus immedietly
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    ShareLink("Share", item: toShareFullString)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showClearConfirmation = true
                    } label: {
                        Label("Clear All", systemImage: "trash")
                    }
                }
            }
            .confirmationDialog("Clear all fields?", isPresented: $showClearConfirmation) {
                Button("Clear All", role: .destructive) {
                    withAnimation {
                        // End editing so fields commit and release focus
                        #if os(iOS)
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                        #endif
                        
                        loanSettingsViewModel.objectWillChange.send()
                        clearData()
                        
#if os(iOS)
                        UIAccessibility.post(notification: .announcement, argument: "All fields cleared")
#endif
                        focusedField = .carAmount
                    }
                }
                Button("Cancel", role: .cancel) {}
            }
            .onAppear {
                calculateLoan()
            }
        }
    }

    func calculateLoan() {
        let carPrice = loanSettingsViewModel.carPrice
        let term = loanSettingsViewModel.loanTerm
        let rate = loanSettingsViewModel.loanInterestRate
        let incentives = loanSettingsViewModel.incentives
        let addons = loanSettingsViewModel.addons
        let down = loanSettingsViewModel.downPayment
        let tradeValue = loanSettingsViewModel.tradeInValue
        let tradeOwed = loanSettingsViewModel.tradeInOwed
        let tax = loanSettingsViewModel.tax
        let fees = loanSettingsViewModel.fees

        guard carPrice > 0, term > 0 else { return }

        let salesTax = (carPrice - tradeValue - incentives) * (tax / 100)
        let totalAmount = (carPrice - tradeValue + tradeOwed + fees - incentives + addons) + salesTax - down

        loanInformation = LoanInformation(
            loanAmount: totalAmount,
            annualInterestRate: rate / 100,
            termMonths: term
        )

        displaySalesTaxAmount = NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: salesTax)) ?? "$0.00"
        displayUpfrontPayment = NumberFormatter.localCurrencyFormatter.string(from: NSDecimalNumber(decimal: down)) ?? "$0.00"
        let formatter = NSDecimalNumberHandler(
            roundingMode: .plain, // nearest
            scale: 0,             // number of decimal places
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )

        displayInterestPercent = "\(NSDecimalNumber(decimal: loanInformation.interestPercentOfLoan).rounding(accordingToBehavior: formatter).stringValue)%"
    }
    
    func clearData() {
        loanSettingsViewModel.carPrice = 0
        loanSettingsViewModel.loanTerm = 0
        loanSettingsViewModel.loanInterestRate = 0
        loanSettingsViewModel.incentives = 0
        loanSettingsViewModel.addons = 0
        loanSettingsViewModel.downPayment = 0
        loanSettingsViewModel.tradeInValue = 0
        loanSettingsViewModel.tradeInOwed = 0
        loanSettingsViewModel.tax = 0
        loanSettingsViewModel.fees = 0
        
        // Reset derived UI
        loanInformation = LoanInformation()
        displaySalesTaxAmount = "$0.00"
        displayUpfrontPayment = "$0.00"
        displayInterestPercent = ""
        
        formInputsRefreshID = UUID()
        loanSettingsViewModel.objectWillChange.send()
    }
}

#Preview("CalculateLoan - Sample Data") {
    let vm = CalculateLoanViewModel()
    vm.carPrice = 47079
    vm.loanTerm = 72
    vm.loanInterestRate = 4.75
    vm.incentives = 1000
    vm.addons = 2300
    vm.downPayment = 0
    vm.tradeInValue = 39000
    vm.tradeInOwed = 17479
    vm.tax = 8.25
    vm.fees = 600

    return CalculateLoanView(calculateLoanViewModel: vm, isAdvanced: true)
}

#Preview("CalculatLoan - Empty; Might load for Cloud") {
    return CalculateLoanView()
}

