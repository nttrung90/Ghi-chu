import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:note_ntt/models/note_model.dart';
import 'package:note_ntt/views/home/widgets/note_card.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('vi', null);
  });

  testWidgets('NoteCard hiển thị tiêu đề và nội dung ghi chú', (
    WidgetTester tester,
  ) async {
    final now = DateTime(2026, 1, 1);
    final note = NoteModel(
      id: 'test-note',
      title: 'Ghi chú kiểm thử',
      content: 'Nội dung kiểm thử',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NoteCard(
            note: note,
            onTap: () {},
            onTogglePin: () {},
          ),
        ),
      ),
    );

    expect(find.text('Ghi chú kiểm thử'), findsOneWidget);
    expect(find.text('Nội dung kiểm thử'), findsOneWidget);
  });
}
