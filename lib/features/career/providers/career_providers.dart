import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/career_repository.dart';

final careerRepositoryProvider = Provider<CareerRepository>(
  (ref) => CareerRepository(),
);
