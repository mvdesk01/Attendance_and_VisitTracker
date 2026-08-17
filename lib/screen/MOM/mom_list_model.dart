class MOMListModel {
  String name;
  String email;

  MOMListModel({ required this.name, required this.email});

  void setName(String name) {
    this.name = name;
  }
  void setEmail(String email) {
    this.email = email;
  }

  String getName(){
    return name;
  }
  String getEmail() {
    return email;
  }
}