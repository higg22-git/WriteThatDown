import 'package:flutter/foundation.dart';

import '../models/idea_tile.dart';
import '../services/storage/idea_repository.dart';

class IdeasController extends ChangeNotifier {
  IdeasController(this._ideaRepository);

  final IdeaRepository _ideaRepository;

  List<IdeaTile> _ideas = const [];
  bool _isLoading = false;
  String? _error;

  List<IdeaTile> get ideas => _ideas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadIdeas() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _ideas = await _ideaRepository.fetchIdeas();
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addIdea(IdeaTile idea) async {
    _ideas = [idea, ..._ideas];
    notifyListeners();
  }
}
