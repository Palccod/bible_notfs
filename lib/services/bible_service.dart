import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class BibleService {
  List<Map<String, dynamic>> _allVerses = [];
  List<int> _shuffledIndices = [];
  int _currentIndex = 0;

  Future<void> loadBibleVerses() async {
    final String jsonString =
        await rootBundle.loadString('assets/bible_verses.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<Map<String, dynamic>> verses = [];

    for (var book in data['books']) {
      for (var chapter in book['chapters']) {
        for (var verse in chapter['verses']) {
          verses.add({
            'book': book['name'],
            'chapter': chapter['chapter'],
            'verse': verse['verse'],
            'text': verse['text'],
          });
        }
      }
    }

    _allVerses = verses;
    await _loadShuffleState();
  }

  Future<void> _loadShuffleState() async {
    final prefs = await SharedPreferences.getInstance();
    final indicesString = prefs.getString('shuffled_indices');
    final currentIndex = prefs.getInt('current_index') ?? 0;

    if (indicesString != null) {
      _shuffledIndices = List<int>.from(json.decode(indicesString));
      _currentIndex = currentIndex;
      if (_shuffledIndices.length != _allVerses.length) {
        _reshuffle();
      }
    } else {
      _reshuffle();
    }
  }

  Future<void> _saveShuffleState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('shuffled_indices', json.encode(_shuffledIndices));
    await prefs.setInt('current_index', _currentIndex);
  }

  void _reshuffle() {
    _shuffledIndices = List.generate(_allVerses.length, (i) => i);
    _shuffledIndices.shuffle(Random());
    _currentIndex = 0;
    _saveShuffleState();
  }

  Future<Map<String, dynamic>> getNextVerse() async {
    if (_shuffledIndices.isEmpty) _reshuffle();
    if (_currentIndex >= _shuffledIndices.length) {
      _reshuffle();
    }
    final verse = _allVerses[_shuffledIndices[_currentIndex]];
    _currentIndex++;
    await _saveShuffleState();
    return verse;
  }
}
