class AISuggestionService {

  static String suggestTime(String medicineName){

    if(medicineName.toLowerCase().contains("vitamin")){
      return "Morning recommended";
    }

    if(medicineName.toLowerCase().contains("antibiotic")){
      return "Take after meal";
    }

    return "Follow doctor instructions";
  }
}
