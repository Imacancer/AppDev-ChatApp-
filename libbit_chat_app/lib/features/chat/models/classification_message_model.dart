// Classification message model
class ClassificationMessage {
  final String url;
  final String
  classification; // "benign" | "potentially malicious" | "malicious"
  final String message;

  ClassificationMessage({
    required this.url,
    required this.classification,
    required this.message,
  });

  factory ClassificationMessage.fromJson(Map<String, dynamic> json) {
    return ClassificationMessage(
      url: json['url'],
      classification: json['classification'],
      message: json['message'],
    );
  }

  // Add this method
  Map<String, dynamic> toJson() {
    return {'url': url, 'classification': classification, 'message': message};
  }
}
