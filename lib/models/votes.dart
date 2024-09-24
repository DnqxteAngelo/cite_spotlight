// ignore_for_file: unnecessary_this, unnecessary_new, prefer_collection_literals, file_names

class Votes {
  int? id;
  String? name;
  String? imageUrl;
  String? gender;
  int? totalVotes;
  DateTime? time;

  Votes(
      {this.id,
      this.name,
      this.imageUrl,
      this.gender,
      this.totalVotes,
      this.time});

  Votes.fromJson(Map<String, dynamic> json) {
    id = json['nominee_id'];
    name = json['nominee_name'];
    imageUrl = json['nominee_image'];
    gender = json['nominee_gender'];
    totalVotes = json['total_votes'] ?? 0; // Use total_votes from the function
    time = DateTime.parse(json['nominee_time']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['imageUrl'] = this.imageUrl;
    data['gender'] = this.gender;
    data['totalVotes'] = this.totalVotes;
    data['time'] = this.time;
    return data;
  }
}
