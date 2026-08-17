import SwiftUI
import SwiftData
import UIKit

struct MoneyView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query(sort: \SavingGoal.createdAt) private var savingGoals: [SavingGoal]
    
    @State private var showingEditor = false
    @State private var transactionToEdit: Transaction? = nil
    @State private var showingSettings = false
    @State private var showingGoalEditor = false
    @State private var goalToEdit: SavingGoal? = nil
    @State private var goalToFund: SavingGoal? = nil
    @State private var showingFunBudgetEditor = false
    @State private var funBudgetNow = Date()
    @State private var funBudgetNotificationMessage: String? = nil
    @State private var funBudgetPermissionDenied = false
    
    private var currencySymbol: String {
        UserDefaults.standard.string(forKey: "selected_currency") ?? "Rp"
    }
    
    private var currentMonthTransactions: [Transaction] {
        let calendar = Calendar.current
        guard let interval = calendar.dateInterval(of: .month, for: funBudgetNow) else { return [] }
        return transactions.filter { interval.contains($0.date) && $0.date <= funBudgetNow }
    }
    
    private var summary: MoneySummary {
        MoneySummaryService.summary(for: currentMonthTransactions)
    }
    
    private var expenseRatio: Double {
        if summary.income == 0 { return summary.expenses > 0 ? 1.0 : 0.0 }
        return min(1.0, Double(truncating: (summary.expenses / summary.income) as NSDecimalNumber))
    }

    private var funBudgetStore: FunBudgetStore { FunBudgetStore() }

    private var funBudgetSnapshot: FunBudgetSnapshot {
        FunBudgetService.snapshot(
            for: transactions,
            limit: funBudgetStore.limit,
            now: funBudgetNow,
            calendar: .autoupdatingCurrent
        )
    }

    private var funBudgetProgress: Double {
        min(1, max(0, Double(truncating: funBudgetSnapshot.progress as NSDecimalNumber)))
    }

    private var funBudgetUsagePercentage: Double {
        max(0, Double(truncating: funBudgetSnapshot.progress as NSDecimalNumber) * 100)
    }

    private var funBudgetMonthLabel: String {
        funBudgetNow.formatted(.dateTime.month(.wide))
    }

    private var funBudgetDayContext: String {
        let calendar = Calendar.autoupdatingCurrent
        let day = calendar.component(.day, from: funBudgetNow)
        let daysInMonth = calendar.range(of: .day, in: .month, for: funBudgetNow)?.count ?? day
        let daysLeft = max(0, daysInMonth - day)
        return "Day \(day) of \(daysInMonth) • \(daysLeft) day\(daysLeft == 1 ? "" : "s") left"
    }

    private var funBudgetAttentionColor: Color {
        switch funBudgetSnapshot.attention {
        case .unconfigured: SelfUpStyle.brand
        case .onTrack: SelfUpStyle.success
        case .nearlyDepleted: SelfUpStyle.warning
        case .depleted: SelfUpStyle.danger
        }
    }

    private var funBudgetAttentionIcon: String {
        switch funBudgetSnapshot.attention {
        case .unconfigured: "plus.circle.fill"
        case .onTrack: "checkmark.circle.fill"
        case .nearlyDepleted: "exclamationmark.triangle.fill"
        case .depleted: "exclamationmark.octagon.fill"
        }
    }

    private var funBudgetAttentionText: String {
        switch funBudgetSnapshot.attention {
        case .unconfigured:
            "Set a monthly limit to track Entertainment spending."
        case .onTrack:
            "On track"
        case .nearlyDepleted:
            "Nearly depleted — \(formattedFunBudgetAmount(funBudgetSnapshot.remaining)) left"
        case .depleted where funBudgetSnapshot.overage > 0:
            "Over budget by \(formattedFunBudgetAmount(funBudgetSnapshot.overage))"
        case .depleted:
            "Budget depleted"
        }
    }

    private var funBudgetTransactionSignature: String {
        transactions.map { transaction in
            [
                transaction.id.uuidString,
                NSDecimalNumber(decimal: transaction.amount).stringValue,
                transaction.type.rawValue,
                transaction.category,
                String(transaction.date.timeIntervalSinceReferenceDate)
            ].joined(separator: "|")
        }.joined(separator: ";")
    }

    private func formattedFunBudgetAmount(_ amount: Decimal) -> String {
        "\(currencySymbol) \(NSDecimalNumber(decimal: amount).stringValue)"
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
                                    .foregroundStyle(SelfUpStyle.brand)
                                    .tracking(1)
                                
                                Text("\(currencySymbol) \(summary.net, format: .number.precision(.fractionLength(0...2)))")
                                    .font(.system(size: 34, weight: .bold, design: .default))
                                    .foregroundStyle(summary.net >= 0 ? SelfUpStyle.success : SelfUpStyle.danger)
                            }
                            Spacer()
                            
                            ZStack {
                                Circle()
                                    .fill((summary.net >= 0 ? SelfUpStyle.success : SelfUpStyle.danger).opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: summary.net >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(summary.net >= 0 ? SelfUpStyle.success : SelfUpStyle.danger)
                            }
                        }
                        
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: SelfUpStyle.spacingLG) {
                                flowMetric(title: "Income", amount: summary.income, symbol: "arrow.down.left.circle.fill", color: SelfUpStyle.success)
                                flowMetric(title: "Expenses", amount: summary.expenses, symbol: "arrow.up.right.circle.fill", color: SelfUpStyle.danger)
                            }
                            VStack(spacing: SelfUpStyle.spacingSM) {
                                flowMetric(title: "Income", amount: summary.income, symbol: "arrow.down.left.circle.fill", color: SelfUpStyle.success)
                                flowMetric(title: "Expenses", amount: summary.expenses, symbol: "arrow.up.right.circle.fill", color: SelfUpStyle.danger)
                            }
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
                                    .foregroundStyle(expenseRatio > 0.8 ? SelfUpStyle.danger : (expenseRatio > 0.5 ? SelfUpStyle.warning : SelfUpStyle.success))
                            }
                            
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.primary.opacity(0.08))
                                        .frame(height: 8)
                                    Capsule()
                                        .fill(expenseRatio > 0.8 ? SelfUpStyle.danger : (expenseRatio > 0.5 ? SelfUpStyle.warning : SelfUpStyle.success))
                                        .frame(width: expenseRatio == 0 ? 0 : max(8, geo.size.width * CGFloat(expenseRatio)), height: 8)
                                        .animation(reduceMotion ? nil : .spring(response: 0.6, dampingFraction: 0.7), value: expenseRatio)
                                }
                            }
                            .frame(height: 8)
                        }
                    }
                    .premiumCard(cornerRadius: 18)
                    .padding(.horizontal)

                    funBudgetCard
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
                                .font(.system(.title3, design: .default))
                                .fontWeight(.bold)
                            Spacer()
                            Button {
                                showingGoalEditor = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                    .foregroundStyle(SelfUpStyle.brand)
                                    .frame(width: SelfUpStyle.Control.minimumTapTarget, height: SelfUpStyle.Control.minimumTapTarget)
                            }
                            .accessibilityLabel("Add saving goal")
                        }
                        .padding(.horizontal)
                        
                        if savingGoals.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "target")
                                    .font(.largeTitle)
                                    .foregroundStyle(SelfUpStyle.brand.opacity(0.6))
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
                                        .frame(minHeight: SelfUpStyle.Control.minimumTapTarget)
                                        .background(Capsule().fill(SelfUpStyle.brandFill))
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
                                                    .font(.system(.headline, design: .default))
                                                    .fontWeight(.bold)
                                                Text("\(currencySymbol) \(goal.currentAmount, format: .number) of \(currencySymbol) \(goal.targetAmount, format: .number)")
                                                    .font(.caption)
                                                    .foregroundStyle(.secondary)
                                            }
                                            Spacer()
                                            Text("\(progress * 100, format: .number.precision(.fractionLength(0)))%")
                                                .font(.system(.callout, design: .default))
                                                .fontWeight(.bold)
                                                .foregroundStyle(SelfUpStyle.brand)
                                        }
                                        
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Capsule()
                                                    .fill(Color.primary.opacity(0.08))
                                                    .frame(height: 8)
                                                Capsule()
                                                    .fill(SelfUpStyle.heroGradient)
                                                    .frame(width: progress == 0 ? 0 : max(8, geo.size.width * CGFloat(progress)), height: 8)
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
                                                .frame(minHeight: SelfUpStyle.Control.minimumTapTarget)
                                                .background(Capsule().fill(SelfUpStyle.brand.opacity(0.12)))
                                                .foregroundStyle(SelfUpStyle.brand)
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
                            .font(.system(.title3, design: .default))
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
                                            .tint(SelfUpStyle.brandFill)
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
                            .foregroundStyle(SelfUpStyle.brand)
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
            .sheet(isPresented: $showingFunBudgetEditor) {
                FunBudgetEditorView(
                    currencySymbol: currencySymbol,
                    initialLimit: funBudgetStore.limit,
                    initialNotificationsEnabled: funBudgetStore.notificationsEnabled,
                    onSave: saveFunBudget
                )
            }
        }
        .task { await reconcileFunBudget() }
        .onChange(of: funBudgetTransactionSignature) { _, _ in
            funBudgetNow = Date()
            Task { await reconcileFunBudget() }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .active else { return }
            funBudgetNow = Date()
            Task { await reconcileFunBudget() }
        }
    }

    private func flowMetric(title: String, amount: Decimal, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: SelfUpStyle.Spacing.xSmall) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(currencySymbol) \(amount, format: .number)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(SelfUpStyle.spacingMD)
        .background(RoundedRectangle(cornerRadius: SelfUpStyle.Radius.small).fill(color.opacity(0.08)))
        .accessibilityElement(children: .combine)
    }

    private var funBudgetCard: some View {
        VStack(alignment: .leading, spacing: SelfUpStyle.Spacing.medium) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: SelfUpStyle.Spacing.xSmall) {
                    Text("Fun budget (Entertainment)")
                        .font(.headline)
                    Text("\(funBudgetMonthLabel) recurring monthly budget")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(funBudgetSnapshot.isConfigured ? "Edit" : "Set budget") {
                    showingFunBudgetEditor = true
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(SelfUpStyle.brand)
                .frame(minWidth: SelfUpStyle.Control.minimumTapTarget, minHeight: SelfUpStyle.Control.minimumTapTarget)
            }

            if funBudgetSnapshot.isConfigured {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: SelfUpStyle.Spacing.large) {
                        funBudgetAmountMetric(
                            label: "SPENT",
                            amount: funBudgetSnapshot.spent,
                            color: .primary,
                            alignment: .leading
                        )
                        Spacer()
                        funBudgetAmountMetric(
                            label: "LIMIT",
                            amount: funBudgetSnapshot.limit,
                            color: .primary,
                            alignment: .center
                        )
                        Spacer()
                        funBudgetAmountMetric(
                            label: funBudgetSnapshot.overage > 0 ? "OVER" : "REMAINING",
                            amount: funBudgetSnapshot.overage > 0 ? funBudgetSnapshot.overage : funBudgetSnapshot.remaining,
                            color: funBudgetAttentionColor,
                            alignment: .trailing
                        )
                    }

                    VStack(alignment: .leading, spacing: SelfUpStyle.Spacing.medium) {
                        funBudgetAmountMetric(
                            label: "SPENT",
                            amount: funBudgetSnapshot.spent,
                            color: .primary,
                            alignment: .leading
                        )
                        funBudgetAmountMetric(
                            label: "LIMIT",
                            amount: funBudgetSnapshot.limit,
                            color: .primary,
                            alignment: .leading
                        )
                        funBudgetAmountMetric(
                            label: funBudgetSnapshot.overage > 0 ? "OVER" : "REMAINING",
                            amount: funBudgetSnapshot.overage > 0 ? funBudgetSnapshot.overage : funBudgetSnapshot.remaining,
                            color: funBudgetAttentionColor,
                            alignment: .leading
                        )
                    }
                }

                VStack(alignment: .leading, spacing: SelfUpStyle.Spacing.xSmall) {
                    HStack {
                        Text("\(funBudgetUsagePercentage, format: .number.precision(.fractionLength(0)))% used")
                            .font(.caption.weight(.semibold))
                        Spacer()
                        Text(funBudgetDayContext)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    ProgressView(value: funBudgetProgress)
                        .tint(funBudgetAttentionColor)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Fun budget used")
                .accessibilityValue("\(funBudgetUsagePercentage, format: .number.precision(.fractionLength(0))) percent. \(funBudgetDayContext)")

                HStack(spacing: SelfUpStyle.Spacing.small) {
                    Image(systemName: funBudgetAttentionIcon)
                    Text(funBudgetAttentionText)
                        .font(.caption.weight(.semibold))
                    Spacer(minLength: 0)
                }
                .foregroundStyle(funBudgetAttentionColor)
                .padding(.horizontal, SelfUpStyle.Spacing.medium)
                .padding(.vertical, SelfUpStyle.Spacing.small)
                .background(funBudgetAttentionColor.opacity(0.1), in: Capsule())

                HStack(spacing: SelfUpStyle.Spacing.small) {
                    Image(systemName: funBudgetStore.notificationsEnabled ? "bell.fill" : "bell.slash")
                    Text(funBudgetStore.notificationsEnabled ? "80% warning enabled" : "80% warning off")
                    Spacer()
                    if funBudgetPermissionDenied {
                        Button("Open Settings") { openNotificationSettings() }
                            .fontWeight(.semibold)
                            .frame(minHeight: SelfUpStyle.Control.minimumTapTarget)
                    }
                }
                .font(.caption)
                .foregroundStyle(funBudgetPermissionDenied ? SelfUpStyle.danger : Color.secondary)
            } else {
                Text(funBudgetAttentionText)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Button {
                    showingFunBudgetEditor = true
                } label: {
                    Label("Set fun budget", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: SelfUpStyle.Control.minimumTapTarget)
                }
                .buttonStyle(.borderedProminent)
                .tint(SelfUpStyle.brandFill)
            }

            if let funBudgetNotificationMessage {
                Text(funBudgetNotificationMessage)
                    .font(.caption)
                    .foregroundStyle(funBudgetPermissionDenied ? SelfUpStyle.danger : .secondary)
            }
        }
        .premiumCard(cornerRadius: SelfUpStyle.Radius.medium)
    }

    private func saveFunBudget(limit: Decimal, notificationsEnabled: Bool) {
        let store = funBudgetStore
        store.limit = limit
        store.notificationsEnabled = notificationsEnabled
        funBudgetNow = Date()
        funBudgetNotificationMessage = nil
        funBudgetPermissionDenied = false

        Task {
            if notificationsEnabled {
                switch await NotificationManager.requestFunBudgetAuthorization() {
                case .authorized:
                    break
                case .denied:
                    funBudgetPermissionDenied = true
                    funBudgetNotificationMessage = "Allow notifications in Settings to receive the mid-month warning."
                case .failed(let message):
                    funBudgetNotificationMessage = "Could not request notifications: \(message)"
                }
            }
            await reconcileFunBudget()
        }
    }

    private func funBudgetAmountMetric(
        label: String,
        amount: Decimal,
        color: Color,
        alignment: HorizontalAlignment
    ) -> some View {
        VStack(alignment: alignment, spacing: SelfUpStyle.Spacing.xxSmall) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
            Text("\(currencySymbol) \(amount, format: .number.precision(.fractionLength(0...2)))")
                .font(.title3.weight(.bold))
                .foregroundStyle(color)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func reconcileFunBudget(using transactionsToEvaluate: [Transaction]? = nil) async {
        let result = await NotificationManager.reconcileFunBudget(
            transactions: transactionsToEvaluate ?? transactions,
            currencySymbol: currencySymbol,
            now: funBudgetNow,
            calendar: .autoupdatingCurrent
        )

        switch result {
        case .notAuthorized:
            funBudgetPermissionDenied = funBudgetStore.notificationsEnabled
            if funBudgetPermissionDenied {
                funBudgetNotificationMessage = "Allow notifications in Settings to receive the mid-month warning."
            }
        case .failed(let message):
            funBudgetNotificationMessage = "Could not update the warning: \(message)"
        case .scheduled:
            funBudgetPermissionDenied = false
            funBudgetNotificationMessage = "Warning scheduled for the 15th at 9:00 AM."
        case .notified:
            funBudgetPermissionDenied = false
            funBudgetNotificationMessage = "This month's fun-budget warning was sent."
        case .cancelled, .notificationsDisabled:
            funBudgetPermissionDenied = false
            funBudgetNotificationMessage = nil
        case .unchanged:
            break
        }
    }

    private func openNotificationSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
    
    private func delete(_ transaction: Transaction) {
        modelContext.delete(transaction)
        do {
            try modelContext.save()
            let savedTransactions = try modelContext.fetch(FetchDescriptor<Transaction>())
            funBudgetNow = Date()
            Task { await reconcileFunBudget(using: savedTransactions) }
        } catch {
            funBudgetNotificationMessage = "Could not save the transaction change."
        }
    }
    
    private func deleteGoal(_ goal: SavingGoal) {
        modelContext.delete(goal)
        try? modelContext.save()
    }
}

private struct FunBudgetEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let currencySymbol: String
    let onSave: (Decimal, Bool) -> Void

    @State private var limitText: String
    @State private var notificationsEnabled: Bool
    @State private var errorMessage: String?

    init(
        currencySymbol: String,
        initialLimit: Decimal,
        initialNotificationsEnabled: Bool,
        onSave: @escaping (Decimal, Bool) -> Void
    ) {
        self.currencySymbol = currencySymbol
        self.onSave = onSave
        _limitText = State(
            initialValue: initialLimit > 0
                ? NSDecimalNumber(decimal: initialLimit).stringValue
                : ""
        )
        _notificationsEnabled = State(initialValue: initialNotificationsEnabled)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text(currencySymbol)
                            .foregroundStyle(.secondary)
                        TextField("0", text: $limitText)
                            .keyboardType(.decimalPad)
                            .accessibilityIdentifier("fun_budget_limit_field")
                    }
                } header: {
                    Text("Monthly limit")
                } footer: {
                    Text("Entertainment expenses reset against this limit each calendar month.")
                }

                Section {
                    Toggle("Mid-month 80% warning", isOn: $notificationsEnabled)
                } header: {
                    Text("Warning")
                } footer: {
                    Text("If 80% is used early, SelfUp schedules one warning for the 15th at 9:00 AM. If it happens later, the warning is immediate. Enabling this asks for notification permission.")
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(SelfUpStyle.danger)
                    }
                }
            }
            .navigationTitle("Fun budget (Entertainment)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let normalized = limitText.replacingOccurrences(of: ",", with: ".")
        guard let limit = Decimal(
            string: normalized,
            locale: Locale(identifier: "en_US_POSIX")
        ), limit > 0 else {
            errorMessage = "Enter a monthly limit greater than zero."
            return
        }

        onSave(limit, notificationsEnabled)
        dismiss()
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
                    .fill((isIncome ? SelfUpStyle.success : SelfUpStyle.danger).opacity(0.12))
                    .frame(width: 42, height: 42)
                Image(systemName: isIncome ? "arrow.down.left.circle.fill" : "arrow.up.right.circle.fill")
                    .font(.title3)
                    .foregroundStyle(isIncome ? SelfUpStyle.success : SelfUpStyle.danger)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.category)
                    .font(.system(.subheadline, design: .default))
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
                    .font(.system(.subheadline, design: .default))
                    .fontWeight(.bold)
                    .foregroundStyle(isIncome ? SelfUpStyle.success : .primary)
                Text(transaction.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
