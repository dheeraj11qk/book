//
//  AutoTyperApp.swift
//  Clipboard Auto-Typer
//
//  Created for clipboard auto-typing feature
//

import SwiftUI
import Combine

/// Coordinator for the Auto-Typer feature
class AutoTyperAppCoordinator: ObservableObject {
    private let viewModel: AutoTyperViewModel
    private let windowController: FloatingWindowController
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.viewModel = AutoTyperViewModel()
        self.windowController = FloatingWindowController(viewModel: viewModel)
        
        setupObservers()
        startMonitoring()
    }
    
    private func setupObservers() {
        // Show/hide window based on clipboard content
        viewModel.$clipboardText
            .sink { [weak self] text in
                if let text = text, !text.isEmpty {
                    self?.windowController.show()
                } else {
                    self?.windowController.hide()
                }
            }
            .store(in: &cancellables)
    }
    
    private func startMonitoring() {
        viewModel.startMonitoring()
    }
    
    func stopMonitoring() {
        viewModel.stopMonitoring()
        windowController.hide()
    }
}
