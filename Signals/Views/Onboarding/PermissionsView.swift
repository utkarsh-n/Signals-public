//
//  PermissionsView.swift
//  Signals
//
//  Created by Assistant on 2/7/26.
//

import SwiftUI

/// Sequential permission request screen
struct PermissionsView: View {
    @Bindable var onboardingManager: OnboardingStateManager
    
    @State private var currentPermissionIndex = 0
    @State private var permissionStatuses: [PermissionGroup: PermissionStatus] = [:]
    @State private var isRequestingPermission = false
    @State private var showContent = false
    
    private var requiredPermissions: [PermissionInfo] {
        onboardingManager.requiredPermissionGroups.compactMap { PermissionInfo.forGroup($0) }
    }
    
    private var currentPermission: PermissionInfo? {
        guard currentPermissionIndex < requiredPermissions.count else { return nil }
        return requiredPermissions[currentPermissionIndex]
    }
    
    private var allPermissionsHandled: Bool {
        currentPermissionIndex >= requiredPermissions.count
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if allPermissionsHandled {
                // All permissions handled
                permissionsCompleteView
            } else if let permission = currentPermission {
                // Show current permission request
                permissionRequestView(for: permission)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }
    
    // MARK: - Permission Request View
    
    private func permissionRequestView(for permission: PermissionInfo) -> some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Permission icon
            ZStack {
                Circle()
                    .fill(ColorPalette.primaryGradient.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: permission.icon)
                    .font(.system(size: 50))
                    .foregroundStyle(ColorPalette.primaryGradient)
            }
            .opacity(showContent ? 1 : 0)
            .scaleEffect(showContent ? 1 : 0.8)
            
            Spacer()
                .frame(height: 40)
            
            // Permission info
            VStack(spacing: 16) {
                Text(permission.title)
                    .font(Typography.title)
                
                Text(permission.description)
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(showContent ? 1 : 0)
            
            Spacer()
            
            // Progress indicator
            HStack(spacing: 8) {
                ForEach(0..<requiredPermissions.count, id: \.self) { index in
                    Circle()
                        .fill(index <= currentPermissionIndex 
                              ? Color.purple 
                              : ColorPalette.tertiaryBackground)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.bottom, 30)
            
            // Buttons
            VStack(spacing: 12) {
                OnboardingButton(
                    title: "Allow Access",
                    action: { requestPermission(for: permission) },
                    isEnabled: !isRequestingPermission
                )
                
                Button("Skip for now") {
                    skipPermission()
                }
                .font(Typography.subheadline)
                .foregroundStyle(ColorPalette.secondaryText)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
            .opacity(showContent ? 1 : 0)
        }
    }
    
    // MARK: - Permissions Complete View
    
    private var permissionsCompleteView: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.1))
                    .frame(width: 120, height: 120)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundStyle(.green)
            }
            
            Spacer()
                .frame(height: 40)
            
            // Summary
            VStack(spacing: 16) {
                Text("Permissions set up")
                    .font(Typography.title)
                
                Text("You can always change these later in Settings")
                    .font(Typography.body)
                    .foregroundStyle(ColorPalette.secondaryText)
                    .multilineTextAlignment(.center)
            }
            
            // Status list
            VStack(spacing: 12) {
                ForEach(requiredPermissions, id: \.group) { permission in
                    PermissionStatusRow(
                        permission: permission,
                        status: permissionStatuses[permission.group] ?? .notDetermined
                    )
                }
            }
            .padding(.horizontal, 40)
            .padding(.top, 30)
            
            Spacer()
            
            OnboardingButton(title: "Continue") {
                onboardingManager.permissionResults = permissionStatuses
                onboardingManager.goToNext()
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    // MARK: - Actions
    
    private func requestPermission(for permission: PermissionInfo) {
        isRequestingPermission = true
        
        Task {
            do {
                try await PermissionService.shared.requestPermission(for: permission.group)
                
                // Check status after requesting
                let status = getPermissionStatus(for: permission.group)
                permissionStatuses[permission.group] = status
                
                await MainActor.run {
                    isRequestingPermission = false
                    moveToNextPermission()
                }
            } catch {
                await MainActor.run {
                    permissionStatuses[permission.group] = .denied
                    isRequestingPermission = false
                    moveToNextPermission()
                }
            }
        }
    }
    
    private func skipPermission() {
        if let permission = currentPermission {
            permissionStatuses[permission.group] = .notDetermined
        }
        moveToNextPermission()
    }
    
    private func moveToNextPermission() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentPermissionIndex += 1
        }
        Haptics.light()
    }
    
    private func getPermissionStatus(for group: PermissionGroup) -> PermissionStatus {
        switch group {
        case .health:
            return PermissionService.shared.getHealthPermissionStatus()
        case .location:
            return PermissionService.shared.getLocationPermissionStatus()
        case .motion:
            return PermissionService.shared.getMotionPermissionStatus()
        case .screenTime:
            return PermissionService.shared.getScreenTimePermissionStatus()
        case .none:
            return .authorized
        }
    }
}

struct PermissionStatusRow: View {
    let permission: PermissionInfo
    let status: PermissionStatus
    
    var body: some View {
        HStack {
            Image(systemName: permission.icon)
                .foregroundStyle(ColorPalette.secondaryText)
                .frame(width: 30)
            
            Text(permission.title)
                .font(Typography.body)
            
            Spacer()
            
            Image(systemName: status.isGranted ? "checkmark.circle.fill" : "minus.circle")
                .foregroundStyle(status.isGranted ? .green : .orange)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    PermissionsView(onboardingManager: {
        let manager = OnboardingStateManager()
        manager.selectedSignals = [.steps, .sleep, .location]
        return manager
    }())
}
