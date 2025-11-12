class ApiConfig {
  // Change this based on your environment
  // For Android Emulator: http://10.0.2.2:5000
  // For iOS Simulator: http://localhost:5000
  // For Physical Device: http://YOUR_IP:5000
  static const String baseUrl = 'http://localhost:5000';
  
  static const String locationsUrl = '$baseUrl/locations';
  static const String accountsUrl = '$baseUrl/accounts';
  static const String authUrl = '$baseUrl/auth';
  static const String usersUrl = '$baseUrl/users';
}
