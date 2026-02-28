import SwiftUI

// MARK: - Log Detail View
// For viewing and editing logs after voice input
// Philosophy: Allow easy correction without making parents feel like they made a mistake

struct LogDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var logStore = LogStore.shared
    
    let log: Log
    var onSave: ((Log) -> Void)?
    var onDelete: (() -> Void)?
    
    // Editable fields
    @State private var eventType: KeeperConstants.EventType
    @State private var amount: String
    @State private var unit: String
    @State private var subtype: String
    @State private var notes: String
    @State private var time: Date
    @State private var drug: String
    
    @State private var showDeleteConfirm = false
    
    init(log: Log, onSave: ((Log) -> Void)? = nil, onDelete: (() -> Void)? = nil) {
        self.log = log
        self.onSave = onSave
        self.onDelete = onDelete
        
        _eventType = State(initialValue: log.eventType)
        _amount = State(initialValue: log.structuredData?.amount.map { String(format: "%.1f", $0) } ?? "")
        _unit = State(initialValue: log.structuredData?.unit ?? "")
        _subtype = State(initialValue: log.structuredData?.subtype ?? "")
        _notes = State(initialValue: log.structuredData?.notes ?? "")
        _time = State(initialValue: log.structuredData?.time ?? log.createdAt)
        _drug = State(initialValue: log.structuredData?.drug ?? "")
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.midnightSlate
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Event Type Selector
                        eventTypeSection
                        
                        // Type-specific fields
                        switch eventType {
                        case .feed:
                            feedFields
                        case .sleep:
                            sleepFields
                        case .diaper:
                            diaperFields
                        case .medication:
                            medicationFields
                        default:
                            noteFields
                        }
                        
                        // Time picker
                        timeSection
                        
                        // Notes
                        notesSection
                        
                        // Original text (if from voice)
                        if let rawText = log.rawText {
                            originalTextSection(rawText)
                        }
                        
                        // Delete button
                        deleteButton
                    }
                    .padding(20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.dimStar)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.moonlightLavender)
                }
            }
            .alert("Delete Log?", isPresented: $showDeleteConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    onDelete?()
                    dismiss()
                }
            } message: {
                Text("This cannot be undone.")
            }
        }
    }
    
    // MARK: - Event Type Section
    private var eventTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Type")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.dimStar)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach([KeeperConstants.EventType.feed, .sleep, .diaper, .medication, .note], id: \.self) { type in
                    EventTypeButton(
                        type: type,
                        isSelected: eventType == type
                    ) {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            eventType = type
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Feed Fields
    private var feedFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Subtype
            VStack(alignment: .leading, spacing: 8) {
                Text("Feed Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.dimStar)
                
                HStack(spacing: 12) {
                    FeedTypeChip(title: "Breast", isSelected: subtype.contains("breast")) {
                        subtype = "breast"
                    }
                    FeedTypeChip(title: "Bottle", isSelected: subtype == "bottle") {
                        subtype = "bottle"
                    }
                    FeedTypeChip(title: "Solid", isSelected: subtype == "solid") {
                        subtype = "solid"
                    }
                }
            }
            
            // Amount
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Amount")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.dimStar)
                    
                    TextField("0", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.starlightCream)
                        .padding(16)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unit")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.dimStar)
                    
                    Picker("", selection: $unit) {
                        Text("oz").tag("oz")
                        Text("ml").tag("ml")
                        Text("min").tag("min")
                    }
                    .pickerStyle(.segmented)
                    .frame(height: 56)
                }
            }
        }
    }
    
    // MARK: - Sleep Fields
    private var sleepFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Duration")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.dimStar)
                
                HStack(spacing: 16) {
                    TextField("0", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.starlightCream)
                        .padding(16)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    
                    Text("hours")
                        .font(.system(size: 18))
                        .foregroundColor(.dimStar)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Type")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.dimStar)
                
                HStack(spacing: 12) {
                    FeedTypeChip(title: "Nap", isSelected: subtype == "nap") {
                        subtype = "nap"
                    }
                    FeedTypeChip(title: "Night Sleep", isSelected: subtype == "night_sleep") {
                        subtype = "night_sleep"
                    }
                }
            }
        }
    }
    
    // MARK: - Diaper Fields
    private var diaperFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Diaper Type")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.dimStar)
            
            HStack(spacing: 16) {
                DiaperOptionButton(
                    title: "Wet",
                    icon: "drop.fill",
                    color: .blue,
                    isSelected: subtype == "wet"
                ) {
                    subtype = "wet"
                }
                
                DiaperOptionButton(
                    title: "Dirty",
                    icon: "leaf.fill",
                    color: .brown,
                    isSelected: subtype == "dirty"
                ) {
                    subtype = "dirty"
                }
                
                DiaperOptionButton(
                    title: "Both",
                    icon: "circle.grid.2x2.fill",
                    color: .green,
                    isSelected: subtype == "both"
                ) {
                    subtype = "both"
                }
            }
        }
    }
    
    // MARK: - Medication Fields
    private var medicationFields: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Medication")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.dimStar)
                
                TextField("e.g., Tylenol", text: $drug)
                    .font(.system(size: 18))
                    .foregroundColor(.starlightCream)
                    .padding(16)
                    .background(Color.deepSlate)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Dose")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.dimStar)
                    
                    TextField("0", text: $amount)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.starlightCream)
                        .padding(16)
                        .background(Color.deepSlate)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Unit")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.dimStar)
                    
                    Picker("", selection: $unit) {
                        Text("ml").tag("ml")
                        Text("mg").tag("mg")
                        Text("drops").tag("drops")
                    }
                    .pickerStyle(.segmented)
                    .frame(height: 56)
                }
            }
            
            // Safety warning for medication
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.yellow)
                Text("Double-check medication dosages")
                    .font(.system(size: 13))
                    .foregroundColor(.yellow)
            }
            .padding(12)
            .background(Color.yellow.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    // MARK: - Note Fields
    private var noteFields: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What happened?")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.dimStar)
            
            TextEditor(text: $notes)
                .font(.system(size: 16))
                .foregroundColor(.starlightCream)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 120)
                .padding(12)
                .background(Color.deepSlate)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Time Section
    private var timeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.dimStar)
            
            DatePicker(
                "",
                selection: $time,
                displayedComponents: [.date, .hourAndMinute]
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .tint(.moonlightLavender)
        }
    }
    
    // MARK: - Notes Section
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Notes")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.dimStar)
            
            TextField("Optional notes...", text: $notes, axis: .vertical)
                .font(.system(size: 16))
                .foregroundColor(.starlightCream)
                .lineLimit(3...6)
                .padding(12)
                .background(Color.deepSlate)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Original Text Section
    private func originalTextSection(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Original Voice Input")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.dimStar)
            
            Text("\"\(text)\"")
                .font(.system(size: 14, design: .serif))
                .italic()
                .foregroundColor(.dimStar)
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.deepSlate.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Delete Button
    private var deleteButton: some View {
        Button {
            showDeleteConfirm = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "trash")
                Text("Delete Log")
            }
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(.sunsetCoral)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.sunsetCoral.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    // MARK: - Save Changes
    private func saveChanges() {
        let updatedLogData = LogData(
            event: eventType.rawValue,
            subtype: subtype.isEmpty ? nil : subtype,
            amount: Double(amount),
            unit: unit.isEmpty ? nil : unit,
            drug: drug.isEmpty ? nil : drug,
            time: time,
            warning: nil,
            notes: notes.isEmpty ? nil : notes
        )
        
        var updatedLog = log
        updatedLog = Log(
            id: log.id,
            familyId: log.familyId,
            creatorId: log.creatorId,
            stageContext: log.stageContext,
            eventType: eventType,
            rawText: log.rawText,
            structuredData: updatedLogData,
            isConfirmed: true,
            createdAt: log.createdAt,
            clientUpdatedAt: Date(),
            lastModifiedBy: log.creatorId
        )
        
        onSave?(updatedLog)
        dismiss()
    }
}

// MARK: - Supporting Views

struct EventTypeButton: View {
    let type: KeeperConstants.EventType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                Text(type.displayName)
                    .font(.system(size: 12))
            }
            .foregroundColor(isSelected ? .white : .dimStar)
            .frame(maxWidth: .infinity)
            .frame(height: 70)
            .background(isSelected ? Color.moonlightLavender : Color.deepSlate)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct FeedTypeChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isSelected ? .white : .dimStar)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(isSelected ? Color.moonlightLavender : Color.deepSlate)
                .clipShape(Capsule())
        }
    }
}

struct DiaperOptionButton: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color : color.opacity(0.2))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(isSelected ? .white : color)
                }
                
                Text(title)
                    .font(.system(size: 13))
                    .foregroundColor(isSelected ? .starlightCream : .dimStar)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? Color.deepSlate : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? color : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Preview
#Preview {
    LogDetailView(
        log: Log(
            familyId: UUID(),
            creatorId: UUID(),
            eventType: .feed,
            rawText: "He drank 4 ounces of formula",
            structuredData: LogData(
                event: "feed",
                subtype: "bottle",
                amount: 4,
                unit: "oz",
                drug: nil,
                time: Date(),
                warning: nil,
                notes: nil
            ),
            isConfirmed: false
        )
    )
}





