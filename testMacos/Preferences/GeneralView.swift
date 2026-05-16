//
//  GeneralView.swift
//  testMacos
//
//  Created by Dilan Piscatello on 5/4/22.
//

import SwiftUI
import UserNotifications

struct GeneralView: View {
    @ObservedObject private var viewModel = ViewModel()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Customize")
                        .font(.title)
                        .fontWeight(.semibold)
                    Text("Adjust timing, appearance, and reminder behavior.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                PreferenceSection(title: "Timing", subtitle: "Control when reminders appear and how long they stay visible.") {
                    PresetTimingRow(
                        title: "Duration between breaks",
                        unitSuffix: "min",
                        presets: GeneralView.intervalMinutePresets,
                        range: 1...360,
                        step: 1,
                        presetTitle: GeneralView.intervalPresetTitle(for:),
                        value: $viewModel.selectedIntervalTime
                    )

                    Divider()

                    PresetTimingRow(
                        title: "Break duration",
                        unitSuffix: "sec",
                        presets: GeneralView.overlaySecondPresets,
                        range: 5...900,
                        step: 5,
                        presetTitle: GeneralView.overlayPresetTitle(for:),
                        value: $viewModel.selectedOverlayTime
                    )

                    Divider()

                    Toggle("AI Break Time (adaptive reminder timing)", isOn: $viewModel.aiBreakTimeEnabled)
                        .help("When enabled, Interlude predicts skip probability from recent behavior and adjusts reminder timing.")
                }

                PreferenceSection(title: "Appearance", subtitle: "Choose the overlay color theme.") {
                    BackgroundColorsView(viewModel: viewModel)
                }

                PreferenceSection(title: "Behavior", subtitle: "Pause reminders or limit them to your active schedule.") {
                    WatchingAMovie()
                    Divider()
                    ScheduleView(viewModel: viewModel)
                }

                PreferenceSection(title: "Notifications", subtitle: "Use a less disruptive notification-style reminder.") {
                    EnableNotifcaionsView(viewModel: viewModel)
                }

                PreferenceSection(title: "Sync", subtitle: "Keep settings local by default, or opt in to iCloud sync.") {
                    Toggle("Sync settings with iCloud", isOn: $viewModel.iCloudSyncEnabled)
                    Text(viewModel.iCloudSyncStatusText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                PreferenceSection(title: "Maintenance") {
                    HStack(spacing: 10) {
                        OpenOnboardingSlides()
                        Spacer()
                        ResetView(viewModel: viewModel)
                    }
                }
            }
            .font(.system(size: 14))
            .frame(maxWidth: 560, alignment: .leading)
            .padding(24)
            .contentShape(Rectangle())
            .onTapGesture {
                NSApp.keyWindow?.makeFirstResponder(nil)
            }
        }
    }

    /// Quick picks for “between breaks”; slider covers full `1…120`.
    fileprivate static let intervalMinutePresets: [Int] = [15, 20, 30, 45, 60, 90, 120]

    /// Quick picks for overlay length; slider covers full `5…300` in steps of 5.
    fileprivate static let overlaySecondPresets: [Int] = [10, 20, 30, 45, 60, 120, 180]

    fileprivate static func intervalPresetTitle(for minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        let base: String
        if h > 0 && m == 0 {
            base = h == 1 ? "1 hour" : "\(h) hours"
        } else if h > 0 {
            base = "\(h)h \(m)m"
        } else {
            base = "\(minutes) min"
        }
        return minutes == 20 ? "\(base) (recommended)" : base
    }

    fileprivate static func overlayPresetTitle(for seconds: Int) -> String {
        let base: String
        if seconds >= 60 && seconds % 60 == 0 {
            let m = seconds / 60
            base = m == 1 ? "1 minute" : "\(m) minutes"
        } else {
            base = "\(seconds) sec"
        }
        return seconds == 20 ? "\(base) (recommended)" : base
    }
}

private struct PreferenceSection<Content: View>: View {
    let title: String
    var subtitle: String?
    let content: Content

    init(title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            content
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.gray.opacity(0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.gray.opacity(0.28), lineWidth: 1)
        )
    }
}

private struct PresetTimingRow: View {
    let title: String
    let unitSuffix: String
    let presets: [Int]
    let range: ClosedRange<Int>
    let step: Int
    let presetTitle: (Int) -> String
    @Binding var value: Int

    @State private var showCustom = false

    private let customMenuTag = Int.min

    private var isCustom: Bool {
        showCustom || !presets.contains(value)
    }

    private var pickerSelection: Binding<Int> {
        Binding(
            get: { isCustom ? customMenuTag : value },
            set: { newTag in
                if newTag == customMenuTag {
                    showCustom = true
                } else {
                    showCustom = false
                    value = newTag
                }
            }
        )
    }

    private func clampAndSnap(_ raw: Int) -> Int {
        let clamped = min(range.upperBound, max(range.lowerBound, raw))
        guard step > 1 else { return clamped }
        let lower = range.lowerBound
        let remainder = (clamped - lower) % step
        let down = clamped - remainder
        let up = min(range.upperBound, down + step)
        return (clamped - down < up - clamped) ? max(range.lowerBound, down) : up
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Primary row — always visible
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                Spacer()
                Picker("", selection: pickerSelection) {
                    ForEach(presets, id: \.self) { preset in
                        Text(presetTitle(preset)).tag(preset)
                    }
                    Divider()
                    Text("Custom…").tag(customMenuTag)
                }
                .labelsHidden()
                .fixedSize()
                .pickerStyle(.menu)
                .accessibilityLabel(title)
            }
            .frame(minHeight: 28)

            // Custom sub-row — only visible when Custom is selected
            if isCustom {
                HStack(spacing: 6) {
                    Spacer()
                    TextField("", value: $value, format: .number)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 52)
                        .textFieldStyle(.roundedBorder)
                    Text(unitSuffix)
                        .foregroundColor(.secondary)
                        .frame(width: 26, alignment: .leading)
                    Stepper("", value: $value, in: range, step: step)
                        .labelsHidden()
                }
                .padding(.top, 6)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.15), value: isCustom)
        .onAppear {
            showCustom = !presets.contains(value)
        }
        .onChange(of: value) { _, newValue in
            let snapped = clampAndSnap(newValue)
            if snapped != newValue {
                value = snapped
            }
        }
    }
}

// toggle for setting if watching a movie
struct WatchingAMovie: View {
    @State private var watchingMovie = watchingAMovie
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle("Watching a movie (pause overlays)", isOn: $watchingMovie).onChange(of: watchingMovie, perform: {watching in
                watchingAMovie = watching
                menuExtrasConfigurator?.createMainMenu()
                if watching {
                    AppDelegate.StopScreenTimer()
                } else {
                    AppDelegate.StartScreenTimer()
                }
            })
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

//pick background color
struct BackgroundColorsView: View {
    @ObservedObject var viewModel: GeneralView.ViewModel
   
    var body: some View {
        HStack {
            Text("Overlay Background:")
                .frame(width: 140, alignment: .leading)
            ForEach(viewModel.backgroundColors, id: \.self) { color in
                Button(action: {
                    viewModel.selectedBackgroundColor = color
                }) {
                    Text("")
                        .padding(.top, 6)
                        .padding(.bottom, 6)
                        .padding(.leading, 12)
                        .padding(.trailing, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5)
                                .stroke(
                                    color.backColor == viewModel.selectedBackgroundColor.backColor ? .gray : .clear,
                                    lineWidth: color.backColor == viewModel.selectedBackgroundColor.backColor ? 3 : 0
                                )
                        )
                        .background(RoundedRectangle(cornerRadius: 5).fill((Color(hex: color.backColor)!)))
                }
                .help(color.helpText)
                .buttonStyle(PlainButtonStyle())
                .animation(.spring(), value: viewModel.selectedBackgroundColor)
            }
            Spacer()
        }
    }
}

// enable notifications control
struct EnableNotifcaionsView: View {
    @ObservedObject var viewModel: GeneralView.ViewModel
    @State private var isHovering = false
    
    var body: some View {
        Toggle("Show a less disruptive Interlude reminder using notifications", isOn: $viewModel.notificationsOn).onChange(of: viewModel.notificationsOn, perform: { newValue in
                let isTryingToEnable = newValue
                UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { Settings in
                    if (Settings.authorizationStatus == .authorized && isTryingToEnable){
                        DispatchQueue.main.async {
                            viewModel.notificationsOn = true
                        }
                    }else if(!(Settings.authorizationStatus == .authorized) && isTryingToEnable){
                        DispatchQueue.main.async {
                            viewModel.notificationsOn = false;
                            viewModel.displaySettingPage = true;
                        }
                    }else{
                        DispatchQueue.main.async {
                        viewModel.notificationsOn = false
                        }
                    }
                })
               
            })
        
        .popover(isPresented:$viewModel.displaySettingPage, arrowEdge: .bottom) {
            ZStack{
                isHovering ? Color.blue.scaleEffect(1.5) : Color.blue.opacity(0.8).scaleEffect(1.5)
                    Button(action: {Notifications.openSettings()}){
                        Text("Enable Notifications").frame(width: 200, height: 50, alignment: .center)
                    }.buttonStyle(.borderless).padding()
                }
            .frame(width: 200, height: 50)
            .onHover { isHovered in
                isHovering = isHovered
            
            }
            
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}


// Reset button controls
struct ResetView: View{
    @ObservedObject var viewModel: GeneralView.ViewModel
    var body: some View{
        Button("Reset Settings"){
            viewModel.selectedIntervalTime = 20
            viewModel.selectedOverlayTime = 20
            viewModel.selectedBackgroundColor = Constants.DefaultBackgroundColor
            viewModel.notificationsOn = false
            viewModel.aiBreakTimeEnabled = false
            watchingAMovie = false
            
            
        }
        .foregroundColor(.black)
    }
}

// Schedule hours control
struct ScheduleView: View {
    @ObservedObject var viewModel: GeneralView.ViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Toggle("Only remind me during scheduled hours", isOn: $viewModel.scheduleEnabled)

            if viewModel.scheduleEnabled {
                HStack(spacing: 16) {
                    Text("From")
                    DatePicker("", selection: $viewModel.scheduleStart, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(width: 90)
                    Text("Until")
                    DatePicker("", selection: $viewModel.scheduleEnd, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .frame(width: 90)
                }
                .padding(.leading, 4)

                Toggle("Weekdays only", isOn: $viewModel.scheduleWeekdaysOnly)
                    .padding(.leading, 4)
            }

            Divider()

            Toggle("Skip overlays during calendar meetings", isOn: $viewModel.calendarBlockingEnabled)
                .help("When enabled, Interlude checks Apple Calendar before showing an overlay.")
            Text(viewModel.calendarAccessStatusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Open Oboarding Toggle
struct OpenOnboardingSlides: View{
    var body: some View{
        Button("Open Onboarding Slides"){
           openOnboardingWindow()
            
        }
        .buttonStyle(.bordered)
    }
}

