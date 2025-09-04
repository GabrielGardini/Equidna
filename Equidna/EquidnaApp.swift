//
//  EquidnaApp.swift
//  Equidna
//
//  Created by Gabriel Gardini on 14/08/25.
//

import SwiftUI
import BackgroundTasks
import WidgetKit

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        BGTaskScheduler.shared.register(forTaskWithIdentifier: "dev.gardinidev.equidna.refresh",
                                        using: nil) { task in
            self.handleAppRefresh(task: task as! BGAppRefreshTask)
        }

        return true
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        scheduleAppRefresh()
    }

    // MARK: - Scheduling Refresh
    // Sugestão: 6h
    func scheduleAppRefresh() {
        // Intervalo em horas
        let refreshIntervalinHours: TimeInterval = 6 * 3600
        
        let request = BGAppRefreshTaskRequest(identifier: "dev.gardinidev.equidna.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: refreshIntervalinHours)
        
        do {
            try BGTaskScheduler.shared.submit(request)
            print("[BGTask] Task agendada para rodar em até 6h")
        } catch {
            print("[BGTask] Erro ao agendar: \(error)")
        }
    }
    
    func handleAppRefresh(task: BGAppRefreshTask) {
        // Agenda outro refresh futuro, se necessário
        scheduleAppRefresh()
        
        // Informa ao sistema quando a task terminar
        let group = DispatchGroup()
        let viewModel = HistoryViewModel()
        viewModel.refresh()
        
        group.notify(queue: .main) {
            task.setTaskCompleted(success: true)
        }
        
        // Expire handler do iOS (caso demore demais)
        task.expirationHandler = {
            // Cancelar operações pendentes se necessário
            task.setTaskCompleted(success: false)
        }
    }

}

@main
struct EquidnaApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var userManager = UserManager()

        var body: some Scene {
            WindowGroup {
                ContentView()
                    .environmentObject(userManager)
                    .onAppear {
                        userManager.setupCurrentUser()
                    }
            }
        }
}
