import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/host.dart';
import '../models/service.dart';
import '../utils/ui_constants.dart';
import '../utils/state_helper.dart';

class HostListItem extends StatelessWidget {
  final Host host;
  final VoidCallback? onTap;
  final Widget? trailing;

  const HostListItem({
    Key? key,
    required this.host,
    this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stateName = StateHelper.getHostStateName(host.state);
    final lastCheckTime =
        DateTime.fromMillisecondsSinceEpoch(host.lastCheck * 1000);
    final timeFormatter = DateFormat('MMM dd, HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: UiConstants.defaultPadding,
        vertical: UiConstants.smallPadding,
      ),
      elevation: UiConstants.cardElevation,
      child: ListTile(
        contentPadding: const EdgeInsets.all(UiConstants.defaultPadding),
        onTap: onTap,
        leading: StateHelper.buildStateIcon(stateName, size: 32),
        title: Text(
          host.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: UiConstants.titleFontSize,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address: ${host.address}',
              style: const TextStyle(fontSize: UiConstants.subtitleFontSize),
            ),
            const SizedBox(height: UiConstants.smallSpacing),
            Text(
              'Last Check: ${timeFormatter.format(lastCheckTime)}',
              style: TextStyle(
                fontSize: UiConstants.captionFontSize,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Services: ${host.totalServices}',
              style: TextStyle(
                fontSize: UiConstants.captionFontSize,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StateHelper.buildStateChip(stateName),
            if (host.acknowledged > 0) ...[
              const SizedBox(height: UiConstants.smallSpacing),
              const Icon(Icons.check_circle, color: Colors.orange, size: 16),
            ],
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class ServiceListItem extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showHostName;

  const ServiceListItem({
    Key? key,
    required this.service,
    this.onTap,
    this.trailing,
    this.showHostName = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stateName = StateHelper.getServiceStateName(service.state);
    final lastCheckTime =
        DateTime.fromMillisecondsSinceEpoch(service.lastCheck * 1000);
    final timeFormatter = DateFormat('MMM dd, HH:mm');

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: UiConstants.defaultPadding,
        vertical: UiConstants.smallPadding,
      ),
      elevation: UiConstants.cardElevation,
      child: ListTile(
        contentPadding: const EdgeInsets.all(UiConstants.defaultPadding),
        onTap: onTap,
        leading: StateHelper.buildStateIcon(stateName, size: 32),
        title: Text(
          service.description,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: UiConstants.titleFontSize,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHostName)
              Text(
                'Host: ${service.hostName}',
                style: const TextStyle(fontSize: UiConstants.subtitleFontSize),
              ),
            if (service.pluginOutput.isNotEmpty) ...[
              const SizedBox(height: UiConstants.smallSpacing),
              Text(
                service.pluginOutput,
                style: TextStyle(
                  fontSize: UiConstants.captionFontSize,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: UiConstants.smallSpacing),
            Text(
              'Last Check: ${timeFormatter.format(lastCheckTime)}',
              style: TextStyle(
                fontSize: UiConstants.captionFontSize,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Attempt: ${service.currentAttempt}/${service.maxCheckAttempts}',
              style: TextStyle(
                fontSize: UiConstants.captionFontSize,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StateHelper.buildStateChip(stateName),
            if (service.acknowledged > 0) ...[
              const SizedBox(height: UiConstants.smallSpacing),
              const Icon(Icons.check_circle, color: Colors.orange, size: 16),
            ],
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class StatisticsCard extends StatelessWidget {
  final Map<String, int> statistics;
  final String title;

  const StatisticsCard({
    Key? key,
    required this.statistics,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(UiConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(UiConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: UiConstants.titleFontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: UiConstants.defaultSpacing),
            Wrap(
              spacing: UiConstants.defaultSpacing,
              runSpacing: UiConstants.smallSpacing,
              children: statistics.entries.map((entry) {
                return Chip(
                  avatar: entry.key != 'Total'
                      ? StateHelper.buildStateIcon(entry.key, size: 16)
                      : const Icon(Icons.analytics, size: 16),
                  label: Text('${entry.key}: ${entry.value}'),
                  backgroundColor: entry.key != 'Total'
                      ? StateHelper.getStateColor(entry.key).withOpacity(0.1)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
