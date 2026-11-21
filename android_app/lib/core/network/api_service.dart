import 'package:dio/dio.dart';
import '../models/market_snapshot.dart';
import '../models/teddy_signal.dart';
import '../models/option_chain.dart';

class ApiService {
  final Dio _dio;
  String baseUrl;

  ApiService({required this.baseUrl})
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 6),
          headers: {'Content-Type': 'application/json'},
        ));

  void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
    _dio.options.baseUrl = newUrl;
  }

  Future<MarketSnapshot> getSnapshot(String instrument) async {
    final response = await _dio.get(
      '/api/snapshot',
      queryParameters: {'instrument': instrument},
    );
    return MarketSnapshot.fromJson(response.data as Map<String, dynamic>);
  }

  Future<TeddySignal> triggerAnalysis(String instrument) async {
    final response = await _dio.post(
      '/api/analyze',
      queryParameters: {'instrument': instrument},
    );
    return TeddySignal.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<OptionChainStrike>> getOptionChain(String instrument) async {
    final response = await _dio.get(
      '/api/option-chain',
      queryParameters: {'instrument': instrument},
    );
    final list = response.data as List<dynamic>;
    return list.map((e) => OptionChainStrike.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<TeddySignal>> getSignalHistory({String? instrument, int limit = 50}) async {
    final query = <String, dynamic>{'limit': limit};
    if (instrument != null) query['instrument'] = instrument;

    final response = await _dio.get('/api/signals', queryParameters: query);
    final list = response.data as List<dynamic>;
    return list.map((e) => TeddySignal.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> setMode(String mode) async {
    await _dio.post('/api/mode', data: {'mode': mode});
  }
}
