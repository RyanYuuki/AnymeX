import 'package:anymex/widgets/common/navbar/navbar_registry.dart';
import 'package:anymex/widgets/common/navbar/styles/classic_navbar.dart';
import 'package:anymex/widgets/common/navbar/styles/floating_pill_navbar.dart';

export 'styles/classic_navbar.dart';
export 'styles/floating_pill_navbar.dart';

enum NavStyleVariant {
  classic,
  floatingPill,
}

void registerBuiltInNavBarStyles() {
  NavBarRegistry.register(ClassicNavBarStyle());
  NavBarRegistry.register(FloatingPillNavBarStyle());
}
