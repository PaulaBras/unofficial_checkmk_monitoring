import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/downtime.dart';
import '../utils/downtime_constants.dart';

class DowntimeForm extends StatefulWidget {
  final String hostName;
  final String? serviceDescription;
  final Function(DowntimeRequest) onSubmit;

  const DowntimeForm({
    Key? key,
    required this.hostName,
    required this.onSubmit,
    this.serviceDescription,
  }) : super(key: key);

  @override
  State<DowntimeForm> createState() => _DowntimeFormState();
}

class _DowntimeFormState extends State<DowntimeForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();

  DateTime? _startTime;
  DateTime? _endTime;
  String _recur = DowntimeConstants.defaultRecur;
  int _duration = DowntimeConstants.defaultDuration;

  bool get _isServiceDowntime => widget.serviceDescription != null;

  @override
  void initState() {
    super.initState();
    _commentController.text = DowntimeConstants.defaultComment;

    // Set default start time to current time
    _startTime = DateTime.now();
    // Set default end time to 2 hours from now
    _endTime = DateTime.now().add(const Duration(hours: 2));
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      // Validate time selection
      if (_startTime == null || _endTime == null) {
        _showValidationError('Please select start and end times');
        return;
      }

      // Validate time range
      if (_endTime!.isBefore(_startTime!)) {
        _showValidationError(DowntimeConstants.invalidTimeRangeMessage);
        return;
      }

      // Validate minimum duration (at least 1 minute)
      if (_endTime!.difference(_startTime!).inMinutes < 1) {
        _showValidationError('Downtime duration must be at least 1 minute');
        return;
      }

      // Validate maximum duration (not more than 1 year)
      if (_endTime!.difference(_startTime!).inDays > 365) {
        _showValidationError('Downtime duration cannot exceed 1 year');
        return;
      }

      // Validate start time is not in the past (allow 1 minute tolerance)
      if (_startTime!
          .isBefore(DateTime.now().subtract(const Duration(minutes: 1)))) {
        _showValidationError('Start time cannot be in the past');
        return;
      }

      final request = DowntimeRequest(
        startTime: DateFormat('yyyy-MM-ddTHH:mm:ss').format(_startTime!),
        endTime: DateFormat('yyyy-MM-ddTHH:mm:ss').format(_endTime!),
        recur: _recur,
        duration: _duration,
        comment: _commentController.text.trim(),
        downtimeType: _isServiceDowntime
            ? DowntimeType.service.value
            : DowntimeType.host.value,
        hostName: widget.hostName,
        serviceDescription: widget.serviceDescription,
      );

      widget.onSubmit(request);
    }
  }

  void _showValidationError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, bool isStartTime) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isStartTime
          ? (_startTime ?? DateTime.now())
          : (_endTime ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(isStartTime
            ? (_startTime ?? DateTime.now())
            : (_endTime ?? DateTime.now())),
      );

      if (pickedTime != null) {
        final DateTime selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isStartTime) {
            _startTime = selectedDateTime;
            // Auto-adjust end time if it's before start time
            if (_endTime != null && _endTime!.isBefore(_startTime!)) {
              _endTime = _startTime!.add(const Duration(hours: 2));
            }
          } else {
            _endTime = selectedDateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildCommentField(),
                  const SizedBox(height: DowntimeConstants.formSpacing),
                  _buildHostNameField(),
                  if (_isServiceDowntime) ...[
                    const SizedBox(height: DowntimeConstants.formSpacing),
                    _buildServiceDescriptionField(),
                  ],
                  const SizedBox(height: DowntimeConstants.formSpacing),
                  _buildTimeSection(),
                  const SizedBox(height: DowntimeConstants.formSpacing),
                  _buildOptionsSection(),
                  const SizedBox(height: DowntimeConstants.formSpacing),
                  _buildPreviewSection(),
                  const SizedBox(height: 16), // Space before button
                ],
              ),
            ),
          ),
        ),
        // Sticky submit button at bottom
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: _buildSubmitButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildCommentField() {
    return TextFormField(
      controller: _commentController,
      decoration: const InputDecoration(
        labelText: 'Comment',
        border: OutlineInputBorder(),
        hintText: 'Reason for downtime',
      ),
      maxLines: DowntimeConstants.maxCommentLines,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return DowntimeConstants.commentRequiredMessage;
        }
        return null;
      },
    );
  }

  Widget _buildHostNameField() {
    return TextFormField(
      initialValue: widget.hostName,
      decoration: const InputDecoration(
        labelText: 'Host Name',
        border: OutlineInputBorder(),
      ),
      enabled: false,
    );
  }

  Widget _buildServiceDescriptionField() {
    return TextFormField(
      initialValue: widget.serviceDescription,
      decoration: const InputDecoration(
        labelText: 'Service Description',
        border: OutlineInputBorder(),
      ),
      enabled: false,
    );
  }

  Widget _buildTimeSection() {
    final dateFormatter = DateFormat(DowntimeConstants.displayDateTimeFormat);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Downtime Period',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateTime(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Start Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _startTime != null
                            ? dateFormatter.format(_startTime!)
                            : 'Select',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDateTime(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'End Time',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _endTime != null
                            ? dateFormatter.format(_endTime!)
                            : 'Select',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_startTime != null && _endTime != null) ...[
              const SizedBox(height: 8),
              Text(
                'Duration: ${_formatDuration(_endTime!.difference(_startTime!))}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Options',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _recur,
              decoration: const InputDecoration(
                labelText: 'Recurrence Type',
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: RecurrenceType.fixed.value,
                  child: const Text('Fixed'),
                ),
                DropdownMenuItem(
                  value: RecurrenceType.flexible.value,
                  child: const Text('Flexible'),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  _recur = value ?? DowntimeConstants.defaultRecur;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    if (_startTime == null ||
        _endTime == null ||
        _commentController.text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final dateFormatter = DateFormat('MMM dd, HH:mm');
    final duration = _endTime!.difference(_startTime!);

    return Card(
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.preview,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Downtime Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Target row
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Target',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isServiceDowntime
                        ? '${widget.serviceDescription} on ${widget.hostName}'
                        : widget.hostName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              dateFormatter.format(_startTime!),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'End',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Colors.red[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              dateFormatter.format(_endTime!),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDuration(duration),
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ],
                  ),
                  if (_commentController.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Comment',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      _commentController.text.trim(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _handleSubmit,
      icon: const Icon(Icons.schedule),
      label: Text(_isServiceDowntime
          ? 'Schedule Service Downtime'
          : 'Schedule Host Downtime'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    final parts = <String>[];
    if (days > 0) parts.add('${days}d');
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');

    return parts.isNotEmpty ? parts.join(' ') : '0m';
  }
}
