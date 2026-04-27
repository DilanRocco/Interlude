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
                    Stepper(
                        value: $viewModel.selectedIntervalTime,
                        in: 1...120
                    ) {
                        LabeledPreferenceValue(
                            title: "Duration between breaks",
                            valueText: "\(viewModel.selectedIntervalTime) min"
                        )
                    }

                    Divider()

                    Stepper(
                        value: $viewModel.selectedOverlayTime,
                        in: 5...300,
                        step: 5
                    ) {
                        LabeledPreferenceValue(
                            title: "Break duration",
                            valueText: "\(viewModel.selectedOverlayTime) sec"
                        )
                    }
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
        }
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
            Text(title)
                .font(.headline)
            if let subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
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

private struct LabeledPreferenceValue: View {
    let title: String
    let valueText: String

    var body: some View {
        HStack {
            Text(title)
            Spacer(minLength: 16)
            Text(valueText)
                .foregroundColor(.secondary)
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
            watchingAMovie = false
            
            
        }
        .foregroundColor(.red)
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

