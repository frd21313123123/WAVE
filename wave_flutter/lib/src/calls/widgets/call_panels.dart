import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../../models/call_models.dart';
import '../../widgets/wave_avatar.dart';
import '../call_media_engine.dart';

class IncomingCallSheet extends StatelessWidget {
  const IncomingCallSheet({
    super.key,
    required this.state,
    required this.onAccept,
    required this.onReject,
    this.onAcceptWithVideo,
  });

  final CallUiState state;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback? onAcceptWithVideo;

  @override
  Widget build(BuildContext context) {
    final pendingIncoming = state.pendingIncoming;
    if (pendingIncoming == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final peer = pendingIncoming.peer;
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF132C62),
                borderRadius: BorderRadius.circular(28),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 32,
                    offset: Offset(0, 16),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Входящий звонок',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        _PeerAvatar(
                          label: peer.displayName,
                          avatarUrl: peer.avatarUrl,
                          radius: 28,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                peer.displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pendingIncoming.videoRequested
                                    ? 'Видео включено у вызывающего абонента'
                                    : 'Голосовой вызов',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _CallButton(
                            icon: Icons.call_end_rounded,
                            label: 'Отклонить',
                            backgroundColor: const Color(0xFFD63C56),
                            onPressed:
                                state.incomingActionInFlight ? null : onReject,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CallButton(
                            icon: Icons.call_rounded,
                            label: 'Ответить',
                            backgroundColor: const Color(0xFF1F8A4C),
                            onPressed:
                                state.incomingActionInFlight ? null : onAccept,
                          ),
                        ),
                        if (onAcceptWithVideo != null) ...<Widget>[
                          const SizedBox(width: 12),
                          Expanded(
                            child: _CallButton(
                              icon: Icons.videocam_rounded,
                              label: 'С камерой',
                              backgroundColor: const Color(0xFF2C7BE5),
                              onPressed: state.incomingActionInFlight
                                  ? null
                                  : onAcceptWithVideo,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ActiveCallSheet extends StatelessWidget {
  const ActiveCallSheet({
    super.key,
    required this.state,
    required this.onEnd,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleCamera,
    this.mediaEngine,
    this.expandToFill = false,
  });

  final CallUiState state;
  final CallMediaEngine? mediaEngine;
  final VoidCallback onEnd;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleCamera;
  final bool expandToFill;

  @override
  Widget build(BuildContext context) {
    if (!state.hasLiveCall && !state.isIncoming) {
      return const SizedBox.shrink();
    }

    final peer = state.peer ?? state.pendingIncoming?.peer;
    if (peer == null) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    final body = DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            Color(0xFF071936),
            Color(0xFF0F2A58),
            Color(0xFF173B78),
          ],
        ),
        borderRadius: expandToFill ? BorderRadius.zero : BorderRadius.circular(32),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          expandToFill ? 28 : 22,
          20,
          expandToFill ? 28 : 20,
        ),
        child: Column(
          children: <Widget>[
            Expanded(
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(expandToFill ? 0 : 24),
                      child: DecoratedBox(
                        decoration: const BoxDecoration(color: Color(0xFF0A1730)),
                        child: _RemoteVideoSurface(
                          state: state,
                          mediaEngine: mediaEngine,
                          peer: peer,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 18,
                    left: 18,
                    right: 18,
                    child: _CallHeadline(
                      peer: peer,
                      statusText: _effectiveStatusText(state),
                      elapsedLabel: state.elapsedLabel,
                    ),
                  ),
                  Positioned(
                    right: 18,
                    bottom: 18,
                    child: _LocalVideoPreview(
                      state: state,
                      mediaEngine: mediaEngine,
                      peer: peer,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 14,
              children: <Widget>[
                _RoundControlButton(
                  icon: state.muted ? Icons.mic_off_rounded : Icons.mic_rounded,
                  label: state.muted ? 'Микрофон выкл' : 'Микрофон',
                  active: !state.muted,
                  onPressed: onToggleMute,
                ),
                _RoundControlButton(
                  icon: state.speakerEnabled
                      ? Icons.volume_up_rounded
                      : Icons.hearing_disabled_rounded,
                  label: state.speakerEnabled ? 'Динамик' : 'Трубка',
                  active: state.speakerEnabled,
                  onPressed: onToggleSpeaker,
                ),
                _RoundControlButton(
                  icon: state.cameraEnabled
                      ? Icons.videocam_rounded
                      : Icons.videocam_off_rounded,
                  label: state.cameraEnabled ? 'Камера' : 'Без камеры',
                  active: state.cameraEnabled,
                  onPressed: onToggleCamera,
                ),
                _RoundControlButton(
                  icon: Icons.call_end_rounded,
                  label: 'Завершить',
                  active: false,
                  backgroundColor: const Color(0xFFD63C56),
                  foregroundColor: Colors.white,
                  onPressed: onEnd,
                ),
              ],
            ),
            if (!expandToFill) ...<Widget>[
              const SizedBox(height: 10),
              Text(
                'Вынесите этот виджет в bottom sheet или overlay.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white54,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (expandToFill) {
      return body;
    }

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 520,
            width: 420,
            child: body,
          ),
        ),
      ),
    );
  }
}

class ActiveCallScreen extends StatelessWidget {
  const ActiveCallScreen({
    super.key,
    required this.state,
    required this.onEnd,
    required this.onToggleMute,
    required this.onToggleSpeaker,
    required this.onToggleCamera,
    this.mediaEngine,
  });

  final CallUiState state;
  final CallMediaEngine? mediaEngine;
  final VoidCallback onEnd;
  final VoidCallback onToggleMute;
  final VoidCallback onToggleSpeaker;
  final VoidCallback onToggleCamera;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071936),
      body: SafeArea(
        child: ActiveCallSheet(
          state: state,
          mediaEngine: mediaEngine,
          onEnd: onEnd,
          onToggleMute: onToggleMute,
          onToggleSpeaker: onToggleSpeaker,
          onToggleCamera: onToggleCamera,
          expandToFill: true,
        ),
      ),
    );
  }
}

class _RemoteVideoSurface extends StatelessWidget {
  const _RemoteVideoSurface({
    required this.state,
    required this.mediaEngine,
    required this.peer,
  });

  final CallUiState state;
  final CallMediaEngine? mediaEngine;
  final CallPeerSnapshot peer;

  @override
  Widget build(BuildContext context) {
    final renderer = mediaEngine?.remoteRenderer;
    if (renderer != null && state.remoteVideoVisible) {
      return RTCVideoView(
        renderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      );
    }

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF183563), Color(0xFF0C1B37)],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _PeerAvatar(
              label: peer.displayName,
              avatarUrl: peer.avatarUrl,
              radius: 44,
            ),
            const SizedBox(height: 16),
            Text(
              peer.displayName,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalVideoPreview extends StatelessWidget {
  const _LocalVideoPreview({
    required this.state,
    required this.mediaEngine,
    required this.peer,
  });

  final CallUiState state;
  final CallMediaEngine? mediaEngine;
  final CallPeerSnapshot peer;

  @override
  Widget build(BuildContext context) {
    final renderer = mediaEngine?.localRenderer;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 112,
        height: 156,
        color: const Color(0xFF0C1730),
        child: renderer != null && state.localVideoVisible
            ? RTCVideoView(
                renderer,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                mirror: true,
              )
            : Center(
                child: _PeerAvatar(
                  label: 'Я',
                  avatarUrl: null,
                  radius: 26,
                ),
              ),
      ),
    );
  }
}

class _CallHeadline extends StatelessWidget {
  const _CallHeadline({
    required this.peer,
    required this.statusText,
    required this.elapsedLabel,
  });

  final CallPeerSnapshot peer;
  final String statusText;
  final String elapsedLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          peer.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Text(
              statusText,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            if (elapsedLabel != '00:00') ...<Widget>[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x26000000),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  elapsedLabel,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _PeerAvatar extends StatelessWidget {
  const _PeerAvatar({
    required this.label,
    required this.avatarUrl,
    required this.radius,
  });

  final String label;
  final String? avatarUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final initials = _initialsFor(label);
    final imageProvider = WaveAvatar.providerFromValue(avatarUrl);
    final child = imageProvider != null
        ? ClipOval(
            child: Image(
              image: imageProvider,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
            ),
          )
        : Center(
            child: Text(
              initials,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          );

    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF4F9CFF), Color(0xFF2557B8)],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}

class _CallButton extends StatelessWidget {
  const _CallButton({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class _RoundControlButton extends StatelessWidget {
  const _RoundControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final Color resolvedBackground = backgroundColor ??
        (active ? const Color(0xFF1D57C8) : const Color(0x1FFFFFFF));
    final Color resolvedForeground =
        foregroundColor ?? (active ? Colors.white : Colors.white70);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkResponse(
          onTap: onPressed,
          radius: 34,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: resolvedBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: resolvedForeground, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white70,
              ),
        ),
      ],
    );
  }
}

String _effectiveStatusText(CallUiState state) {
  if (state.statusText.trim().isNotEmpty) {
    return state.statusText;
  }
  if (state.isOutgoing) {
    return 'Звоним...';
  }
  if (state.isReconnecting) {
    return 'Переустанавливаем соединение...';
  }
  return 'В звонке';
}

String _initialsFor(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return '?';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
