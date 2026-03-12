import 'extraction_result.dart';
import 'provider_type.dart';

class ExtractionExecution {
  const ExtractionExecution({
    required this.result,
    required this.providerType,
    required this.model,
  });

  final ExtractionResult result;
  final ProviderType providerType;
  final String model;
}
