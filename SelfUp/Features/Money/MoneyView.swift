import SwiftUI
import SwiftData

struct MoneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    
    @State private var showingEditor = false
    @State private var transactionToEdit: Transaction? = nil
    @State private var showingSettings = false
    
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
    
    private var expenseRatio: Double {
        if summary.income == 0 { return summary.expenses > 0 ? 1.0 : 0.0 }
        return min(1.0, Double(truncating: (summary.expenses / summary.income) as NSDecimalNumber))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Net Flow Hero Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NET FLOW THIS MONTH")
                                    .font(.caption)
                                    .bold()
                                    .foregroundStyle(.secondary)
                                
                                Text("\(currencySymbol) \(summary.net, format: .number.precision(.fractionLength(0...2)))")
                                    .font(.system(size: 32, weight: .black, design: .rounded))
                                    .foregroundStyle(summary.net >= 0 ? .green : .red)
                            }
                            Spacer()
                        }
                        
                        // Side-by-side meters
                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total Income")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(currencySymbol) \(summary.income, format: .number)")
                                    .font(.headline)
                                    .bold()
                                    .foregroundStyle(.green)
                            }
                            Divider()
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Total Expenses")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(currencySymbol) \(summary.expenses, format: .number)")
                                    .font(.headline)
                                    .bold()
                                    .foregroundStyle(.red)
                            }
                            Spacer()
                        }
                        .frame(height: 40)
                        
                        // Progress bar representing Expense / Income ratio
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Expense vs Income Gauge")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(expenseRatio * 100, format: .number.precision(.fractionLength(0)))%")
                                    .font(.caption2)
                                    .bold()
                                    .foregroundStyle(expenseRatio > 0.8 ? .red : (expenseRatio > 0.5 ? .orange : .green))
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(height: 8)
                                    Capsule()
                                        .fill(expenseRatio > 0.8 ? Color.red : (expenseRatio > 0.5 ? Color.orange : Color.green))
                                        .frame(width: geo.size.width * CGFloat(expenseRatio), height: 8)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .premiumCard()
                    .padding(.horizontal)
                    
                    // Donut Chart & Category breakdown
                    if !currentMonthTransactions.isEmpty {
                        MoneyChartView(transactions: transactions, currentMonthOnly: true)
                            .padding(.horizontal)
                    }
                    
                    // Recent Transactions List
                    VStack(alignment: .leading, spacing: 12) {
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
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Money")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
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
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }
    
    private func delete(_ transaction: Transaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    let currencySymbol: String
    
    private var isIncome: Bool {
        transaction.type == .income
    }
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(isIncome ? Color.green.opacity(0.12) : Color.red.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: isIncome ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                    .font(.headline)
                    .foregroundStyle(isIncome ? Color.green : Color.red)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category)
                    .font(.subheadline)
                    .bold()
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(isIncome ? "+" : "-")\(currencySymbol) \(transaction.amount, format: .number.precision(.fractionLength(0...2)))")
                    .font(.subheadline)
                    .bold()
                    .foregroundStyle(isIncome ? Color.green : Color.primary)
                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
