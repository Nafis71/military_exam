import '../config/deployment.dart';

class LogFilter {
  bool get isEnabled => !Deployment.instance.isProduction;
}
