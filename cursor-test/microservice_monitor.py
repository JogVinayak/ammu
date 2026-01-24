#!/usr/bin/env python3
"""
Microservice Monitor - A PyQt6 application to monitor microservices status.
Provides real-time health checks, log viewing, and start/stop controls.
"""

import sys
import socket
import subprocess
import threading
import os
from datetime import datetime
from dataclasses import dataclass
from typing import Optional, Dict, List
from pathlib import Path

from PyQt6.QtWidgets import (
    QApplication, QMainWindow, QWidget, QVBoxLayout, QHBoxLayout,
    QTableWidget, QTableWidgetItem, QPushButton, QTextEdit, QLabel,
    QHeaderView, QSplitter, QFrame, QGroupBox, QMessageBox,
    QFileDialog, QComboBox, QSpinBox, QCheckBox
)
from PyQt6.QtCore import Qt, QTimer, QThread, pyqtSignal
from PyQt6.QtGui import QColor, QFont, QIcon, QPalette


@dataclass
class Microservice:
    """Represents a microservice configuration."""
    name: str
    port: int
    health_endpoint: str = "/"
    process: Optional[subprocess.Popen] = None
    log_file: Optional[str] = None
    start_command: Optional[str] = None
    working_dir: Optional[str] = None


class HealthCheckWorker(QThread):
    """Worker thread for checking service health."""
    health_checked = pyqtSignal(str, bool, str)  # service_name, is_healthy, message
    
    def __init__(self, services: Dict[str, Microservice]):
        super().__init__()
        self.services = services
        self.running = True
    
    def run(self):
        """Check health of all services."""
        for name, service in self.services.items():
            if not self.running:
                break
            is_healthy, message = self.check_service_health(service)
            self.health_checked.emit(name, is_healthy, message)
    
    def check_service_health(self, service: Microservice) -> tuple[bool, str]:
        """Check if a service is healthy by attempting to connect to its port."""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(2)
            result = sock.connect_ex(('localhost', service.port))
            sock.close()
            
            if result == 0:
                return True, f"Service running on port {service.port}"
            else:
                return False, f"Cannot connect to port {service.port}"
        except socket.timeout:
            return False, f"Connection timeout on port {service.port}"
        except Exception as e:
            return False, f"Error: {str(e)}"
    
    def stop(self):
        """Stop the worker thread."""
        self.running = False


class LogReader(QThread):
    """Worker thread for reading log files."""
    log_updated = pyqtSignal(str)
    
    def __init__(self, log_path: str):
        super().__init__()
        self.log_path = log_path
        self.running = True
    
    def run(self):
        """Read and emit log content."""
        try:
            if os.path.exists(self.log_path):
                with open(self.log_path, 'r') as f:
                    # Read last 1000 lines
                    lines = f.readlines()[-1000:]
                    self.log_updated.emit(''.join(lines))
            else:
                self.log_updated.emit(f"Log file not found: {self.log_path}")
        except Exception as e:
            self.log_updated.emit(f"Error reading log: {str(e)}")
    
    def stop(self):
        """Stop the worker thread."""
        self.running = False


class MicroserviceMonitor(QMainWindow):
    """Main application window for microservice monitoring."""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Microservice Monitor")
        self.setMinimumSize(1000, 700)
        
        # Define microservices
        self.services: Dict[str, Microservice] = {
            "role-permission-service": Microservice(
                name="role-permission-service",
                port=8080,
                health_endpoint="/actuator/health"
            ),
            "auth-service": Microservice(
                name="auth-service",
                port=8081,
                health_endpoint="/actuator/health"
            ),
            "tenant-service": Microservice(
                name="tenant-service",
                port=8082,
                health_endpoint="/actuator/health"
            ),
            "user-profile-service": Microservice(
                name="user-profile-service",
                port=8083,
                health_endpoint="/actuator/health"
            ),
            "api-gateway": Microservice(
                name="api-gateway",
                port=8084,
                health_endpoint="/actuator/health"
            ),
        }
        
        # Track service status
        self.service_status: Dict[str, bool] = {}
        self.service_processes: Dict[str, subprocess.Popen] = {}
        
        # Workers
        self.health_worker: Optional[HealthCheckWorker] = None
        self.log_reader: Optional[LogReader] = None
        
        # Setup UI
        self.setup_ui()
        self.apply_styles()
        
        # Setup auto-refresh timer
        self.refresh_timer = QTimer()
        self.refresh_timer.timeout.connect(self.refresh_status)
        self.refresh_timer.start(5000)  # Refresh every 5 seconds
        
        # Initial status check
        self.refresh_status()
    
    def setup_ui(self):
        """Setup the user interface."""
        central_widget = QWidget()
        self.setCentralWidget(central_widget)
        
        main_layout = QVBoxLayout(central_widget)
        main_layout.setSpacing(10)
        main_layout.setContentsMargins(15, 15, 15, 15)
        
        # Header
        header_layout = QHBoxLayout()
        
        title_label = QLabel("Microservice Monitor")
        title_label.setFont(QFont("Arial", 18, QFont.Weight.Bold))
        header_layout.addWidget(title_label)
        
        header_layout.addStretch()
        
        # Auto-refresh controls
        self.auto_refresh_checkbox = QCheckBox("Auto Refresh")
        self.auto_refresh_checkbox.setChecked(True)
        self.auto_refresh_checkbox.stateChanged.connect(self.toggle_auto_refresh)
        header_layout.addWidget(self.auto_refresh_checkbox)
        
        self.refresh_interval_spin = QSpinBox()
        self.refresh_interval_spin.setRange(1, 60)
        self.refresh_interval_spin.setValue(5)
        self.refresh_interval_spin.setSuffix(" sec")
        self.refresh_interval_spin.valueChanged.connect(self.update_refresh_interval)
        header_layout.addWidget(self.refresh_interval_spin)
        
        self.refresh_btn = QPushButton("Refresh Now")
        self.refresh_btn.clicked.connect(self.refresh_status)
        header_layout.addWidget(self.refresh_btn)
        
        main_layout.addLayout(header_layout)
        
        # Create splitter for resizable panels
        splitter = QSplitter(Qt.Orientation.Vertical)
        
        # Services table panel
        services_group = QGroupBox("Services Status")
        services_layout = QVBoxLayout(services_group)
        
        # Services table
        self.services_table = QTableWidget()
        self.services_table.setColumnCount(6)
        self.services_table.setHorizontalHeaderLabels([
            "Service Name", "Port", "Status", "Last Check", "Actions", "Logs"
        ])
        
        # Set table properties
        header = self.services_table.horizontalHeader()
        header.setSectionResizeMode(0, QHeaderView.ResizeMode.Stretch)
        header.setSectionResizeMode(1, QHeaderView.ResizeMode.Fixed)
        header.setSectionResizeMode(2, QHeaderView.ResizeMode.Fixed)
        header.setSectionResizeMode(3, QHeaderView.ResizeMode.Fixed)
        header.setSectionResizeMode(4, QHeaderView.ResizeMode.Fixed)
        header.setSectionResizeMode(5, QHeaderView.ResizeMode.Fixed)
        
        self.services_table.setColumnWidth(1, 80)
        self.services_table.setColumnWidth(2, 100)
        self.services_table.setColumnWidth(3, 150)
        self.services_table.setColumnWidth(4, 150)
        self.services_table.setColumnWidth(5, 100)
        
        self.services_table.setAlternatingRowColors(True)
        self.services_table.setSelectionBehavior(QTableWidget.SelectionBehavior.SelectRows)
        self.services_table.verticalHeader().setVisible(False)
        
        # Populate table
        self.populate_services_table()
        
        services_layout.addWidget(self.services_table)
        
        # Bulk action buttons
        bulk_actions_layout = QHBoxLayout()
        
        self.start_all_btn = QPushButton("Start All")
        self.start_all_btn.clicked.connect(self.start_all_services)
        bulk_actions_layout.addWidget(self.start_all_btn)
        
        self.stop_all_btn = QPushButton("Stop All")
        self.stop_all_btn.clicked.connect(self.stop_all_services)
        bulk_actions_layout.addWidget(self.stop_all_btn)
        
        self.restart_all_btn = QPushButton("Restart All")
        self.restart_all_btn.clicked.connect(self.restart_all_services)
        bulk_actions_layout.addWidget(self.restart_all_btn)
        
        bulk_actions_layout.addStretch()
        
        # Status summary
        self.status_summary_label = QLabel("Checking services...")
        bulk_actions_layout.addWidget(self.status_summary_label)
        
        services_layout.addLayout(bulk_actions_layout)
        
        splitter.addWidget(services_group)
        
        # Log viewer panel
        log_group = QGroupBox("Service Logs")
        log_layout = QVBoxLayout(log_group)
        
        # Log controls
        log_controls_layout = QHBoxLayout()
        
        log_controls_layout.addWidget(QLabel("Service:"))
        self.log_service_combo = QComboBox()
        self.log_service_combo.addItems(list(self.services.keys()))
        self.log_service_combo.currentTextChanged.connect(self.on_log_service_changed)
        log_controls_layout.addWidget(self.log_service_combo)
        
        self.load_log_btn = QPushButton("Load Log File")
        self.load_log_btn.clicked.connect(self.load_log_file)
        log_controls_layout.addWidget(self.load_log_btn)
        
        self.clear_log_btn = QPushButton("Clear")
        self.clear_log_btn.clicked.connect(self.clear_log)
        log_controls_layout.addWidget(self.clear_log_btn)
        
        log_controls_layout.addStretch()
        
        log_layout.addLayout(log_controls_layout)
        
        # Log text area
        self.log_text = QTextEdit()
        self.log_text.setReadOnly(True)
        self.log_text.setFont(QFont("Courier New", 10))
        self.log_text.setPlaceholderText(
            "Select a service and click 'Load Log File' to view logs,\n"
            "or click 'View Logs' button in the table above."
        )
        log_layout.addWidget(self.log_text)
        
        splitter.addWidget(log_group)
        
        # Set splitter sizes
        splitter.setSizes([350, 300])
        
        main_layout.addWidget(splitter)
        
        # Status bar
        self.statusBar().showMessage("Ready")
    
    def populate_services_table(self):
        """Populate the services table with all microservices."""
        self.services_table.setRowCount(len(self.services))
        
        for row, (name, service) in enumerate(self.services.items()):
            # Service name
            name_item = QTableWidgetItem(service.name)
            name_item.setFlags(name_item.flags() & ~Qt.ItemFlag.ItemIsEditable)
            self.services_table.setItem(row, 0, name_item)
            
            # Port
            port_item = QTableWidgetItem(str(service.port))
            port_item.setFlags(port_item.flags() & ~Qt.ItemFlag.ItemIsEditable)
            port_item.setTextAlignment(Qt.AlignmentFlag.AlignCenter)
            self.services_table.setItem(row, 1, port_item)
            
            # Status (will be updated by health check)
            status_item = QTableWidgetItem("Checking...")
            status_item.setFlags(status_item.flags() & ~Qt.ItemFlag.ItemIsEditable)
            status_item.setTextAlignment(Qt.AlignmentFlag.AlignCenter)
            self.services_table.setItem(row, 2, status_item)
            
            # Last check time
            time_item = QTableWidgetItem("-")
            time_item.setFlags(time_item.flags() & ~Qt.ItemFlag.ItemIsEditable)
            time_item.setTextAlignment(Qt.AlignmentFlag.AlignCenter)
            self.services_table.setItem(row, 3, time_item)
            
            # Action buttons widget
            actions_widget = QWidget()
            actions_layout = QHBoxLayout(actions_widget)
            actions_layout.setContentsMargins(5, 2, 5, 2)
            actions_layout.setSpacing(5)
            
            start_btn = QPushButton("Start")
            start_btn.setFixedWidth(60)
            start_btn.clicked.connect(lambda checked, n=name: self.start_service(n))
            actions_layout.addWidget(start_btn)
            
            stop_btn = QPushButton("Stop")
            stop_btn.setFixedWidth(60)
            stop_btn.clicked.connect(lambda checked, n=name: self.stop_service(n))
            actions_layout.addWidget(stop_btn)
            
            self.services_table.setCellWidget(row, 4, actions_widget)
            
            # Log button
            log_widget = QWidget()
            log_layout = QHBoxLayout(log_widget)
            log_layout.setContentsMargins(5, 2, 5, 2)
            
            log_btn = QPushButton("View Logs")
            log_btn.clicked.connect(lambda checked, n=name: self.view_service_logs(n))
            log_layout.addWidget(log_btn)
            
            self.services_table.setCellWidget(row, 5, log_widget)
        
        # Set row height
        for row in range(self.services_table.rowCount()):
            self.services_table.setRowHeight(row, 45)
    
    def apply_styles(self):
        """Apply custom styles to the application."""
        self.setStyleSheet("""
            QMainWindow {
                background-color: #f5f5f5;
            }
            QGroupBox {
                font-weight: bold;
                border: 1px solid #cccccc;
                border-radius: 5px;
                margin-top: 10px;
                padding-top: 10px;
                background-color: white;
            }
            QGroupBox::title {
                subcontrol-origin: margin;
                left: 10px;
                padding: 0 5px;
            }
            QTableWidget {
                background-color: white;
                border: 1px solid #dddddd;
                border-radius: 3px;
                gridline-color: #eeeeee;
            }
            QTableWidget::item {
                padding: 5px;
            }
            QTableWidget::item:selected {
                background-color: #e3f2fd;
                color: black;
            }
            QHeaderView::section {
                background-color: #f8f9fa;
                padding: 8px;
                border: none;
                border-bottom: 2px solid #dee2e6;
                font-weight: bold;
            }
            QPushButton {
                background-color: #2196F3;
                color: white;
                border: none;
                padding: 8px 16px;
                border-radius: 4px;
                font-weight: bold;
            }
            QPushButton:hover {
                background-color: #1976D2;
            }
            QPushButton:pressed {
                background-color: #0D47A1;
            }
            QPushButton:disabled {
                background-color: #BDBDBD;
            }
            QTextEdit {
                border: 1px solid #dddddd;
                border-radius: 3px;
                background-color: #1e1e1e;
                color: #d4d4d4;
            }
            QComboBox {
                padding: 5px 10px;
                border: 1px solid #cccccc;
                border-radius: 3px;
                background-color: white;
            }
            QSpinBox {
                padding: 5px;
                border: 1px solid #cccccc;
                border-radius: 3px;
            }
            QCheckBox {
                spacing: 5px;
            }
            QLabel {
                color: #333333;
            }
        """)
    
    def refresh_status(self):
        """Refresh the status of all services."""
        if self.health_worker and self.health_worker.isRunning():
            return
        
        self.statusBar().showMessage("Checking services...")
        
        self.health_worker = HealthCheckWorker(self.services)
        self.health_worker.health_checked.connect(self.update_service_status)
        self.health_worker.finished.connect(self.on_health_check_finished)
        self.health_worker.start()
    
    def update_service_status(self, service_name: str, is_healthy: bool, message: str):
        """Update the status of a service in the table."""
        self.service_status[service_name] = is_healthy
        
        # Find the row for this service
        for row in range(self.services_table.rowCount()):
            name_item = self.services_table.item(row, 0)
            if name_item and name_item.text() == service_name:
                # Update status
                status_item = self.services_table.item(row, 2)
                if is_healthy:
                    status_item.setText("● Running")
                    status_item.setForeground(QColor("#4CAF50"))
                else:
                    status_item.setText("● Down")
                    status_item.setForeground(QColor("#F44336"))
                
                # Update last check time
                time_item = self.services_table.item(row, 3)
                time_item.setText(datetime.now().strftime("%H:%M:%S"))
                
                # Update tooltip with message
                status_item.setToolTip(message)
                break
    
    def on_health_check_finished(self):
        """Called when health check is complete."""
        running = sum(1 for status in self.service_status.values() if status)
        total = len(self.services)
        
        self.status_summary_label.setText(f"Services: {running}/{total} running")
        
        if running == total:
            self.status_summary_label.setStyleSheet("color: #4CAF50; font-weight: bold;")
            self.statusBar().showMessage("All services are running")
        elif running == 0:
            self.status_summary_label.setStyleSheet("color: #F44336; font-weight: bold;")
            self.statusBar().showMessage("All services are down")
        else:
            self.status_summary_label.setStyleSheet("color: #FF9800; font-weight: bold;")
            self.statusBar().showMessage(f"{running}/{total} services running")
    
    def toggle_auto_refresh(self, state):
        """Toggle automatic refresh."""
        if state == Qt.CheckState.Checked.value:
            interval = self.refresh_interval_spin.value() * 1000
            self.refresh_timer.start(interval)
        else:
            self.refresh_timer.stop()
    
    def update_refresh_interval(self, value):
        """Update the refresh interval."""
        if self.auto_refresh_checkbox.isChecked():
            self.refresh_timer.setInterval(value * 1000)
    
    def start_service(self, service_name: str):
        """Start a specific service."""
        service = self.services.get(service_name)
        if not service:
            return
        
        # Show dialog to get start command
        msg = QMessageBox(self)
        msg.setWindowTitle(f"Start {service_name}")
        msg.setText(f"Enter the command to start {service_name}:")
        msg.setInformativeText(
            f"Example commands:\n"
            f"• java -jar {service_name}.jar\n"
            f"• ./gradlew bootRun\n"
            f"• mvn spring-boot:run\n\n"
            f"Note: The service will be started in a new terminal window."
        )
        msg.setIcon(QMessageBox.Icon.Information)
        msg.setStandardButtons(QMessageBox.StandardButton.Ok | QMessageBox.StandardButton.Cancel)
        
        if msg.exec() == QMessageBox.StandardButton.Ok:
            # Try to find common service directories
            possible_dirs = [
                os.path.expanduser(f"~/Learner-microservices/{service_name}"),
                os.path.expanduser(f"~/{service_name}"),
                os.path.join(os.getcwd(), "..", service_name),
            ]
            
            working_dir = None
            for d in possible_dirs:
                if os.path.exists(d):
                    working_dir = d
                    break
            
            if working_dir:
                # Open terminal with the service directory
                if sys.platform == "darwin":
                    cmd = f'osascript -e \'tell app "Terminal" to do script "cd {working_dir} && echo Starting {service_name}..."\''
                else:
                    cmd = f'gnome-terminal -- bash -c "cd {working_dir}; bash"'
                
                try:
                    subprocess.Popen(cmd, shell=True)
                    self.statusBar().showMessage(f"Opening terminal for {service_name}...")
                except Exception as e:
                    QMessageBox.warning(self, "Error", f"Failed to open terminal: {e}")
            else:
                QMessageBox.information(
                    self, "Manual Start Required",
                    f"Please start {service_name} manually.\n\n"
                    f"Navigate to the service directory and run your start command.\n"
                    f"The monitor will detect when the service is running."
                )
    
    def stop_service(self, service_name: str):
        """Stop a specific service."""
        service = self.services.get(service_name)
        if not service:
            return
        
        reply = QMessageBox.question(
            self, f"Stop {service_name}",
            f"This will attempt to stop the process on port {service.port}.\n\n"
            f"Do you want to continue?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        
        if reply == QMessageBox.StandardButton.Yes:
            try:
                # Find and kill process on the port
                if sys.platform == "darwin" or sys.platform.startswith("linux"):
                    # Use lsof to find process
                    result = subprocess.run(
                        ["lsof", "-t", f"-i:{service.port}"],
                        capture_output=True, text=True
                    )
                    if result.stdout.strip():
                        pids = result.stdout.strip().split('\n')
                        for pid in pids:
                            subprocess.run(["kill", "-9", pid])
                        self.statusBar().showMessage(f"Stopped {service_name}")
                        QTimer.singleShot(1000, self.refresh_status)
                    else:
                        self.statusBar().showMessage(f"No process found on port {service.port}")
                else:
                    # Windows
                    subprocess.run(
                        f"for /f \"tokens=5\" %a in ('netstat -aon ^| findstr :{service.port}') do taskkill /F /PID %a",
                        shell=True
                    )
                    self.statusBar().showMessage(f"Stopped {service_name}")
                    QTimer.singleShot(1000, self.refresh_status)
            except Exception as e:
                QMessageBox.warning(self, "Error", f"Failed to stop service: {e}")
    
    def start_all_services(self):
        """Start all services."""
        QMessageBox.information(
            self, "Start All Services",
            "To start all services, please use your deployment scripts or "
            "docker-compose if available.\n\n"
            "The monitor will detect when services are running."
        )
    
    def stop_all_services(self):
        """Stop all services."""
        reply = QMessageBox.question(
            self, "Stop All Services",
            "This will attempt to stop all running services.\n\n"
            "Do you want to continue?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        
        if reply == QMessageBox.StandardButton.Yes:
            for name in self.services:
                if self.service_status.get(name, False):
                    self.stop_service(name)
    
    def restart_all_services(self):
        """Restart all services."""
        QMessageBox.information(
            self, "Restart All Services",
            "Please use your deployment scripts or docker-compose "
            "to restart all services.\n\n"
            "The monitor will detect when services are running."
        )
    
    def view_service_logs(self, service_name: str):
        """View logs for a specific service."""
        self.log_service_combo.setCurrentText(service_name)
        
        # Try to find log files
        possible_log_paths = [
            os.path.expanduser(f"~/Learner-microservices/{service_name}/logs/application.log"),
            os.path.expanduser(f"~/Learner-microservices/{service_name}/app.log"),
            os.path.expanduser(f"~/{service_name}/logs/application.log"),
            f"/var/log/{service_name}/application.log",
            os.path.join(os.getcwd(), "..", service_name, "logs", "application.log"),
        ]
        
        log_found = False
        for log_path in possible_log_paths:
            if os.path.exists(log_path):
                self.load_log_from_path(log_path)
                log_found = True
                break
        
        if not log_found:
            self.log_text.setPlainText(
                f"No log file found for {service_name}.\n\n"
                f"Searched in:\n" + "\n".join(f"  • {p}" for p in possible_log_paths) +
                "\n\nClick 'Load Log File' to manually select a log file."
            )
    
    def on_log_service_changed(self, service_name: str):
        """Handle service selection change in log viewer."""
        pass  # Don't auto-load, let user click View Logs
    
    def load_log_file(self):
        """Open file dialog to load a log file."""
        file_path, _ = QFileDialog.getOpenFileName(
            self, "Open Log File",
            os.path.expanduser("~"),
            "Log Files (*.log *.txt);;All Files (*)"
        )
        
        if file_path:
            self.load_log_from_path(file_path)
    
    def load_log_from_path(self, log_path: str):
        """Load log content from a specific path."""
        self.log_text.setPlainText(f"Loading {log_path}...")
        
        if self.log_reader and self.log_reader.isRunning():
            self.log_reader.stop()
            self.log_reader.wait()
        
        self.log_reader = LogReader(log_path)
        self.log_reader.log_updated.connect(self.update_log_display)
        self.log_reader.start()
    
    def update_log_display(self, content: str):
        """Update the log display with new content."""
        self.log_text.setPlainText(content)
        # Scroll to bottom
        scrollbar = self.log_text.verticalScrollBar()
        scrollbar.setValue(scrollbar.maximum())
    
    def clear_log(self):
        """Clear the log display."""
        self.log_text.clear()
    
    def closeEvent(self, event):
        """Handle application close."""
        # Stop workers
        if self.health_worker and self.health_worker.isRunning():
            self.health_worker.stop()
            self.health_worker.wait()
        
        if self.log_reader and self.log_reader.isRunning():
            self.log_reader.stop()
            self.log_reader.wait()
        
        # Stop timer
        self.refresh_timer.stop()
        
        event.accept()


def main():
    """Main entry point."""
    app = QApplication(sys.argv)
    app.setApplicationName("Microservice Monitor")
    app.setStyle("Fusion")
    
    # Set application-wide font
    font = QFont("Segoe UI", 10)
    app.setFont(font)
    
    window = MicroserviceMonitor()
    window.show()
    
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
