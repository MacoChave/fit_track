/// Modelos y tipos para la configuración BYOK (Bring Your Own Key) y verificación de conectividad.
enum AiProvider {
  gemini(
    id: 'gemini',
    name: 'Gemini',
    modelSummary: '1.5 Pro / Flash',
    headerBadge: 'RECOMENDADO',
    apiHint: 'GOOGLE AI STUDIO',
    signupUrl: 'https://aistudio.google.com/app/apikey',
  ),
  openai(
    id: 'openai',
    name: 'GPT-4o',
    modelSummary: 'Gen1 Native',
    headerBadge: 'OPENAI',
    apiHint: 'OPENAI PLATFORM',
    signupUrl: 'https://platform.openai.com/api-keys',
  ),
  anthropic(
    id: 'anthropic',
    name: 'Claude',
    modelSummary: '3.5 Sonnet',
    headerBadge: 'ANTHROPIC',
    apiHint: 'ANTHROPIC CONSOLE',
    signupUrl: 'https://console.anthropic.com/',
  );

  final String id;
  final String name;
  final String modelSummary;
  final String headerBadge;
  final String apiHint;
  final String signupUrl;

  const AiProvider({
    required this.id,
    required this.name,
    required this.modelSummary,
    required this.headerBadge,
    required this.apiHint,
    required this.signupUrl,
  });

  static AiProvider fromId(String id) {
    return AiProvider.values.firstWhere(
      (e) => e.id == id,
      orElse: () => AiProvider.gemini,
    );
  }
}

enum GenerativeFocus {
  scientific(
    id: 'SCIENTIFIC',
    label: 'CIENTÍFICO / PRECISO',
    temperature: 0.2,
    description: 'Preciso (T=0.2)',
  ),
  adaptive(
    id: 'ADAPTATIVE',
    label: 'ADAPTATIVO / VARIADO',
    temperature: 0.7,
    description: 'Creativo (T=0.7)',
  );

  final String id;
  final String label;
  final double temperature;
  final String description;

  const GenerativeFocus({
    required this.id,
    required this.label,
    required this.temperature,
    required this.description,
  });
}

class PingTestResult {
  final bool isSuccess;
  final int statusCode;
  final String statusText;
  final int latencyMs;
  final String quotaInfo;
  final String verifiedModel;
  final String? errorMessage;
  final String testCode;

  const PingTestResult({
    required this.isSuccess,
    required this.statusCode,
    required this.statusText,
    required this.latencyMs,
    required this.quotaInfo,
    required this.verifiedModel,
    this.errorMessage,
    this.testCode = 'TC-01',
  });

  factory PingTestResult.initial() {
    return const PingTestResult(
      isSuccess: true,
      statusCode: 200,
      statusText: 'HTTP 200 OK — CONEXIÓN VERIFICADA',
      latencyMs: 214,
      quotaInfo: 'Tier Gratuito Activo',
      verifiedModel: 'gemini-1.5-flash: LISTO PARA ENTRENAR',
      testCode: 'TC-01',
    );
  }

  factory PingTestResult.error({
    required int statusCode,
    required String message,
    int latencyMs = 120,
  }) {
    return PingTestResult(
      isSuccess: false,
      statusCode: statusCode,
      statusText: 'HTTP $statusCode — ERROR DE AUTENTICACIÓN',
      latencyMs: latencyMs,
      quotaInfo: 'Acceso Denegado',
      verifiedModel: 'Credencial Inválida',
      errorMessage: message,
      testCode: 'TC-01',
    );
  }
}

class ByokConfig {
  final AiProvider provider;
  final bool optimizeSessionTime; // RN-05: 30-45 min
  final GenerativeFocus generativeFocus; // Temperatura

  const ByokConfig({
    this.provider = AiProvider.gemini,
    this.optimizeSessionTime = true,
    this.generativeFocus = GenerativeFocus.scientific,
  });

  ByokConfig copyWith({
    AiProvider? provider,
    bool? optimizeSessionTime,
    GenerativeFocus? generativeFocus,
  }) {
    return ByokConfig(
      provider: provider ?? this.provider,
      optimizeSessionTime: optimizeSessionTime ?? this.optimizeSessionTime,
      generativeFocus: generativeFocus ?? this.generativeFocus,
    );
  }
}
