import 'package:attendance_system_ios/cleanarchitecture/feature/MOM/domain/enteties/responsibility.dart';

class Responsibilitystate {
  final bool isLoading;
  final List<Responsibility> responsibility;
  final Responsibility? selectedResponsibility;
  final String? error;

  const Responsibilitystate({
    this.isLoading = false,
    this.responsibility = const [],
    this.selectedResponsibility,
    this.error,
  });

  Responsibilitystate copyWith({
    bool? isLoading,
    List<Responsibility>? responsibility,
    Responsibility? selectedResponsibility,
    String? error,
  }) {
    return Responsibilitystate(
      isLoading: isLoading ?? this.isLoading,
      responsibility: responsibility ?? this.responsibility,
      selectedResponsibility:
          selectedResponsibility ?? this.selectedResponsibility,
      error: error,
    );
  }
}

///test
