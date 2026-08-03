import SwiftUI
import SwiftData

struct MoneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    @State private var showingEditor = false
    @State private var transactionToEdit: Transaction? = nil
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "selected_currency") ?? "Rp"
    }
    
    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        return transactions.filter {
            calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
    }
    
    private var summary: MoneySummary {
        MoneySummaryService.summary(for: currentMonthTransactions)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    HStack(spacing: 12) {
                        SummaryCard(title: "Income", amount: summary.income, symbol: currencySymbol, color: .green)
                        SummaryCard(title: "Expenses", amount: summary.expenses, symbol: currencySymbol, color: .red)
                        SummaryCard(title: "Net Flow", amount: summary.net, symbol: currencySymbol, color: summary.net >= 0 ? .blue : .orange)
                    }
                    .padding(.horizontal)
                    
                    if !currentMonthTransactions.isEmpty {
                        MoneyChartView(transactions: transactions, currentMonthOnly: true)
                            .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("This Month's Transactions")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if currentMonthTransactions.isEmpty {
                            ContentUnavailableView(
                                "No Transactions",
                                systemImage: "creditcard",
                                description: Text("Log an income or expense to see the cash flow summary.")
                            )
                            .padding(.vertical, 40)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(currentMonthTransactions) { tx in
                                    TransactionRow(transaction: tx, currencySymbol: currencySymbol)
                                        .padding()
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                transactionToEdit = tx
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(.blue)
                                        }
                                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                            Button(role: .destructive) {
                                                delete(tx)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
                                            }
                                        }
                                    
                                    if tx != currentMonthTransactions.last {
                                        Divider()
                                    }
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Money")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingEditor = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingEditor) {
                TransactionEditorView()
            }
            .sheet(item: $transactionToEdit) { tx in
                TransactionEditorView(transactionToEdit: tx)
            }
        }
    }
    
    private func delete(_ transaction: Transaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Decimal
    let symbol: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(symbol) \(amount, format: .number.precision(.fractionLength(0...2)))")
                .font(.subheadline)
                .bold()
                .foregroundStyle(color)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let currencySymbol: String
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category)
                    .font(.body)
                    .bold()
                
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("\(transaction.type == .income ? "+" : "-") \(currencySymbol) \(transaction.amount, format: .number.precision(.fractionLength(0...2)))")
                .font(.body)
                .bold()
                .foregroundStyle(transaction.type == .income ? .green : .red)
        }
    }
}
