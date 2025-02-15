import Foundation
import HAP
import Logging

fileprivate let logger = Logger(label: "homekit-autonomic")

#if os(Linux)
import Dispatch
#endif

// Define the Autonomic Zones for HomeKit
let zones = [
    ("Loft", "001"),
    ("Kitchen", "002"),
]

// ✅ Create HomeKit Accessories (using Lightbulb for now)
var accessories: [Accessory] = zones.map { (name, serialNumber) in
    let info = Service.Info(name: name, serialNumber: serialNumber, manufacturer: "Autonomic", model: "MAS")
    return AutonomicZoneAccessory(info: info, zoneName: name) // ✅ Use Lightbulb
}

// ✅ Provide valid `Service.Info` for the HomeKit bridge
let bridgeInfo = Service.Info(
    name: "Autonomic Bridge",
    serialNumber: "Bridge-001",
    manufacturer: "Autonomic",
    model: "MAS Bridge"
)

// Create the HomeKit bridge
let device = HAP.Device(
    bridgeInfo: bridgeInfo,
    setupCode: "801-70-700",
    storage: FileStorage(filename: "configuration.json"),
    accessories: accessories
)

do {
    let server = try HAP.Server(device: device, listenPort: 0)

    print("\n📱 Scan this QR code to pair with HomeKit:\n")
    print(device.setupQRCode.asText) // ✅ Now correctly displays the QR code

    while true { RunLoop.current.run(mode: .default, before: .distantFuture) }
} catch {
    logger.error("❌ Failed to start HomeKit server: \(error.localizedDescription)")
}
