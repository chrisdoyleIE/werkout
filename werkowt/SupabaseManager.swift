import Foundation
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // Configure JSONDecoder for Supabase date format
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateString = try container.decode(String.self)
            
            // Try ISO8601 with fractional seconds first
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Try ISO8601 without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: dateString) {
                return date
            }
            
            // Try a custom formatter for PostgreSQL timestamp format
            let customFormatter = DateFormatter()
            customFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
            customFormatter.timeZone = TimeZone(identifier: "UTC")
            if let date = customFormatter.date(from: dateString) {
                return date
            }
            
            // Try date-only format
            customFormatter.dateFormat = "yyyy-MM-dd"
            if let date = customFormatter.date(from: dateString) {
                return date
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
        }
        
        // Configure JSONEncoder for consistent date encoding
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime]
            let dateString = formatter.string(from: date)
            try container.encode(dateString)
        }
        
        client = SupabaseClient(
            supabaseURL: URL(string: Config.supabaseURL)!,
            supabaseKey: Config.supabaseAnonKey,
            options: SupabaseClientOptions(
                db: .init(
                    encoder: encoder,
                    decoder: decoder
                )
            )
        )
    }
}
