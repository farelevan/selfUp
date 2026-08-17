import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var habits: [Habit]
    @Query private var tasks: [TaskItem]
    @Query private var transactions: [Transaction]
    
    @State private var selectedCurrency = "Rp"
    @State private var showingExport = false
    @State private var showingImport = false
    @State private var exportDocument: JSONDocument? = nil
    @State private var importErrorMessage: String? = nil
    @State private var showOverwriteConfirmation = false
    @State private var pendingPayload: BackupPayload? = nil
    @State private var showingSuccessAlert = false
    @State private var successAlertMessage = ""
    
    let currencies = [
        ("IDR (Rp)", "Rp"),
        ("USD ($)", "$"),
        ("EUR (€)", "€"),
        ("GBP (£)", "£"),
        ("JPY (¥)", "¥")
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Configuration")) {
                    Picker("Currency", selection: $selectedCurrency) {
                        ForEach(currencies, id: \.1) { label, code in
                            Text(label).tag(code)
                        }
                    }
                    .onChange(of: selectedCurrency) { _, newValue in
                        UserDefaults.standard.set(newValue, forKey: "selected_currency")
                    }
                }
                
                Section(header: Text("Demo Data")) {
                    Button("Seed Demo Dataset") {
                        seedDemoData()
                    }
                    .foregroundStyle(.blue)
                }
                
                Section(header: Text("Data Backup & Restore"), footer: Text("Importing data will replace all current habits, tasks, and transactions.")) {
                    Button {
                        prepareExport()
                    } label: {
                        Label("Export Data to JSON", systemImage: "square.and.arrow.up")
                    }
                    
                    Button {
                        showingImport = true
                    } label: {
                        Label("Import Data from JSON", systemImage: "square.and.arrow.down")
                    }
                    .foregroundStyle(.red)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                selectedCurrency = UserDefaults.standard.string(forKey: "selected_currency") ?? "Rp"
            }
            .fileExporter(isPresented: $showingExport, document: exportDocument, contentType: .json, defaultFilename: "SelfUpBackup") { result in
                switch result {
                case .success(let url):
                    print("Exported to \(url)")
                case .failure(let error):
                    print("Failed to export: \(error)")
                }
            }
            .fileImporter(isPresented: $showingImport, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url):
                    handleImport(url: url)
                case .failure(let error):
                    importErrorMessage = error.localizedDescription
                }
            }
            .alert("Confirm Overwrite", isPresented: $showOverwriteConfirmation) {
                Button("Cancel", role: .cancel) {
                    pendingPayload = nil
                }
                Button("Overwrite", role: .destructive) {
                    applyPendingPayload()
                }
            } message: {
                Text("This action cannot be undone. All existing local data will be replaced.")
            }
            .alert("Success", isPresented: $showingSuccessAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(successAlertMessage)
            }
            .alert("Import Error", isPresented: Binding<Bool>(
                get: { importErrorMessage != nil },
                set: { if !$0 { importErrorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(importErrorMessage ?? "")
            }
        }
    }
    
    private func prepareExport() {
        let habitBackups = habits.map { h in
            HabitBackup(
                id: h.id,
                title: h.title,
                symbol: h.symbol,
                tintName: h.tintName,
                xpReward: h.xpReward,
                isArchived: h.isArchived,
                createdAt: h.createdAt,
                completions: h.completions.map { $0.date },
                scheduledWeekdays: h.scheduledWeekdays,
                reminderHour: h.reminderHour,
                reminderMinute: h.reminderMinute
            )
        }
        
        let taskBackups = tasks.map { t in
            TaskBackup(
                id: t.id,
                title: t.title,
                dueDate: t.dueDate,
                priority: t.priority.rawValue,
                completedAt: t.completedAt,
                xpReward: t.xpReward,
                period: t.effectivePeriod.rawValue,
                workflowStatus: t.effectiveStatus.rawValue,
                startedAt: t.startedAt,
                recurrence: t.effectiveRecurrence.rawValue,
                reminderHour: t.reminderHour,
                reminderMinute: t.reminderMinute
            )
        }
        
        let txBackups = transactions.map { tx in
            TransactionBackup(
                id: tx.id,
                amount: tx.amount,
                type: tx.type.rawValue,
                category: tx.category,
                note: tx.note,
                date: tx.date
            )
        }
        
        let payload = BackupPayload(habits: habitBackups, transactions: txBackups, tasks: taskBackups)
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        encoder.outputFormatting = .prettyPrinted
        
        do {
            let data = try encoder.encode(payload)
            exportDocument = JSONDocument(data: data)
            showingExport = true
        } catch {
            importErrorMessage = "Failed to encode backup payload: \(error.localizedDescription)"
        }
    }
    
    private func handleImport(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importErrorMessage = "Failed to access backup file security scope."
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        
        do {
            let data = try Data(contentsOf: url)
            let payload = try BackupService.validateImport(data)
            pendingPayload = payload
            showOverwriteConfirmation = true
        } catch {
            importErrorMessage = "Import validation failed: \(error.localizedDescription)"
        }
    }
    
    private func applyPendingPayload() {
        guard let payload = pendingPayload else { return }
        
        for h in habits { modelContext.delete(h) }
        for t in tasks { modelContext.delete(t) }
        for tx in transactions { modelContext.delete(tx) }
        
        for hb in payload.habits {
            let h = Habit(
                title: hb.title,
                symbol: hb.symbol,
                tintName: hb.tintName,
                xpReward: hb.xpReward,
                isArchived: hb.isArchived,
                createdAt: hb.createdAt,
                scheduledWeekdays: hb.scheduledWeekdays ?? 0,
                reminderHour: hb.reminderHour,
                reminderMinute: hb.reminderMinute
            )
            h.id = hb.id
            modelContext.insert(h)
            
            for date in hb.completions {
                let comp = HabitCompletion(date: date, habit: h)
                modelContext.insert(comp)
                h.completions.append(comp)
            }
        }
        
        for tb in payload.tasks {
            let priority = TaskPriority(rawValue: tb.priority) ?? .medium
            let t = TaskItem(
                title: tb.title,
                dueDate: tb.dueDate,
                priority: priority,
                completedAt: tb.completedAt,
                xpReward: tb.xpReward,
                period: tb.period.flatMap(TaskPeriod.init(rawValue:)) ?? .inbox,
                workflowStatus: tb.workflowStatus.flatMap(TaskWorkflowStatus.init(rawValue:)) ?? .planned,
                startedAt: tb.startedAt,
                recurrence: tb.recurrence.flatMap(TaskRecurrence.init(rawValue:)) ?? .none,
                reminderHour: tb.reminderHour,
                reminderMinute: tb.reminderMinute
            )
            t.id = tb.id
            modelContext.insert(t)
        }
        
        for txb in payload.transactions {
            let type = TransactionType(rawValue: txb.type) ?? .expense
            let tx = Transaction(
                amount: txb.amount,
                type: type,
                category: txb.category,
                note: txb.note,
                date: txb.date
            )
            tx.id = txb.id
            modelContext.insert(tx)
        }
        
        do {
            try modelContext.save()
            successAlertMessage = "Data successfully imported!"
            showingSuccessAlert = true
        } catch {
            importErrorMessage = "Failed to save imported data: \(error.localizedDescription)"
        }
        
        pendingPayload = nil
    }
    
    private func seedDemoData() {
        for h in habits { modelContext.delete(h) }
        for t in tasks { modelContext.delete(t) }
        for tx in transactions { modelContext.delete(tx) }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let twoDaysAgo = calendar.date(byAdding: .day, value: -2, to: today)!
        
        let h1 = Habit(title: "Drink Water", symbol: "drop.fill", tintName: "blue")
        let h2 = Habit(title: "Read a Book", symbol: "book.fill", tintName: "purple")
        let h3 = Habit(title: "Daily Exercise", symbol: "bolt.fill", tintName: "orange")
        
        modelContext.insert(h1)
        modelContext.insert(h2)
        modelContext.insert(h3)
        
        let c1_1 = HabitCompletion(date: today, habit: h1)
        let c1_2 = HabitCompletion(date: yesterday, habit: h1)
        let c1_3 = HabitCompletion(date: twoDaysAgo, habit: h1)
        h1.completions.append(contentsOf: [c1_1, c1_2, c1_3])
        
        let c2_1 = HabitCompletion(date: today, habit: h2)
        h2.completions.append(c2_1)
        
        let t1 = TaskItem(title: "Submit Tax Report", dueDate: today, priority: .high)
        let t2 = TaskItem(title: "Buy Groceries", dueDate: today, priority: .medium, completedAt: today)
        let t3 = TaskItem(title: "Plan Weekend Trip", dueDate: calendar.date(byAdding: .day, value: 3, to: today), priority: .low)
        
        modelContext.insert(t1)
        modelContext.insert(t2)
        modelContext.insert(t3)
        
        let tx1 = Transaction(amount: 150000, type: .expense, category: "Food", note: "Dinner at restaurant", date: today)
        let tx2 = Transaction(amount: 2500000, type: .income, category: "Salary", note: "Monthly paycheck", date: yesterday)
        let tx3 = Transaction(amount: 85000, type: .expense, category: "Transport", note: "Taxi ride", date: twoDaysAgo)
        
        modelContext.insert(tx1)
        modelContext.insert(tx2)
        modelContext.insert(tx3)
        
        do {
            try modelContext.save()
            successAlertMessage = "Demo data successfully seeded!"
            showingSuccessAlert = true
        } catch {
            importErrorMessage = "Failed to seed demo data: \(error.localizedDescription)"
        }
    }
}

struct JSONDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    
    var data: Data
    
    init(data: Data) {
        self.data = data
    }
    
    init(configuration: ReadConfiguration) throws {
        if let d = configuration.file.regularFileContents {
            self.data = d
        } else {
            self.data = Data()
        }
    }
    
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
