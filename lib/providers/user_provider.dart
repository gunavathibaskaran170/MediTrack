import 'package:flutter/material.dart';
import '../core/models.dart';
import '../core/database_helper.dart';

class UserProvider with ChangeNotifier {
  User? _currentUser;
  bool _isLoading = false;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Primary user is hardcoded to ID = 1 for the scope of this single-patient app
      _currentUser = await DatabaseHelper.instance.getUser(1);
    } catch (e) {
      debugPrint("Error loading user: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> saveUser(User user) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper.instance.insertUser(user);
      _currentUser = user;
    } catch (e) {
      debugPrint("Error inserting user: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateUser(User user) async {
    _isLoading = true;
    notifyListeners();

    try {
      await DatabaseHelper.instance.updateUser(user);
      _currentUser = user;
    } catch (e) {
      debugPrint("Error updating user: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
