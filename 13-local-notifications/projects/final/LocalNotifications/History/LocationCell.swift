import SwiftUI
import CoreLocation

struct LocationCell: View {
  private static let formatter: MeasurementFormatter = {
    let formatter = MeasurementFormatter()
    formatter.unitStyle = .medium
    formatter.unitOptions = .naturalScale
    return formatter
  }()

  private let title: String
  private let subTitle: String

  init(for trigger: UNLocationNotificationTrigger, with content: UNNotificationContent) {
    title = "Location - \(content.title)"

    guard let region = trigger.region as? CLCircularRegion else {
      subTitle = "Unknown region."
      return
    }
    let measurement = Measurement(value: region.radius, unit: UnitLength.meters)
    let radius = LocationCell.formatter.string(from: measurement)
    subTitle = "ɸ \(region.center.latitude), λ \(region.center.longitude), radius \(radius)"
  }

  var body: some View {
    VStack(alignment: .leading) {
      Text(title)
        .font(.headline)

      Text(subTitle)
        .font(.subheadline)
    }
  }
}
