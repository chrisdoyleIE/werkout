import SwiftUI

enum MeasurementUnit: String, CaseIterable {
    case metric = "Metric"
    case imperial = "Imperial"
    
    var description: String {
        switch self {
        case .metric: return "Grams, kilograms, litres"
        case .imperial: return "Ounces, pounds, cups"
        }
    }
}

enum TemperatureUnit: String, CaseIterable {
    case celsius = "Celsius"
    case fahrenheit = "Fahrenheit"
    
    var symbol: String {
        switch self {
        case .celsius: return "°C"
        case .fahrenheit: return "°F"
        }
    }
    
    var description: String {
        switch self {
        case .celsius: return "Celsius (°C)"
        case .fahrenheit: return "Fahrenheit (°F)"
        }
    }
}

class SettingsManager: ObservableObject {
    @Published var measurementUnit: MeasurementUnit {
        didSet {
            UserDefaults.standard.set(measurementUnit.rawValue, forKey: "measurementUnit")
        }
    }
    
    @Published var temperatureUnit: TemperatureUnit {
        didSet {
            UserDefaults.standard.set(temperatureUnit.rawValue, forKey: "temperatureUnit")
        }
    }
    
    init() {
        let savedUnit = UserDefaults.standard.string(forKey: "measurementUnit") ?? MeasurementUnit.metric.rawValue
        self.measurementUnit = MeasurementUnit(rawValue: savedUnit) ?? .metric
        
        let savedTempUnit = UserDefaults.standard.string(forKey: "temperatureUnit") ?? TemperatureUnit.celsius.rawValue
        self.temperatureUnit = TemperatureUnit(rawValue: savedTempUnit) ?? .celsius
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsManager = SettingsManager()
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Measurement Units")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Choose your preferred units for shopping lists and recipes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                                Button(action: {
                                    settingsManager.measurementUnit = unit
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(unit.rawValue)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Text(unit.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if settingsManager.measurementUnit == unit {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title3)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.gray.opacity(0.4))
                                                .font(.title3)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        settingsManager.measurementUnit == unit ?
                                        Color.blue.opacity(0.1) : Color.clear
                                    )
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Preferences")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Temperature Units")
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text("Choose temperature scale for cooking instructions")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            ForEach(TemperatureUnit.allCases, id: \.self) { unit in
                                Button(action: {
                                    settingsManager.temperatureUnit = unit
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(unit.rawValue)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primary)
                                            
                                            Text(unit.description)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        if settingsManager.temperatureUnit == unit {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.blue)
                                                .font(.title3)
                                        } else {
                                            Image(systemName: "circle")
                                                .foregroundColor(.gray.opacity(0.4))
                                                .font(.title3)
                                        }
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        settingsManager.temperatureUnit == unit ?
                                        Color.blue.opacity(0.1) : Color.clear
                                    )
                                    .cornerRadius(8)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("About Centad")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        Text("AI-powered meal planning and workout tracking")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text("Version 1.0")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Information")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    SettingsView()
}
