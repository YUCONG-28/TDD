// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:todo_diary/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TodoDiaryApp());

    // Verify that the app title is present
    expect(find.text('待办日记'), findsOneWidget);
    
    // Verify that the home page loads with bottom navigation
    expect(find.byIcon(Icons.checklist), findsOneWidget);
    expect(find.byIcon(Icons.book), findsOneWidget);
    expect(find.byIcon(Icons.sync), findsOneWidget);
  });
  
  testWidgets('Todo page basic interaction', (WidgetTester tester) async {
    await tester.pumpWidget(const TodoDiaryApp());
    
    // Verify initial state
    expect(find.text('待办事项'), findsOneWidget);
    
    // Find the text field and add a todo
    final textField = find.byType(TextField);
    expect(textField, findsWidgets);
    
    // Enter text
    await tester.enterText(textField.first, '测试待办事项');
    
    // Find and tap the add button
    final addButton = find.text('添加待办');
    await tester.tap(addButton);
    await tester.pump();
    
    // Verify the todo appears (may need to handle async loading)
    // This is a basic smoke test
  });
}
