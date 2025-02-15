//
//  BrowseZones.swift
//  HomeKitAutonomic
//
//  Created by Dave Mendlen on 2/14/25.
//

// MARK: - Zone Model
struct BrowseResponse: Codable {
    let items: [ZoneItem]
    
    enum OuterKeys: String, CodingKey {
        case browse
    }
    
    enum BrowseKeys: String, CodingKey {
        case items = "Items"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: OuterKeys.self)
        let browseContainer = try container.nestedContainer(keyedBy: BrowseKeys.self, forKey: .browse)
        items = try browseContainer.decode([ZoneItem].self, forKey: .items)
    }
}




struct ZoneItem: Identifiable, Codable {
    var id: String { guid }
    let zoneId: String
    var isOn: Bool
    var sourceName: String
    let groupName: String
    let name: String
    let guid: String
    let volume: Int?
    let sourceMetaData: SourceMetaData?
    
    // Nested structure for SourceMetaData
    struct SourceMetaData: Codable {
        let artUrl: String?
        let displayLine1: String?
        let displayLine2: String?
        let displayLine3: String?
        let displayLine4: String?
        
        enum CodingKeys: String, CodingKey {
            case artUrl = "ArtUrl"
            case displayLine1 = "DisplayLine1"
            case displayLine2 = "DisplayLine2"
            case displayLine3 = "DisplayLine3"
            case displayLine4 = "DisplayLine4"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case zoneId = "ZoneId"
        case isOn = "IsOn"
        case sourceName = "SourceName"
        case groupName = "GroupName"
        case name = "Name"
        case guid = "Guid"
        case volume = "Volume"
        case sourceMetaData = "SourceMetaData"
    }
}
