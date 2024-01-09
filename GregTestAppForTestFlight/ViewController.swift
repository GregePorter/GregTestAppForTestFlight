//
//  ViewController.swift
//  GregTestAppForTestFlight
//
//  Created by Gregory Porter on 12/18/23.
//

import UIKit
import MapKit
import CoreLocation
import UserNotifications

class ViewController: UIViewController {
    
    private var neighborhoods: [MKPolygon: String] = [:];
    private var timer: Timer?;
    let center = UNUserNotificationCenter.current();
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //self.testCoords();
        //self.handleGeojson();
//         timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) {_ in
//              print("function timer")
//          }
//
//        self.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
//            print("global timer")
//        }
//
        let id = UUID().uuidString;
        self.requestNotificationAuthorization()
        self.sendNotification(notificationId: id);
        self.clearInitialNotification(notificationId: id)
    }
    
    //deletes the first notification after 10 seconds
    func clearInitialNotification(notificationId: String) {
        _ =  Timer.scheduledTimer(withTimeInterval: 10, repeats: false) {_ in
            self.timer?.invalidate() //invalidate that logging timer
            let center = UNUserNotificationCenter.current(); //get current notificationCenter
            center.removeDeliveredNotifications(withIdentifiers: [notificationId]) //remove the specified notification
          }
    }
    
    func requestNotificationAuthorization() {
        let authOptions = UNAuthorizationOptions.init(arrayLiteral: .alert, .badge, .sound)
        self.center.requestAuthorization(options: authOptions) { (success, error) in
            if let error = error {
                print("Error: ", error)
            }
        }
    }
    
    //actually sends two notifications after a 5 second delay
    func sendNotification(notificationId: String) {
        let content = UNMutableNotificationContent()
        content.title = "Late wake up call"
        content.body = "The early bird catches the worm, but the second mouse gets the cheese."
        content.categoryIdentifier = "alarm"
        content.userInfo = ["customData": "fizzbuzz"]
        content.sound = UNNotificationSound.default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request = UNNotificationRequest(identifier: notificationId, content: content, trigger: trigger)
        
        center.add(request) { (error) in
            if let error = error {
                print("Notification Error: ", error)
            }
        }
        
        let content_two = UNMutableNotificationContent()
        content_two.title = "This is another notification"
        content_two.body = "Blah blah blah."
        content_two.categoryIdentifier = "alarm"
        content_two.userInfo = ["customData": "fizzbuzz"]
        content_two.sound = UNNotificationSound.default

        let trigger_two = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)

        let request_two = UNNotificationRequest(identifier: UUID().uuidString, content: content_two, trigger: trigger_two)
        center.add(request_two)
        
        //print out the current list of notifications - for testing
//        center.getPendingNotificationRequests(completionHandler: { requests in
//            for request in requests {
//                print(request)
//            }
//        })
    }
    
    func loadNeighborhoods(from fileURL: URL) -> [MKPolygon: String]?{
        do {
            let data = try Data(contentsOf: fileURL)
            let json = try JSONSerialization.jsonObject(with: data, options: [])

            guard let featureCollection = json as? [String: Any],
                  let features = featureCollection["features"] as? [[String: Any]] else {
                return nil
            }

            var neighborhoods = [MKPolygon: String]()

            for feature in features {
                if let properties = feature["properties"] as? [String: Any],
                   let neighborhoodName = properties["NAMELSAD"] as? String,
                   let geometry = feature["geometry"] as? [String: Any],
                   let type = geometry["type"] as? String,
                   type == "MultiPolygon",
                   let coordinatesArray = geometry["coordinates"] as? [[[[Double]]]] {
                   let polygon = coordinatesArray[0][0].map {
                       CLLocationCoordinate2D(latitude: $0[1], longitude: $0[0])
                       }
                    let mkPolygon = MKPolygon(coordinates: polygon, count: polygon.count)
                    neighborhoods[mkPolygon] = neighborhoodName
                }
            }

            return neighborhoods
        } catch {
            print("Error reading or parsing GeoJSON file: \(error)")
            return nil
        }
        
    }
    
    
    func testCoords() {
        let inPoint = CLLocationCoordinate2D.init(latitude: 20, longitude: 20);
        let outPoint = CLLocationCoordinate2D.init(latitude: 60, longitude: 60);
    
        let coords = [
            CLLocationCoordinate2D.init(latitude: 10, longitude: 10),
            CLLocationCoordinate2D.init(latitude: 10, longitude: 50),
            CLLocationCoordinate2D.init(latitude: 50, longitude: 50),
            CLLocationCoordinate2D.init(latitude: 50, longitude: 10)
        ];
        
        let polygon = MKPolygon.init(coordinates: coords, count: 4);
        
        if isPoint(inPoint, insidePolygon: polygon) {
            print("inPolygonViewPoint")
        }

        if isPoint(outPoint, insidePolygon: polygon) {
            print("outPolygonViewPoint.")
        }
    }
    
    fileprivate func handleGeojson() {
        if let fileURL = Bundle.main.url(forResource: "Neighborhoods", withExtension: "geojson") {
            self.neighborhoods = loadNeighborhoods(from: fileURL) ?? [:]
        }
        
        let inPoint = CLLocationCoordinate2D.init(latitude: 38.627024950703614, longitude:  -90.1994318070533);
        
        for (polygon, name) in self.neighborhoods {
            let isIn = isPoint(inPoint, insidePolygon: polygon);
            if isIn {
                print("found it! polygon - %s ", name);
                print("found it! lat - %s ", inPoint.latitude);
                print("found it! long - %s ", inPoint.longitude);
                break;
            }
        }
    }
    
    // New method to check if a point is inside a polygon using MKPolygonRenderer
    func isPoint(_ point: CLLocationCoordinate2D, insidePolygon polygon: MKPolygon) -> Bool {
        let polygonRenderer = MKPolygonRenderer(polygon: polygon)
        let mapPoint = MKMapPoint(point)
        let polygonViewPoint = polygonRenderer.point(for: mapPoint)

        return polygonRenderer.path.contains(polygonViewPoint)
    }

}

