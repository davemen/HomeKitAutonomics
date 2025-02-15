import Foundation
import HAP
import Logging

fileprivate let logger = Logger(label: "AutonomicZoneAccessory")

class AutonomicZoneAccessory: HAP.Accessory.Lightbulb {  // ✅ Using Lightbulb
    private let zoneName: String
    private let baseURL = "http://Autonomic.redirectme.net:5005/api"
    private let timer = DispatchSource.makeTimerSource()

    init(info: Service.Info, zoneName: String) {
        self.zoneName = zoneName
        super.init(info: info, type: .monochrome, isDimmable: true) // ✅ Lightbulb instead of Speaker
        
        // ✅ Set initial HomeKit state using `powerState.value`
        self.lightbulb.powerState.value = getZoneState()
        
        // ✅ Set up periodic state updates
        timer.schedule(deadline: .now(), repeating: 60)
        timer.setEventHandler(handler: { [weak self] in
            self?.syncStateWithAutonomic()
        })
        timer.resume()
    }

    deinit {
        timer.cancel()
    }

    /// ✅ Track HomeKit changes
    override func characteristic<T>(_ characteristic: GenericCharacteristic<T>,
                                    ofService service: Service,
                                    didChangeValue newValue: T?) {
        if characteristic === lightbulb.powerState, let newValue = newValue as? Bool {
            logger.info("🔄 HomeKit toggled \(self.zoneName) to \(newValue ? "ON" : "OFF")")
            setZoneState(isOn: newValue) // ✅ Call setZoneState
        }
        super.characteristic(characteristic, ofService: service, didChangeValue: newValue)
    }

    /// ✅ Fetches the power state from Autonomic API.
    private func getZoneState() -> Bool {
        guard let browseUrl = URL(string: "\(baseURL)/api/mrad.browsezones"),
              let bareApiUrl = URL(string: "\(baseURL)/api/") else {
            logger.error("❌ Invalid URL for getting zone state.")
            return false
        }

        let semaphore = DispatchSemaphore(value: 0)
        var isOn = false

        func fetchZoneState(from url: URL, completion: @escaping (BrowseResponse?) -> Void) {
            var request = URLRequest(url: url)
            request.httpMethod = "GET"

            let task = URLSession.shared.dataTask(with: request) { data, _, _ in
                defer { semaphore.signal() }

                if let data = data {
                    do {
                        let decodedResponse = try JSONDecoder().decode(BrowseResponse.self, from: data)
                        completion(decodedResponse)
                    } catch {
                        logger.error("❌ Failed to decode JSON: \(error.localizedDescription)")
                        completion(nil)
                    }
                } else {
                    completion(nil)
                }
            }
            task.resume()
        }

        // Step 1: Get initial zone list
        fetchZoneState(from: browseUrl) { response in
            if let zones = response?.items {
                if let zone = zones.first(where: { $0.name == self.zoneName }) {
                    isOn = zone.isOn
                }
            }
        }
        semaphore.wait()

        // Step 2: Get real-time updates from bare API
        fetchZoneState(from: bareApiUrl) { response in
            if let zones = response?.items {
                if let zone = zones.first(where: { $0.name == self.zoneName }) {
                    isOn = zone.isOn
                }
            }
        }
        semaphore.wait()

        return isOn
    }

    /// ✅ Sends a request to update zone power state.
    private func setZoneState(isOn: Bool) {
        let command = "mrad.SetZone \(zoneName)/mrad.power \(isOn ? "On" : "Off")/setinstance main/"
        guard let url = URL(string: "\(baseURL)/Script/\(command)") else {
            logger.error("❌ Invalid URL for setting zone state.")
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        URLSession.shared.dataTask(with: request).resume()
    }

    /// ✅ Syncs HomeKit state with the Autonomic API.
    private func syncStateWithAutonomic() {
        let currentState = getZoneState()
        if self.lightbulb.powerState.value != currentState {
            self.lightbulb.powerState.value = currentState
            logger.info("🔄 Synced HomeKit state for \(self.zoneName) to \(currentState ? "ON" : "OFF")")
        }
    }
}
