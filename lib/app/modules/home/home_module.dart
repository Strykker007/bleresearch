import 'package:flutter_modular/flutter_modular.dart';
import '../home/home_store.dart';

import 'home_page.dart';

class HomeModule extends ChildModule {
  @override
  final List<Bind> binds = [
    Bind((i) => HomeStore()),
  ];

  @override
  final List<ModularRouter> routers = [
    ModularRouter(Modular.initialRoute, child: (_, args) => HomePage()),
  ];
}
