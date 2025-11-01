import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get_it/get_it.dart';

import '../../data/repositories/monster_repository_impl.dart';
import '../../data/repositories/skill_repository_impl.dart';
import '../../data/repositories/equipment_repository_impl.dart';
import '../../domain/repositories/monster_repository.dart';
import '../../domain/repositories/skill_repository.dart';
import '../../domain/repositories/equipment_repository.dart';

final getIt = GetIt.instance;

Future<void> setupDependencies() async {
  // Firebase
  getIt.registerLazySingleton(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton(() => FirebaseAuth.instance);

  // Repositories
  getIt.registerLazySingleton<MonsterRepository>(
    () => MonsterRepositoryImpl(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<SkillRepository>(
    () => SkillRepositoryImpl(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<EquipmentRepository>(
    () => EquipmentRepositoryImpl(getIt<FirebaseFirestore>()),
  );
}