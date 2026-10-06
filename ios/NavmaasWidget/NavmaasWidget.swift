import SwiftUI
import WidgetKit

// The home-screen widget (ARCHITECTURE §10). It never opens the database:
// it shows the snapshot the app writes to the App Group
// (lib/features/home_widget), picking the entry for the day and the next
// reminder still ahead. Every word comes from the snapshot.

private let appGroup = "group.com.patelkeyur.navmaas"
private let openToday = URL(string: "navmaas://widget/today")!

struct Snapshot: Decodable {
  struct Labels: Decodable {
    let name, next, nextReminder, none, tomorrow: String
  }
  struct Day: Decodable {
    let date, week, weekDay, daySize, size: String
  }
  struct Reminder: Decodable {
    let at: Double
    let date, weekday, time: String
    let title: String?
  }
  let stopped, hidden: Bool
  let labels: Labels
  let days: [Day]
  let next: [Reminder]

  static func load() -> Snapshot? {
    guard let json = UserDefaults(suiteName: appGroup)?.string(forKey: "snapshot"),
      let data = json.data(using: .utf8)
    else { return nil }
    return try? JSONDecoder().decode(Snapshot.self, from: data)
  }
}

struct Entry: TimelineEntry {
  let date: Date
  let snapshot: Snapshot?
}

/// What the widget shows at one moment.
struct Shown {
  let labels: Snapshot.Labels?
  let day: Snapshot.Day?
  let next: Snapshot.Reminder?
  /// "Tomorrow" or "Wed" when the next reminder isn't today.
  let nextDay: String?

  init(_ entry: Entry) {
    guard let s = entry.snapshot, !s.stopped else {
      labels = nil
      day = nil
      next = nil
      nextDay = nil
      return
    }
    let format = DateFormatter()
    format.locale = Locale(identifier: "en_US_POSIX")
    format.dateFormat = "yyyy-MM-dd"
    let today = format.string(from: entry.date)
    let tomorrow = format.string(
      from: Calendar.current.date(byAdding: .day, value: 1, to: entry.date)!)
    labels = s.labels
    day = s.hidden ? nil : s.days.first { $0.date == today }
    next = s.next.first { $0.at / 1000 > entry.date.timeIntervalSince1970 }
    nextDay =
      next.map { n in
        n.date == today ? nil : n.date == tomorrow ? s.labels.tomorrow : n.weekday
      } ?? nil
  }

  var when: String? { next.map { n in nextDay.map { "\($0) \(n.time)" } ?? n.time } }
}

struct Provider: TimelineProvider {
  func placeholder(in context: Context) -> Entry { Entry(date: Date(), snapshot: nil) }

  func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
    completion(Entry(date: Date(), snapshot: Snapshot.load()))
  }

  /// An entry now, after each reminder in the next two days and at each
  /// midnight for a week; the app reloads the timeline whenever it changes.
  func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
    let now = Date()
    let snapshot = Snapshot.load()
    var times = [now]
    for r in snapshot?.next ?? [] {
      let at = Date(timeIntervalSince1970: r.at / 1000 + 1)
      if at > now && at < now.addingTimeInterval(2 * 86400) { times.append(at) }
    }
    let midnight = Calendar.current.startOfDay(for: now)
    for d in 1...7 {
      times.append(Calendar.current.date(byAdding: .day, value: d, to: midnight)!)
    }
    let entries = times.sorted().map { Entry(date: $0, snapshot: snapshot) }
    completion(Timeline(entries: entries, policy: .atEnd))
  }
}

// Moonlit Sage tokens (design/navmaas-tokens.css), light and dark.
extension Color {
  fileprivate static func nm(_ light: UInt32, _ dark: UInt32) -> Color {
    func ui(_ hex: UInt32) -> UIColor {
      UIColor(
        red: CGFloat(hex >> 16 & 0xFF) / 255, green: CGFloat(hex >> 8 & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
    }
    return Color(UIColor { $0.userInterfaceStyle == .dark ? ui(dark) : ui(light) })
  }
  static let nmSurface = nm(0xFFFDF9, 0x24202A)
  static let nmText = nm(0x2F2A28, 0xE8E0D8)
  static let nmText2 = nm(0x5E5650, 0xC2B8B0)
  static let nmText3 = nm(0x6E655E, 0xA99F98)
  static let nmPrimary = nm(0x4A6F5D, 0x9CC2AE)
  static let nmPrimarySoft = nm(0xE2ECE5, 0x2B3A33)
  static let nmOnPrimarySoft = nm(0x2C4638, 0xCFE4D7)
}

/// The prototype's line icons (NavmaasIcon), on its 24-grid.
struct Sprout: Shape {
  func path(in rect: CGRect) -> Path {
    let s = rect.width / 24
    var p = Path()
    p.move(to: CGPoint(x: 12 * s, y: 21 * s))
    p.addLine(to: CGPoint(x: 12 * s, y: 12.5 * s))
    p.move(to: CGPoint(x: 12 * s, y: 12.5 * s))
    p.addCurve(
      to: CGPoint(x: 20 * s, y: 5 * s), control1: CGPoint(x: 12 * s, y: 8.3 * s),
      control2: CGPoint(x: 15 * s, y: 5 * s))
    p.addCurve(
      to: CGPoint(x: 12 * s, y: 12.5 * s), control1: CGPoint(x: 20 * s, y: 9.2 * s),
      control2: CGPoint(x: 17 * s, y: 12.5 * s))
    p.move(to: CGPoint(x: 12 * s, y: 14.5 * s))
    p.addCurve(
      to: CGPoint(x: 5 * s, y: 8.5 * s), control1: CGPoint(x: 12 * s, y: 11.2 * s),
      control2: CGPoint(x: 9.4 * s, y: 8.5 * s))
    p.addCurve(
      to: CGPoint(x: 12 * s, y: 14.5 * s), control1: CGPoint(x: 5 * s, y: 11.8 * s),
      control2: CGPoint(x: 7.6 * s, y: 14.5 * s))
    return p
  }
}

struct Bell: Shape {
  func path(in rect: CGRect) -> Path {
    let s = rect.width / 24
    var p = Path()
    p.move(to: CGPoint(x: 6 * s, y: 16 * s))
    p.addLine(to: CGPoint(x: 6 * s, y: 11 * s))
    p.addArc(
      center: CGPoint(x: 12 * s, y: 11 * s), radius: 6 * s, startAngle: .degrees(180),
      endAngle: .degrees(0), clockwise: false)
    p.addLine(to: CGPoint(x: 18 * s, y: 16 * s))
    p.addLine(to: CGPoint(x: 19.5 * s, y: 18 * s))
    p.addLine(to: CGPoint(x: 4.5 * s, y: 18 * s))
    p.closeSubpath()
    p.move(to: CGPoint(x: 10 * s, y: 21 * s))
    p.addLine(to: CGPoint(x: 14 * s, y: 21 * s))
    return p
  }
}

private func line<S: Shape>(_ shape: S, _ size: CGFloat) -> some View {
  shape.stroke(style: StrokeStyle(lineWidth: 2 * size / 24, lineCap: .round, lineJoin: .round))
    .frame(width: size, height: size)
}

private func nmFont(_ size: CGFloat, _ weight: Font.Weight = .heavy) -> Font {
  .system(size: size, weight: weight, design: .rounded)
}

struct Mark: View {
  let size: CGFloat
  var body: some View {
    ZStack {
      Circle().fill(Color.nmPrimarySoft)
      line(Sprout(), size / 2).foregroundColor(.nmOnPrimarySoft)
    }
    .frame(width: size, height: size)
    .accessibilityHidden(true)
  }
}

struct Brand: View {
  let name: String
  var body: some View {
    HStack(spacing: 8) {
      Mark(size: 28)
      Text(name).font(nmFont(13)).foregroundColor(.nmText3)
    }
  }
}

struct WidgetView: View {
  @Environment(\.widgetFamily) var family
  let entry: Entry

  var body: some View {
    let shown = Shown(entry)
    Group {
      if let labels = shown.labels {
        if let day = shown.day {
          family == .systemSmall
            ? AnyView(small(labels, day, shown)) : AnyView(medium(labels, day, shown))
        } else {
          AnyView(hidden(labels, shown))
        }
      } else {
        AnyView(Mark(size: 56).frame(maxWidth: .infinity, maxHeight: .infinity))
      }
    }
    .widgetURL(openToday)
    .modifier(Background())
  }

  private func small(_ labels: Snapshot.Labels, _ day: Snapshot.Day, _ shown: Shown) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Brand(name: labels.name)
      Spacer(minLength: 4)
      Text(day.week).font(nmFont(22)).foregroundColor(.nmText)
      Text(day.daySize).font(nmFont(13, .bold)).foregroundColor(.nmText2).lineLimit(2)
      Spacer(minLength: 4)
      HStack(spacing: 6) {
        line(Bell(), 14)
        Text(shown.when.map { w in shown.next?.title.map { "\(w) · \($0)" } ?? w } ?? labels.none)
          .font(nmFont(13)).lineLimit(1).minimumScaleFactor(0.85)
      }
      .foregroundColor(.nmPrimary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }

  private func medium(_ labels: Snapshot.Labels, _ day: Snapshot.Day, _ shown: Shown) -> some View {
    HStack(spacing: 14) {
      VStack(alignment: .leading, spacing: 2) {
        Brand(name: labels.name)
        Spacer(minLength: 4)
        Text(day.weekDay).font(nmFont(22)).foregroundColor(.nmText).lineLimit(1)
          .minimumScaleFactor(0.8)
        if !day.size.isEmpty {
          Text(day.size).font(nmFont(14, .semibold)).foregroundColor(.nmText2).lineLimit(2)
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      VStack(alignment: .leading, spacing: 0) {
        line(Bell(), 18)
        Spacer(minLength: 4)
        Text(labels.next).font(nmFont(12, .bold))
        Text(shown.next?.title ?? labels.none).font(nmFont(15)).lineLimit(2)
        if let when = shown.when { Text(when).font(nmFont(15)).lineLimit(2) }
      }
      .foregroundColor(.nmOnPrimarySoft)
      .padding(12)
      .frame(width: 128, alignment: .leading)
      .frame(maxHeight: .infinity)
      .background(RoundedRectangle(cornerRadius: 16).fill(Color.nmPrimarySoft))
    }
  }

  private func hidden(_ labels: Snapshot.Labels, _ shown: Shown) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Brand(name: labels.name)
      Spacer(minLength: 4)
      Text(labels.nextReminder).font(nmFont(12, .bold)).foregroundColor(.nmText3)
      if let next = shown.next {
        if let day = shown.nextDay {
          Text(day).font(nmFont(22)).foregroundColor(.nmText)
          Text(next.time).font(nmFont(15)).foregroundColor(.nmText2)
        } else {
          Text(next.time).font(nmFont(22)).foregroundColor(.nmText)
        }
      } else {
        Text(labels.none).font(nmFont(15)).foregroundColor(.nmText)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
  }
}

/// iOS 17 draws the widget's own background and margins; earlier versions
/// get the same 16 pt padding by hand.
struct Background: ViewModifier {
  func body(content: Content) -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      content.containerBackground(Color.nmSurface, for: .widget)
    } else {
      content.padding(16).background(Color.nmSurface)
    }
  }
}

@main
struct NavmaasWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: "NavmaasWidget", provider: Provider()) { entry in
      WidgetView(entry: entry)
    }
    .configurationDisplayName("Navmaas")
    .description("Your week and the next reminder")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
