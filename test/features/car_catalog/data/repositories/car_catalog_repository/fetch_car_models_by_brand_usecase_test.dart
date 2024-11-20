import 'dart:convert';

import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:minicore_arch_example/minicore_arch_example.dart';
import 'package:mocktail/mocktail.dart';

class MockClient extends Mock implements Client {}

void main() {
  late Client mockClient;
  late CarCatalogRepository sutRepository;

  setUp(() {
    mockClient = MockClient();
    sutRepository = ParallelumCarCatalogRepository(mockClient);
  });

  setUpAll(() {
    registerFallbackValue(Uri.parse(''));
  });

  group('fetchCarModelsByBrandUseCase Tests |', () {
    test(
        '''Should return CarModelsByBrandSuccess when API call succeeds with valid data''',
        () async {
      // Arrange
      const brandId = 1;
      final mockResponseData = jsonEncode(
        List.generate(5, (_) {
          return {
            'code': faker.randomGenerator.integer(1000, min: 1).toString(),
            'name': faker.vehicle.model(),
          };
        }),
      );
      when(
        () => mockClient.get(
          Uri.parse(
            'https://fipe.parallelum.com.br/api/v2/cars/brands/$brandId/models',
          ),
        ),
      ).thenAnswer(
        (_) async => Response(mockResponseData, 200),
      );

      // Act
      final result = await sutRepository.fetchCarModelsByBrandUseCase(brandId);

      // Assert
      expect(result, isA<CarModelsByBrandSuccess>());
      final successState = result as CarModelsByBrandSuccess;
      expect(successState.carModels.length, 5);
      expect(successState.carModels[0], isA<CarModelEntity>());
    });

    test(
        '''Should return CarCatalogFailure when API call fails with a non-200 status code''',
        () async {
      // Arrange
      const brandId = 1;
      const mockStatusCode = 404;
      final mockMessage = faker.lorem.sentence();
      when(
        () => mockClient.get(
          Uri.parse(
            'https://fipe.parallelum.com.br/api/v2/cars/brands/$brandId/models',
          ),
        ),
      ).thenAnswer(
        (_) async => Response(mockMessage, mockStatusCode),
      );

      // Act
      final result = await sutRepository.fetchCarModelsByBrandUseCase(brandId);

      // Assert
      expect(result, isA<CarCatalogFailure>());
      final failureState = result as CarCatalogFailure;
      expect(
        failureState.message,
        'Failed to fetch car models catalog. Status code: $mockStatusCode',
      );
    });

    test('Should return CarCatalogFailure when an exception is thrown',
        () async {
      // Arrange
      const brandId = 1;
      final mockExceptionMessage = faker.lorem.sentence();
      when(
        () => mockClient.get(
          Uri.parse(
            'https://fipe.parallelum.com.br/api/v2/cars/brands/$brandId/models',
          ),
        ),
      ).thenThrow(Exception(mockExceptionMessage));

      // Act
      final result = await sutRepository.fetchCarModelsByBrandUseCase(brandId);

      // Assert
      expect(result, isA<CarCatalogFailure>());
      final failureState = result as CarCatalogFailure;
      expect(
        failureState.message,
        'Failed to fetch car models catalog: Exception: $mockExceptionMessage',
      );
    });
  });
}
