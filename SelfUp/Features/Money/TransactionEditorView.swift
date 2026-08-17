import SwiftUI
import SwiftData

enum ValidationError: Error, LocalizedError {
    case invalidAmount
    case emptyCategory
    
    var errorDescription: String? {
        switch self {
        case .invalidAmount: return "Amount must be greater than 0."
        case .emptyCategory: return "Category cannot be empty."
        }
    }
}

struct TransactionDraft {
    var amountText: String
    var type: TransactionType
    var category: String
    var note: String = ""
    var date: Date = Date()
    
    func makeTransaction() throws -> Transaction {
        let cleanedText = amountText.replacingOccurrences(of: ",", with: ".")
        guard let amount = Decimal(string: cleanedText), amount > 0 else {
            throw ValidationError.invalidAmount
        }
        let trimmedCat = category.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCat.isEmpty else {
            throw ValidationError.emptyCategory
        }
        return Transaction(amount: amount, type: type, category: trimmedCat, note: note, date: date)
    }
}

struct TransactionEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    var transactionToEdit: Transaction?
    
    @State private var amountText: String = ""
    @State private var type: TransactionType = .expense
    @State private var category: String = ""
    @State private var note: String = ""
    @State private var date: Date = Date()
    @State private var errorMessage: String? = nil
    
    let expenseCategories = ["Food", "Transport", "Shopping", "Rent", "Utilities", "Entertainment", "Education", "Other"]
    let incomeCategories = ["Salary", "Freelance", "Investment", "Gift", "Other"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Type")) {
                    Picker("Type", selection: $type) {
                        ForEach(TransactionType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _, newType in
                        let defaultCategories = newType == .expense ? expenseCategories : incomeCategories
                        if !defaultCategories.contains(category) {
                            category = defaultCategories.first ?? ""
                        }
                    }
                }
                
                Section(header: Text("Amount & Category")) {
                    HStack {
                        Text(currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("transaction_amount_field")
                    }
                    
                    Picker("Category", selection: $category) {
                        let categories = type == .expense ? expenseCategories : incomeCategories
                        ForEach(categories, id: \.self) { cat in
                            Text(cat).tag(cat)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Section(header: Text("Details")) {
                    TextField("Note (Optional)", text: $note)
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                            .font(.subheadline)
                    }
                }
            }
            .navigationTitle(transactionToEdit == nil ? "Log Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                }
            }
            .onAppear {
                if let transaction = transactionToEdit {
                    amountText = "\(transaction.amount)"
                    type = transaction.type
                    category = transaction.category
                    note = transaction.note
                    date = transaction.date
                } else {
                    category = expenseCategories.first ?? ""
                }
            }
        }
    }
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "selected_currency") ?? "Rp"
    }
    
    private func save() {
        errorMessage = nil
        let draft = TransactionDraft(amountText: amountText, type: type, category: category, note: note, date: date)
        
        do {
            let newTransaction = try draft.makeTransaction()
            
            if let existing = transactionToEdit {
                existing.amount = newTransaction.amount
                existing.type = newTransaction.type
                existing.category = newTransaction.category
                existing.note = newTransaction.note
                existing.date = newTransaction.date
            } else {
                modelContext.insert(newTransaction)
            }
            
            try modelContext.save()
            if let savedTransactions = try? modelContext.fetch(FetchDescriptor<Transaction>()) {
                Task {
                    _ = await NotificationManager.reconcileFunBudget(
                        transactions: savedTransactions,
                        currencySymbol: currencySymbol,
                        now: Date(),
                        calendar: .autoupdatingCurrent
                    )
                }
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
