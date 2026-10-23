import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// What the player owns. The only product today is the one-time "full game".
///
/// The store is the source of truth: purchases, restores and promo/offer codes
/// all arrive as the same purchase event. A cached copy of the answer lets the
/// game start offline.
abstract class Entitlements extends ChangeNotifier {
  /// Product id configured in App Store Connect and Play Console.
  static const String fullGameId = 'eldrin_full_game';

  bool get fullGame;
  bool get storeAvailable;
  bool get busy;

  /// Localised price of the full game, once the store has answered.
  String? get price;

  /// Last status or error worth showing the player.
  String? get message;

  Future<void> init();
  Future<void> buy();
  Future<void> restore();

  /// Opens the platform's own code-redemption flow.
  Future<void> redeemCode();

  /// Grants the full game without paying. Debug builds only.
  void debugUnlock();

  /// True if the player owns [product] ("full").
  bool owns(String product) => product == 'full' && fullGame;
}

/// In-memory implementation for tests.
class MemoryEntitlements extends Entitlements {
  MemoryEntitlements({bool fullGame = false}) : _full = fullGame;

  bool _full;
  String? _message;

  @override
  bool get fullGame => _full;
  @override
  bool get storeAvailable => true;
  @override
  bool get busy => false;
  @override
  String? get price => r'$3.99';
  @override
  String? get message => _message;

  @override
  Future<void> init() async {}

  @override
  Future<void> buy() async {
    _full = true;
    notifyListeners();
  }

  @override
  Future<void> restore() async {
    _message = 'No previous purchase found.';
    notifyListeners();
  }

  @override
  Future<void> redeemCode() async {}

  @override
  void debugUnlock() => buy();
}

/// Real implementation backed by StoreKit (iOS) and Play Billing (Android).
class StoreEntitlements extends Entitlements {
  static const _cacheKey = 'eldrin.entitlement.full';

  late final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  ProductDetails? _product;
  bool _full = false;
  bool _available = false;
  bool _busy = false;
  String? _message;

  @override
  bool get fullGame => _full;
  @override
  bool get storeAvailable => _available;
  @override
  bool get busy => _busy;
  @override
  String? get price => _product?.price;
  @override
  String? get message => _message;

  @override
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _full = prefs.getBool(_cacheKey) ?? false;
    } catch (_) {
      // The cache is only a convenience.
    }
    notifyListeners();

    try {
      _available = await _iap.isAvailable();
      if (!_available) {
        _message = 'The store is not available right now.';
        notifyListeners();
        return;
      }
      _subscription = _iap.purchaseStream.listen(
        _onPurchases,
        onError: (Object e) => _fail('Purchase error: $e'),
      );
      final response = await _iap.queryProductDetails({Entitlements.fullGameId});
      if (response.productDetails.isNotEmpty) {
        _product = response.productDetails.first;
      } else {
        _message = 'The full game is not available in the store yet.';
      }
    } catch (e) {
      _available = false;
      _message = 'Could not reach the store.';
    }
    notifyListeners();
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final p in purchases) {
      if (p.productID != Entitlements.fullGameId) continue;
      switch (p.status) {
        case PurchaseStatus.pending:
          _busy = true;
          _message = 'Waiting for the store…';
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _grant();
        case PurchaseStatus.canceled:
          _busy = false;
          _message = null;
        case PurchaseStatus.error:
          _busy = false;
          _message = p.error?.message ?? 'The purchase did not go through.';
      }
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
    notifyListeners();
  }

  Future<void> _grant() async {
    _full = true;
    _busy = false;
    _message = 'Full game unlocked. Thank you!';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKey, true);
    } catch (_) {
      // Ignore cache failures; the store will restore it.
    }
  }

  void _fail(String message) {
    _busy = false;
    _message = message;
    notifyListeners();
  }

  @override
  Future<void> buy() async {
    final product = _product;
    if (product == null) {
      _fail(_available ? 'The full game is not available in the store yet.' : 'The store is not available right now.');
      return;
    }
    _busy = true;
    _message = null;
    notifyListeners();
    try {
      await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
    } catch (e) {
      _fail('Could not start the purchase.');
    }
  }

  @override
  Future<void> restore() async {
    if (!_available) {
      _fail('The store is not available right now.');
      return;
    }
    _busy = true;
    _message = 'Looking for previous purchases…';
    notifyListeners();
    try {
      await _iap.restorePurchases();
      // Restored purchases arrive on the purchase stream. If none do, clear the
      // busy state after a moment so the sheet does not spin forever.
      await Future<void>.delayed(const Duration(seconds: 4));
      if (_busy && !_full) {
        _busy = false;
        _message = 'No previous purchase found.';
        notifyListeners();
      }
    } catch (e) {
      _fail('Could not restore purchases.');
    }
  }

  @override
  Future<void> redeemCode() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _iap
            .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>()
            .presentCodeRedemptionSheet();
      } else {
        await launchUrl(
          Uri.parse('https://play.google.com/redeem'),
          mode: LaunchMode.externalApplication,
        );
      }
    } catch (_) {
      _fail('Could not open the code redemption screen.');
    }
  }

  @override
  void debugUnlock() {
    if (!kDebugMode) return;
    _full = true;
    _message = 'Unlocked for this debug session.';
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
