import 'package:equatable/equatable.dart';

class CsvValidationError extends Equatable {
  final int rowNumber;
  final String field;
  final String message;
  final ValidationErrorType type;

  const CsvValidationError({
    required this.rowNumber,
    required this.field,
    required this.message,
    required this.type,
  });

  @override
  List<Object?> get props => [rowNumber, field, message, type];
}

enum ValidationErrorType {
  missingField,
  invalidFormat,
  invalidOptions,
  duplicateQuestion,
  invalidPoints,
  invalidImageUrl,
}
