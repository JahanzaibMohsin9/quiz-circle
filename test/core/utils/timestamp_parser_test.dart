import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quiz_circle/core/utils/timestamp_parser.dart';

void main() {
  group('TimestampParser', () {
    group('parse()', () {
      test('should parse Firestore Timestamp correctly', () {
        final now = DateTime.now();
        final timestamp = Timestamp.fromDate(now);

        final result = TimestampParser.parse(timestamp);

        expect(
          result.millisecondsSinceEpoch,
          equals(now.millisecondsSinceEpoch),
        );
      });

      test('should parse ISO8601 string correctly', () {
        const isoString = '2024-01-05T12:30:00.000Z';

        final result = TimestampParser.parse(isoString);

        expect(result.toIso8601String(), equals(isoString));
      });

      test('should parse milliseconds int correctly', () {
        final now = DateTime.now();
        final milliseconds = now.millisecondsSinceEpoch;

        final result = TimestampParser.parse(milliseconds);

        expect(result.millisecondsSinceEpoch, equals(milliseconds));
      });

      test('should return DateTime object as-is (passthrough)', () {
        final now = DateTime.now();

        final result = TimestampParser.parse(now);

        expect(result, same(now));
      });

      test('should throw ArgumentError for null value', () {
        expect(
          () => TimestampParser.parse(null),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Timestamp cannot be null'),
            ),
          ),
        );
      });

      test('should throw ArgumentError for invalid type (boolean)', () {
        expect(
          () => TimestampParser.parse(true),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid timestamp format'),
            ),
          ),
        );
      });

      test('should throw ArgumentError for invalid type (Map)', () {
        expect(
          () => TimestampParser.parse({'key': 'value'}),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid timestamp format'),
            ),
          ),
        );
      });

      test('should throw ArgumentError for invalid ISO8601 string', () {
        const invalidString = 'not-a-date';

        expect(
          () => TimestampParser.parse(invalidString),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('Invalid timestamp string format'),
            ),
          ),
        );
      });
    });

    group('toJson()', () {
      test('should convert DateTime to Firestore Timestamp', () {
        final now = DateTime.now();

        final result = TimestampParser.toJson(now);

        expect(result, isA<Timestamp>());
        expect(
          result.toDate().millisecondsSinceEpoch,
          equals(now.millisecondsSinceEpoch),
        );
      });

      test('should handle DateTime with microseconds', () {
        final dateTime = DateTime(2024, 1, 5, 12, 30, 45, 123, 456);

        final result = TimestampParser.toJson(dateTime);

        expect(result, isA<Timestamp>());
        // Firestore Timestamp has millisecond precision, microseconds are truncated
        expect(
          result.toDate().millisecondsSinceEpoch,
          equals(DateTime(2024, 1, 5, 12, 30, 45, 123).millisecondsSinceEpoch),
        );
      });
    });

    group('round-trip conversion', () {
      test(
        'should maintain timestamp through parse -> toJson -> parse cycle',
        () {
          final original = DateTime(2024, 1, 5, 12, 30, 45);

          final timestamp = TimestampParser.toJson(original);
          final parsed = TimestampParser.parse(timestamp);

          expect(
            parsed.millisecondsSinceEpoch,
            equals(original.millisecondsSinceEpoch),
          );
        },
      );
    });
  });
}
