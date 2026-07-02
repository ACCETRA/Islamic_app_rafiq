import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rafiq/services/hadith_api_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    HadithApiService.resetForTesting();
  });

  test('falls back to the regular hadith JSON when the minified endpoint returns 404', () async {
    final mockClient = MockClient((request) {
      if (request.url.path.endsWith('eng-bukhari.min.json')) {
        return Future.value(http.Response('Not Found', 404));
      }

      if (request.url.path.endsWith('eng-bukhari.json')) {
        return Future.value(
          http.Response(
            '{"metadata":{"sections":{"1":"Book 1"}},"hadiths":[]}',
            200,
          ),
        );
      }

      return Future.value(http.Response('Not Found', 404));
    });

    HadithApiService.setClientForTesting(mockClient);

    final hadiths = await HadithApiService.getHadiths('bukhari');

    expect(hadiths, isEmpty);
  });

  test('keeps fractional hadith numbers as display identifiers', () async {
    final mockClient = MockClient((request) {
      return Future.value(
        http.Response(
          '{"metadata":{"sections":{"1":"Book 1"}},"hadiths":['
          '{"hadithnumber":402.2,"text":"Text","reference":{"book":1},"grades":[]}'
          ']}',
          200,
        ),
      );
    });

    HadithApiService.setClientForTesting(mockClient);

    final hadiths = await HadithApiService.getHadiths('bukhari');

    expect(hadiths.single.hadithNumber, '402.2');
  });
}
