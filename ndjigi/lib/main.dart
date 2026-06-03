import 'package:flutter/material.dart';
import 'core/config/app_config.dart';
import 'app/bootstrap/bootstrap.dart';
import 'app/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrap(flavor: Flavor.dev);
  runApp(const App());
}
