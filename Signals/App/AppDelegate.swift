//
//  AppDelegate.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import UIKit
import BackgroundTasks
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate {
    
    // MARK: - App Launch
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Register background tasks
        registerBackgroundTasks()
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Schedule initial background tasks
        scheduleBackgroundTasks()
        
        return true
    }
    
    // MARK: - Background Tasks Registration
    
    private func registerBackgroundTasks() {
        // Register daily data collection task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifier.dailyCollection,
            using: nil
        ) { task in
            self.handleDailyCollectionTask(task as! BGAppRefreshTask)
        }
        
        // Register weekly analysis task
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: BackgroundTaskIdentifier.weeklyAnalysis,
            using: nil
        ) { task in
            self.handleWeeklyAnalysisTask(task as! BGProcessingTask)
        }
    }
    
    // MARK: - Background Task Scheduling
    
    func scheduleBackgroundTasks() {
        scheduleDailyCollectionTask()
        scheduleWeeklyAnalysisTask()
    }
    
    private func scheduleDailyCollectionTask() {
        let request = BGAppRefreshTaskRequest(identifier: BackgroundTaskIdentifier.dailyCollection)
        
        // Schedule for ~6 AM tomorrow
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.hour = 6
        components.minute = 0
        
        if let scheduledDate = calendar.date(from: components) {
            // If 6 AM has already passed today, schedule for tomorrow
            let targetDate = scheduledDate <= Date() 
                ? calendar.date(byAdding: .day, value: 1, to: scheduledDate)! 
                : scheduledDate
            request.earliestBeginDate = targetDate
        }
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule daily collection task: \(error)")
        }
    }
    
    private func scheduleWeeklyAnalysisTask() {
        let request = BGProcessingTaskRequest(identifier: BackgroundTaskIdentifier.weeklyAnalysis)
        request.requiresNetworkConnectivity = false
        request.requiresExternalPower = false
        
        // Schedule for Sunday night ~10 PM
        let calendar = Calendar.current
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())
        components.weekday = 1 // Sunday
        components.hour = 22
        components.minute = 0
        
        if let scheduledDate = calendar.date(from: components) {
            // If Sunday 10 PM has passed, schedule for next week
            let targetDate = scheduledDate <= Date()
                ? calendar.date(byAdding: .day, value: 7, to: scheduledDate)!
                : scheduledDate
            request.earliestBeginDate = targetDate
        }
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule weekly analysis task: \(error)")
        }
    }
    
    // MARK: - Background Task Handlers
    
    private func handleDailyCollectionTask(_ task: BGAppRefreshTask) {
        // Schedule the next daily task
        scheduleDailyCollectionTask()
        
        // Create a task to perform the collection
        let collectionTask = Task {
            await BackgroundTaskHandler.shared.performDailyCollection()
        }
        
        // Handle task expiration
        task.expirationHandler = {
            collectionTask.cancel()
        }
        
        // Complete the task when done
        Task {
            await collectionTask.value
            task.setTaskCompleted(success: true)
        }
    }
    
    private func handleWeeklyAnalysisTask(_ task: BGProcessingTask) {
        // Schedule the next weekly task
        scheduleWeeklyAnalysisTask()
        
        // Create a task to perform the analysis
        let analysisTask = Task {
            await BackgroundTaskHandler.shared.performWeeklyAnalysis()
        }
        
        // Handle task expiration
        task.expirationHandler = {
            analysisTask.cancel()
            // Save partial progress if possible
            Task {
                await BackgroundTaskHandler.shared.savePartialProgress()
            }
        }
        
        // Complete the task when done
        Task {
            await analysisTask.value
            task.setTaskCompleted(success: true)
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension AppDelegate: UNUserNotificationCenterDelegate {
    
    // Handle notification when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner and play sound even when app is open
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        
        // Route to appropriate screen via NavigationRouter
        Task { @MainActor in
            NavigationRouter.shared.handleNotification(userInfo: userInfo)
        }
        
        completionHandler()
    }
}

// MARK: - Background Task Identifiers

enum BackgroundTaskIdentifier {
    static let dailyCollection = "com.nimavat.Signals.daily-collection"
    static let weeklyAnalysis = "com.nimavat.Signals.weekly-analysis"
}
