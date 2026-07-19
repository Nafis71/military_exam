import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

class GetDistrictsUseCase {
  GetDistrictsUseCase(this._authRepository);

  final AuthRepository _authRepository;

  Future<Result<List<String>>> call() => _authRepository.getDistricts();
}
