import 'package:anymex/widgets/common/cards/media_card_registry.dart';
import 'package:anymex/widgets/common/cards/styles/exotic_card.dart';
import 'package:anymex/widgets/common/cards/styles/minimal_exotic_card.dart';
import 'package:anymex/widgets/common/cards/styles/modern_card.dart';
import 'package:anymex/widgets/common/cards/styles/saikou_card.dart';
import 'package:anymex/widgets/common/cards/styles/simple_card.dart';

export 'styles/exotic_card.dart';
export 'styles/minimal_exotic_card.dart';
export 'styles/modern_card.dart';
export 'styles/saikou_card.dart';
export 'styles/simple_card.dart';

void registerBuiltInMediaCardStyles() {
  if (MediaCardRegistry.styles.isNotEmpty) return;
  MediaCardRegistry.register(DefaultCardStyle());
  MediaCardRegistry.register(SaikouCardStyle());
  MediaCardRegistry.register(ExoticCardStyle());
  MediaCardRegistry.register(MinimalExoticCardStyle());
  MediaCardRegistry.register(ModernCardStyle());
}
