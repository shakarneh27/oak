import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/games_matrix_data.dart';
import '../data/units_data.dart';
import '../models/game_definition.dart';

/// Fetches the units + adaptive games catalog from Supabase, falling back
/// to the bundled static copy (lib/data) if the network call fails —
/// keeps `fetch_units_status` / the games screen usable offline.
class CatalogService {
  final SupabaseClient _client;

  CatalogService(this._client);

  Future<List<Unit>> fetchUnits() async {
    try {
      final rows = await _client.from('units').select().order('sort_order');
      if (rows.isEmpty) return kUnits;
      return rows.map((row) => Unit.fromMap(row)).toList();
    } catch (_) {
      return kUnits;
    }
  }

  Future<List<GameDefinition>> fetchGames({String? unitKey}) async {
    try {
      var query = _client.from('games_catalog').select();
      if (unitKey != null) {
        query = query.eq('unit_key', unitKey);
      }
      final rows = await query;
      if (rows.isEmpty) return _localGames(unitKey);
      return rows.map((row) => GameDefinition.fromMap(row)).toList();
    } catch (_) {
      return _localGames(unitKey);
    }
  }

  List<GameDefinition> _localGames(String? unitKey) {
    if (unitKey == null) return kGamesMatrix;
    return kGamesMatrix.where((g) => g.unitKey == unitKey).toList();
  }
}
