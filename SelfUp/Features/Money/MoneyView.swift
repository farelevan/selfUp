import SwiftUI
import SwiftData

struct MoneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \SavingGoal.createdAt) private var savingGoals: [SavingGoal]
    
    @State private var showingEditor = false
    @State private var transactionToEdit: Transaction? = nil
    @State private var showingSettings = false
    @State private var showingGoalEditor = false
    @State private var goalToEdit: SavingGoal? = nil
    @State private var goalToFund: SavingGoal? = nil
    
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
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(SelfUpStyle.primaryIndigo)
                                    .tracking(1)
                                
                                Text("\(currencySymbol) \(summary.net, format: .number.precision(.fractionLength(0...2)))")
                                    .font(.system(size: 34, weight: .bold, design: .rounded))
                                    .foregroundStyle(summary.net >= 0 ? Color.emerald : Color.coral)
                            }
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill((summary.net >= 0 ? Color.emerald : Color.coral).opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: summary.net >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(summary.net >= 0 ? Color.emerald : Color.coral)
                            }
                        }
                        
                        // Side-by-side meters
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.down.left.circle.fill")
                                        .foregroundStyle(Color.emerald)
                                        .font(.caption)
                                    Text("Income")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                Text("\(currencySymbol) \(summary.income, format: .number)")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.emerald)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.emerald.opacity(0.08)))
                            
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.right.circle.fill")
                                        .foregroundStyle(Color.coral)
                                        .font(.caption)
                                }
                                Text("Expenses")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text("\(currencySymbol) \(summary.expenses, format: .number)")
                                    .font(.system(.headline, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.coral)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.coral.opacity(0.08)))
                        }
                        
                        // Progress bar representing Expense / Income ratio
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Expense Ratio")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text("\(expenseRatio * 100, format: .number.precision(.fractionLength(0)))%")
                                    .font(.caption2)
                                    .fontWeight(.bold)
                                    .foregroundStyle(expenseRatio > 0.8 ? Color.coral : (expenseRatio > 0.5 ? Color.orange : Color.emerald))
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.08))
                                        .frame(height: 8)
                                    Capsule()
                                        .fill(expenseRatio > 0.8 ? Color.coral : (expenseRatio > 0.5 ? Color.orange : Color.emerald))
                                        .frame(width: max(8, geo.size.width * CGFloat(expenseRatio)), height: 8)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: expenseRatio)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .glowingCard(color: summary.net >= 0 ? Color.emerald : Color.coral, cornerRadius: 20)
                    .padding(.horizontal)
                    
                    // Donut Chart & Category breakdown
                    if !currentMonthTransactions.isEmpty {
                        MoneyChartView(transactions: transactions, currentMonthOnly: true)
                            .padding(.horizontal)
                    }
                    
                    // Saving Goals Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Saving Goals")
                                .font(.system(.title3, design: .rounded))
                                .fontWeight(.bold)
                            Spacer()
                            Button {
                                showingGoalEditor = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(SelfUpStyle.primaryIndigo)
                            }
                        }
                        .padding(.horizontal)
                        
                        if savingGoals.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "target")
                                    .font(.largeTitle)
                                    .foregroundStyle(SelfUpStyle.primaryIndigo.opacity(0.6))
                                Text("Set your first saving goal")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                Button {
                                    showingGoalEditor = true
                                } label: {
                                    Text("Add Goal")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(Capsule().fill(SelfUpStyle.primaryIndigo))
                                        .foregroundStyle(.white)
                                }
                                .pressableScale()
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                            .background(RoundedRectangle(cornerRadius: 20).fill(Color(.secondarySystemGroupedBackground)))
                            .padding(.horizontal)
                        } else {
                            VStack(spacing: 12) {
                                ForEach(savingGoals) { goal in
                                    let progress = goal.targetAmount > 0 ? min(1.0, Double(truncating: (goal.currentAmount / goal.targetAmount) as NSDecimalNumber)) : 0.0
                                    
                                    VStack(alignment: .leading, spacing: 12) {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(goal.title)
                                                    .font(.system(.headline, design: .rounded))
                                                    .fontWeight(.bold)
                                                Text("\(currencySymbol) \(goal.currentAmount, format: .number) of \(currencySymbol) \(goal.targetAmount, format: .number)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text("\(progress * 100, format: .number.precision(.fractionLength(0)))%")
                                                .font(.system(.callout, design: .rounded))
                                                .fontWeight(.bold)
                                                .foregroundStyle(SelfUpStyle.primaryIndigo)
                                        }
                                        
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.primary.opacity(0.08))
                                                    .frame(height: 8)
                                                Capsule()
                                                    .fill(SelfUpStyle.heroGradient)
                                                    .frame(width: max(8, geo.size.width * CGFloat(progress)), height: 8)
                                            }
                                        }
                                        .frame(height: 8)
                                        
                                        HStack {
                                            Spacer()
                                            
                                            Button {
                                                goalToFund = goal
                                            } label: {
                                                HStack(spacing: 4) {
                                                    Image(systemName: "plus")
                                                    Text("Deposit")
                                                }
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(Capsule().fill(SelfUpStyle.primaryIndigo.opacity(0.12)))
                                                .foregroundStyle(SelfUpStyle.primaryIndigo)
                                            }
                                            .pressableScale(scale: 0.92)
                                        }
                                    }
                                    .padding(14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18)
                                            .fill(Color(.secondarySystemGroupedBackground))
                                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18)
                                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                                    )
                                    .contextMenu {
                                        Button {
                                            goalToEdit = goal
                                        } label: {
                                            Label("Edit", systemImage: "pencil")
                                        }
                                        
                                        Button(role: .destructive) {
                                            deleteGoal(goal)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Recent Transactions List
                    VStack(alignment: .leading, spacing: 14) {
                        Text("This Month's Transactions")
                            .font(.system(.title3, design: .rounded))
                            .fontWeight(.bold)
                            .padding(.horizontal)
                        
                        if currentMonthTransactions.isEmpty {
                            ContentUnavailableView(
                                "No Transactions",
                                systemImage: "creditcard",
                                description: Text("Log income or expenses to visualize your monthly cash flow.")
                            )
                            .padding(.vertical, 30)
                        } else {
                            VStack(spacing: 0) {
                                ForEach(currentMonthTransactions) { tx in
                                    TransactionRow(transaction: tx, currencySymbol: currencySymbol)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(Color(.secondarySystemGroupedBackground))
                                        .swipeActions(edge: .leading) {
                                            Button {
                                                transactionToEdit = tx
                                            } label: {
                                                Label("Edit", systemImage: "pencil")
                                            }
                                            .tint(SelfUpStyle.primaryIndigo)
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
                            .clipShape(RoundedRectangle(cornerRadius: 20))
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
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .foregroundStyle(SelfUpStyle.primaryIndigo)
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
            .sheet(isPresented: $showingGoalEditor) {
                SavingGoalEditorView()
            }
            .sheet(item: $goalToEdit) { goal in
                SavingGoalEditorView(goalToEdit: goal)
            }
            .sheet(item: $goalToFund) { goal in
                SavingGoalFundView(goal: goal)
            }
        }
    }
    
    private func delete(_ transaction: Transaction) {
        modelContext.delete(transaction)
        try? modelContext.save()
    }
    
    private func deleteGoal(_ goal: SavingGoal) {
        modelContext.delete(goal)
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
                    .fill(isIncome ? Color.emerald.opacity(0.12) : Color.coral.opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: isIncome ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isIncome ? Color.emerald : Color.coral)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                if !transaction.note.isEmpty {
                    Text(transaction.note)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(isIncome ? "+" : "-")\(currencySymbol) \(transaction.amount, format: .number.precision(.fractionLength(0...2)))")
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundStyle(isIncome ? Color.emerald : .primary)
                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

