import 'package:flutter/material.dart';
import '../../core/models/report_model.dart';
import '../../core/services/backend_service.dart';

class ReportUserDialog extends StatefulWidget {
  final String reportedUserId;
  final String reportedUserName;

  const ReportUserDialog({
    super.key,
    required this.reportedUserId,
    required this.reportedUserName,
  });

  @override
  State<ReportUserDialog> createState() => _ReportUserDialogState();
}

class _ReportUserDialogState extends State<ReportUserDialog> {
  final BackendService _backend = BackendService();
  String _selectedReportType = ReportModel.harassment;
  final TextEditingController _descriptionController = TextEditingController();
  bool _isSubmitting = false;
  bool _alsoBlock = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez décrire le problème')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Create report
      await _backend.reportUser(
        reportedUserId: widget.reportedUserId,
        reportType: _selectedReportType,
        description: _descriptionController.text.trim(),
      );

      // Also block if requested
      if (_alsoBlock) {
        await _backend.blockUser(
          widget.reportedUserId,
          reason: 'Signalé: ${ReportModel.getReportTypeLabel(_selectedReportType)}',
        );
      }

      if (!mounted) return;

      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _alsoBlock
                ? 'Utilisateur signalé et bloqué'
                : 'Utilisateur signalé. Merci pour votre aide.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Signaler ${widget.reportedUserName}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pourquoi signalez-vous cet utilisateur ?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...ReportModel.reportTypes.map((type) {
              return RadioListTile<String>(
                title: Text(ReportModel.getReportTypeLabel(type)),
                value: type,
                groupValue: _selectedReportType,
                onChanged: _isSubmitting
                    ? null
                    : (value) {
                        setState(() => _selectedReportType = value!);
                      },
                dense: true,
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (obligatoire)',
                hintText: 'Décrivez le problème...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              enabled: !_isSubmitting,
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Bloquer également cet utilisateur'),
              subtitle: const Text(
                'Vous ne verrez plus ce profil',
                style: TextStyle(fontSize: 12),
              ),
              value: _alsoBlock,
              onChanged: _isSubmitting
                  ? null
                  : (value) {
                      setState(() => _alsoBlock = value ?? false);
                    },
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submitReport,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Signaler'),
        ),
      ],
    );
  }
}

// Dialog for blocking user
class BlockUserDialog extends StatelessWidget {
  final String blockedUserId;
  final String blockedUserName;

  const BlockUserDialog({
    super.key,
    required this.blockedUserId,
    required this.blockedUserName,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Bloquer $blockedUserName ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Cet utilisateur :'),
          const SizedBox(height: 8),
          const Text('• N\'apparaîtra plus dans vos suggestions'),
          const Text('• Ne pourra plus vous voir'),
          const Text('• Ne pourra plus vous contacter'),
          const SizedBox(height: 16),
          const Text(
            'Vous pouvez débloquer cet utilisateur plus tard depuis les paramètres.',
            style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await BackendService().blockUser(blockedUserId);
              if (!context.mounted) return;
              Navigator.of(context).pop(true);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Utilisateur bloqué'),
                  backgroundColor: Colors.orange,
                ),
              );
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Bloquer'),
        ),
      ],
    );
  }
}
