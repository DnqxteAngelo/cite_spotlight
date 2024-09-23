// ignore_for_file: unnecessary_this, unnecessary_new, prefer_collection_literals, file_names

class Nominees {
  int? id;
  String? name;
  String? imageUrl;
  String? gender;
  DateTime? time;

  Nominees({this.id, this.name, this.imageUrl, this.gender, this.time});

  Nominees.fromJson(Map<String, dynamic> json) {
    id = json['nominee_id'];
    name = json['nominee_name'];
    imageUrl = json['nominee_image'];
    gender = json['nominee_gender'];
    time = DateTime.parse(json['nominee_time']);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['id'] = this.id;
    data['name'] = this.name;
    data['imageUrl'] = this.imageUrl;
    data['gender'] = this.gender;
    data['time'] = this.time;
    return data;
  }
}
