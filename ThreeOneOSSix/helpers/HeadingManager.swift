import Foundation
import CoreLocation
import Combine

final class HeadingManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published var heading: Double = 0
    @Published var coordinate: CLLocationCoordinate2D?
    @Published var altitude: Double = 0
    @Published var placeName: String = ""

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var lastGeocodeTime: Date = .distantPast

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.headingFilter = 1
        manager.distanceFilter = 10
    }

    func start() {
        manager.requestWhenInUseAuthorization()
        if CLLocationManager.headingAvailable() {
            manager.startUpdatingHeading()
        }
        manager.startUpdatingLocation()
    }

    func stop() {
        manager.stopUpdatingHeading()
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        guard newHeading.headingAccuracy >= 0 else { return }
        heading = newHeading.trueHeading > 0 ? newHeading.trueHeading : newHeading.magneticHeading
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        coordinate = location.coordinate
        altitude = location.altitude

        let now = Date()
        guard now.timeIntervalSince(lastGeocodeTime) > 5 else { return }
        lastGeocodeTime = now
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            if let place = placemarks?.first {
                DispatchQueue.main.async {
                    self?.placeName = place.locality
                        ?? place.administrativeArea
                        ?? place.country
                        ?? ""
                }
            }
        }
    }
}
