import 'package:workmanager/workmanager.dart';
import 'rental_reminder_service.dart';

// Background task callback (must be top-level function)
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print('🔧 Background task running: $task');
    
    switch (task) {
      case 'rentalReminderTask':
        await RentalReminderService.checkAndSendReminders();
        break;
      case 'dailyCheckTask':
        await RentalReminderService.checkAndSendReminders();
        break;
      default:
        print('⚠️ Unknown task: $task');
    }
    
    return Future.value(true);
  });
}

class BackgroundService {
  // Initialize background service
  static Future<void> init() async {
    // Initialize Workmanager
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Set to true for debugging
    );
    
    // Register periodic task (runs every 24 hours)
    await Workmanager().registerPeriodicTask(
      "rental-reminder-task",
      "rentalReminderTask",
      frequency: Duration(hours: 24),
      existingWorkPolicy: ExistingWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    // Also register a one-time task for immediate check
    await Workmanager().registerOneOffTask(
      "initial-check",
      "rentalReminderTask",
      initialDelay: Duration(seconds: 10),
    );
    
    print('✅ Background service initialized');
  }
  
  // Cancel all background tasks
  static Future<void> cancelAll() async {
    await Workmanager().cancelAll();
    print('❌ All background tasks cancelled');
  }
  
  // Force immediate check (for testing)
  static Future<void> forceCheck() async {
    await RentalReminderService.checkAndSendReminders();
  }
}