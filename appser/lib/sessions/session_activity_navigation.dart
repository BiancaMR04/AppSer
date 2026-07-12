import 'dart:async';

import 'package:appser/resources/audios/audio_player.dart';
import 'package:appser/resources/docs/folheto_text_view.dart';
import 'package:appser/resources/docs/inline_text_view.dart';
import 'package:appser/resources/docs/material_text_catalog.dart';
import 'package:appser/resources/docs/pdf_view.dart';
import 'package:appser/resources/videos/video_player.dart';
import 'package:appser/screens/user_tracking_service.dart';
import 'package:appser/services/practice_resume_service.dart';
import 'package:appser/sessions/praticando_em_casa_text_catalog.dart';
import 'package:appser/sessions/session_catalog.dart';
import 'package:flutter/material.dart';

int? sessionNumberFromSessaoId(String? sessaoId) {
  if (sessaoId == null) return null;
  final match = RegExp(r'^sessao_(\d+)$').firstMatch(sessaoId.trim());
  final raw = match?.group(1);
  if (raw == null) return null;
  return int.tryParse(raw);
}

bool hasNextSessionContentItem({
  required String? sessaoId,
  required String? itemId,
}) {
  final sessionNumber = sessionNumberFromSessaoId(sessaoId);
  if (sessionNumber == null || itemId == null) return false;

  final items = SessionCatalog.contentItemsFor(sessionNumber);
  final index = items.indexWhere((item) => item.itemId == itemId);
  return index >= 0 && index < items.length - 1;
}

({int sessionNumber, SessionContentItem item})? _nextSessionContentItem({
  required String? sessaoId,
  required String? itemId,
}) {
  final sessionNumber = sessionNumberFromSessaoId(sessaoId);
  if (sessionNumber == null || itemId == null) return null;

  final items = SessionCatalog.contentItemsFor(sessionNumber);
  final index = items.indexWhere((item) => item.itemId == itemId);
  if (index < 0 || index >= items.length - 1) return null;

  return (sessionNumber: sessionNumber, item: items[index + 1]);
}

Widget buildSessionContentDestination({
  required int sessionNumber,
  required SessionContentItem item,
}) {
  final sessionId = 'sessao_$sessionNumber';

  switch (item.type) {
    case SessionContentType.audio:
      return AudioPlayerScreen(
        audioPath: item.path,
        audioTitle: item.viewerTitle,
        sessaoId: sessionId,
        itemId: item.itemId,
        isSupplementary: false,
      );
    case SessionContentType.video:
      return VideoPlayerScreen(
        videoPath: item.path,
        videoTitle: item.viewerTitle,
        sessaoId: sessionId,
        itemId: item.itemId,
        isSupplementary: false,
      );
    case SessionContentType.pdf:
      if (item.itemId == 'praticando_em_casa') {
        return InlineTextViewerScreen(
          title: item.viewerTitle,
          text: PraticandoEmCasaTextCatalog.forSession(sessionNumber),
          sessaoId: sessionId,
          itemId: item.itemId,
          isSupplementary: false,
        );
      }

      final normalizedTitle = item.title
          .replaceFirst(RegExp(r'^\s*\d+\.\s*'), '')
          .trim()
          .toLowerCase();
      final normalizedPdfTitle = item.viewerTitle.toLowerCase();
      final materialText = MaterialTextCatalog.forMaterial(
        sessionNumber: sessionNumber,
        normalizedTitle: normalizedTitle,
        normalizedPdfTitle: normalizedPdfTitle,
      );

      if (materialText != null) {
        return FolhetoTextViewerScreen(
          title: item.viewerTitle,
          text: materialText,
          sessaoId: sessionId,
          itemId: item.itemId,
          isSupplementary: false,
        );
      }

      return PdfViewerScreen(
        pdfPath: item.path,
        downloadPath: item.downloadPath ?? item.path,
        pdfTitle: item.viewerTitle,
        sessaoId: sessionId,
        itemId: item.itemId,
        isSupplementary: false,
      );
  }
}

Future<bool> openNextSessionContentItem({
  required BuildContext context,
  required String? sessaoId,
  required String? itemId,
  bool replaceCurrent = true,
}) async {
  final navigator = Navigator.of(context);
  final nextTarget = _nextSessionContentItem(
    sessaoId: sessaoId,
    itemId: itemId,
  );
  if (nextTarget == null) return false;

  return _openNextSessionContentItemWithNavigator(
    navigator: navigator,
    sessionNumber: nextTarget.sessionNumber,
    next: nextTarget.item,
    replaceCurrent: replaceCurrent,
  );
}

Future<bool> openNextSessionContentItemWithNavigator({
  required NavigatorState navigator,
  required String? sessaoId,
  required String? itemId,
  bool replaceCurrent = true,
}) async {
  final nextTarget = _nextSessionContentItem(
    sessaoId: sessaoId,
    itemId: itemId,
  );
  if (nextTarget == null) return false;

  return _openNextSessionContentItemWithNavigator(
    navigator: navigator,
    sessionNumber: nextTarget.sessionNumber,
    next: nextTarget.item,
    replaceCurrent: replaceCurrent,
  );
}

Future<bool> _openNextSessionContentItemWithNavigator({
  required NavigatorState navigator,
  required int sessionNumber,
  required SessionContentItem next,
  required bool replaceCurrent,
}) async {
  final sessionId = 'sessao_$sessionNumber';

  await PracticeResumeService.setTarget(
    sessionNumber: sessionNumber,
    itemId: next.itemId,
  );

  unawaited(
    UserTrackingService.registrarClique(
      sessaoId: sessionId,
      tipo: trackingTypeForSessionContent(next.type),
      itemId: next.itemId,
    ),
  );

  final destination = buildSessionContentDestination(
    sessionNumber: sessionNumber,
    item: next,
  );
  final route = MaterialPageRoute(builder: (_) => destination);

  if (replaceCurrent) {
    await navigator.pushReplacement(route);
  } else {
    await navigator.push(route);
  }

  return true;
}

String trackingTypeForSessionContent(SessionContentType type) {
  switch (type) {
    case SessionContentType.audio:
      return 'audio';
    case SessionContentType.video:
      return 'video';
    case SessionContentType.pdf:
      return 'pdf';
  }
}
