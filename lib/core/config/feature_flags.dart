/// Feature flags pour activer/désactiver des fonctionnalités
class FeatureFlags {
  // Activer le Realtime pour les notifications temps réel (likes, matches, messages)
  static const bool enableRealtime = true;

  // Polling interval quand Realtime est désactivé (en secondes)
  static const int pollingInterval = 3;

  // Activer les logs détaillés
  static const bool verboseLogs = true;
}
