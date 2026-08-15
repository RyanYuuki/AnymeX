import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex/widgets/common/cards/styles/exotic_card.dart';
import 'package:anymex/widgets/common/cards/styles/glass_card.dart';
import 'package:anymex/widgets/common/cards/styles/minimal_exotic_card.dart';
import 'package:anymex/widgets/common/cards/styles/modern_card.dart';
import 'package:anymex/widgets/common/cards/styles/saikou_card.dart';
import 'package:anymex/widgets/common/cards/styles/simple_card.dart';

export 'styles/exotic_card.dart';
export 'styles/glass_card.dart';
export 'styles/minimal_exotic_card.dart';
export 'styles/modern_card.dart';
export 'styles/saikou_card.dart';
export 'styles/simple_card.dart';

void registerBuiltInMediaCardStyles() {
  MediaCardRegistry.register(SaikouCardStyle());
  MediaCardRegistry.register(ExoticCardStyle());
  MediaCardRegistry.register(MinimalExoticCardStyle());
  MediaCardRegistry.register(ModernCardStyle());
  MediaCardRegistry.register(GlassCardStyle());
  MediaCardRegistry.register(SimpleCardStyle());
}
