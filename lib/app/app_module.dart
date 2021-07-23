import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_1_22_6/app/app_widget.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'modules/home/home_module.dart';

class AppModule extends MainModule {
  @override
  final List<Bind> binds = [];

  @override
  final List<ModularRouter> routers = [
    ModularRouter(Modular.initialRoute, module: HomeModule()),
  ];

  @override
  Widget get bootstrap => AppWidget();
}
